exports.findBestMatch = (req, res) => {
  const { family_id } = req.params;

  db.query("SELECT * FROM family_members WHERE family_id = ?", [family_id], (err, families) => {
    if (err) return res.status(500).json({ msg: "DB error fetching family", err });
    if (families.length === 0) return res.status(404).json({ msg: "Family not found" });

    const family = families[0];
    const { preference, city, budget, skills_required, hours_needed } = family;

    if (!preference || !city || !budget)
      return res.status(400).json({ msg: "Incomplete family data for matching." });

    // Safety check for budget to prevent Division by Zero errors
    const safeBudget = budget > 0 ? budget : 1;
    let sql, params;

    if (preference === "caregiver") {
      sql = `
        SELECT caregiver_id AS id, name, city, skills, expected_salary, hours_per_day,
          GREATEST(0, (100 -
            (ABS(expected_salary - ?) / ? * 40) -                -- Cost Penalty (40%)
            (CASE WHEN city = ? THEN 0 ELSE 20 END) +           -- City Penalty (20%)
            (CASE WHEN skills LIKE ? THEN 15 ELSE 0 END) +      -- Skills Bonus (15%)
            (CASE WHEN hours_per_day >= ? THEN 10 ELSE 0 END)   -- Hours Bonus (10%)
          )) AS score
        FROM caregivers
        WHERE is_approved = 1
        ORDER BY score DESC
        LIMIT 5;
      `;
      // Use wildcard % for the skills LIKE search
      params = [safeBudget, safeBudget, city, `%${skills_required || ''}%`, hours_needed || 0];
    } else {
      sql = `
        SELECT home_id AS id, name, city, monthly_cost,
          GREATEST(0, (100 -
            (ABS(monthly_cost - ?) / ? * 40) -                  -- Cost Penalty (40%)
            (CASE WHEN city = ? THEN 0 ELSE 20 END)             -- City Penalty (20%)
          )) AS score
        FROM retirement_homes
        WHERE is_approved = 1
        ORDER BY score DESC
        LIMIT 5;
      `;
      params = [safeBudget, safeBudget, city];
    }

    db.query(sql, params, (err, matches) => {
      if (err) return res.status(500).json({ msg: "Error running match query", err });
      if (matches.length === 0) return res.status(404).json({ msg: "No suitable matches found." });

      const top = matches[0];
      db.query(
        "INSERT INTO matches (family_id, matched_id, matched_role, score) VALUES (?, ?, ?, ?)",
        [family_id, top.id, preference, top.score],
        (insertErr) => {
          if (insertErr) console.error("Failed to save match:", insertErr);
        }
      );

      res.status(200).json({
        msg: `Top ${matches.length} ${preference} matches found`,
        matches,
      });
    });
  });
};