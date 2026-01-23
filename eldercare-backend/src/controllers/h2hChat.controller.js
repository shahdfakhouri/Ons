const db = require("../config/db");
const H2HConversation = require("../models/chat/H2HConversation");
const H2HMessage = require("../models/chat/H2HMessage");

function mustBeFamilyOrCaregiver(req, res) {
  const id = req.user?.id;
  const role = req.user?.role;

  if (!id || !role) return res.status(401).json({ error: "Unauthorized" });
  if (!["family", "caregiver"].includes(role))
    return res.status(403).json({ error: "Only family/caregiver allowed" });

  return { myId: Number(id), myRole: role, myIdStr: String(id) };
}

function q(sql, params = []) {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, rows) => (err ? reject(err) : resolve(rows)));
  });
}

async function ensureParticipant(conversationId, myIdStr) {
  const conv = await H2HConversation.findById(conversationId).lean();
  if (!conv) return { conv: null, ok: false };
  const ok = (conv.participants || []).some((p) => p.userId === myIdStr);
  return { conv, ok };
}

// 🔒 POST /api/chat-h2h/conversations  { elderId }
exports.createOrGetConversation = async (req, res) => {
  const u = mustBeFamilyOrCaregiver(req, res);
  if (!u?.myRole) return;

  const elderId = Number(req.body?.elderId);
  if (!elderId) return res.status(400).json({ error: "elderId is required" });

  try {
    // elder name (for UI)
    const elderRows = await q(`SELECT elder_id, name FROM elders WHERE elder_id = ? LIMIT 1`, [elderId]);
    if (!elderRows.length) return res.status(404).json({ error: "Elder not found" });
    const elderName = elderRows[0].name;

    let caregiverId, familyId, caregiverName, familyName;

    // 👇 Caregiver starts chat => find family for elder, ensure caregiver assigned to elder
    if (u.myRole === "caregiver") {
      caregiverId = u.myId;

      // ensure caregiver is assigned to that elder
      const asg = await q(
        `SELECT 1
         FROM elder_assignments
         WHERE elder_id = ? AND caregiver_id = ?
         ORDER BY assigned_at DESC
         LIMIT 1`,
        [elderId, caregiverId]
      );
      if (!asg.length) {
        return res.status(403).json({ error: "You are not assigned to this elder" });
      }

      // find family linked to elder
      const fam = await q(
        `SELECT ef.family_id, fm.name
         FROM elder_family ef
         JOIN family_members fm ON fm.family_id = ef.family_id
         WHERE ef.elder_id = ?
         LIMIT 1`,
        [elderId]
      );
      if (!fam.length) {
        return res.status(400).json({ error: "No family linked to this elder yet" });
      }

      familyId = Number(fam[0].family_id);
      familyName = fam[0].name;

      // caregiver name
      const c = await q(`SELECT name FROM caregivers WHERE caregiver_id = ? LIMIT 1`, [caregiverId]);
      caregiverName = c[0]?.name ?? `Caregiver #${caregiverId}`;
    }

    // 👇 Family starts chat => ensure elder belongs to family, find current assigned caregiver
    if (u.myRole === "family") {
      familyId = u.myId;

      // ensure elder belongs to this family
      const ok = await q(
        `SELECT 1 FROM elder_family WHERE family_id = ? AND elder_id = ? LIMIT 1`,
        [familyId, elderId]
      );
      if (!ok.length) {
        return res.status(403).json({ error: "This elder is not linked to your family" });
      }

      // find latest caregiver assignment (home_id NULL = freelance caregiver in your logic)
      const cg = await q(
        `SELECT ea.caregiver_id, c.name
         FROM elder_assignments ea
         JOIN caregivers c ON c.caregiver_id = ea.caregiver_id
         WHERE ea.elder_id = ?
         ORDER BY ea.assigned_at DESC
         LIMIT 1`,
        [elderId]
      );
      if (!cg.length) {
        return res.status(400).json({ error: "No caregiver assigned to this elder yet" });
      }

      caregiverId = Number(cg[0].caregiver_id);
      caregiverName = cg[0].name;

      // family name
      const f = await q(`SELECT name FROM family_members WHERE family_id = ? LIMIT 1`, [familyId]);
      familyName = f[0]?.name ?? `Family #${familyId}`;
    }

    const participants = [
      { role: "caregiver", userId: String(caregiverId) },
      { role: "family", userId: String(familyId) },
    ];

    const conv = await H2HConversation.findOneAndUpdate(
      { elderId, caregiverId, familyId },
      {
        $setOnInsert: {
          elderId,
          elderName,
          caregiverId,
          caregiverName,
          familyId,
          familyName,
          participants,
        },
      },
      { new: true, upsert: true }
    );

    res.json({ conversationId: conv._id, conversation: conv });
  } catch (e) {
    console.error("createOrGetConversation error:", e);
    res.status(500).json({ error: "Server error", details: e.message });
  }
};



// GET /api/chat-h2h/conversations
exports.listMyConversations = async (req, res) => {
  const u = mustBeFamilyOrCaregiver(req, res);
  if (!u.myRole) return;

  const convs = await H2HConversation.find({ "participants.userId": u.myIdStr })
    .sort({ lastMessageAt: -1, updatedAt: -1 })
    .limit(100)
    .lean();

  res.json({ conversations: convs });
};

// GET /api/chat-h2h/conversations/:id/messages?before=<iso>&limit=30
exports.getMessages = async (req, res) => {
  const u = mustBeFamilyOrCaregiver(req, res);
  if (!u.myRole) return;

  const { id } = req.params;
  const { conv, ok } = await ensureParticipant(id, u.myIdStr);
  if (!conv) return res.status(404).json({ error: "Conversation not found" });
  if (!ok) return res.status(403).json({ error: "Not allowed" });

  const limit = Math.min(parseInt(req.query.limit || "30", 10), 100);
  const before = req.query.before ? new Date(req.query.before) : null;

  const filter = { conversationId: id };
  if (before && !Number.isNaN(before.getTime())) filter.createdAt = { $lt: before };

  const msgs = await H2HMessage.find(filter).sort({ createdAt: -1 }).limit(limit).lean();
  msgs.reverse();

  res.json({ messages: msgs });
};

// POST /api/chat-h2h/conversations/:id/messages  { text }
exports.sendMessage = async (req, res) => {
  const u = mustBeFamilyOrCaregiver(req, res);
  if (!u.myRole) return;

  const { id } = req.params;
  const { conv, ok } = await ensureParticipant(id, u.myIdStr);
  if (!conv) return res.status(404).json({ error: "Conversation not found" });
  if (!ok) return res.status(403).json({ error: "Not allowed" });

  const text = String(req.body?.text || "").trim();
  if (!text) return res.status(400).json({ error: "text is required" });

  const msg = await H2HMessage.create({
    conversationId: id,
    senderRole: u.myRole,
    senderId: u.myId,
    text,
    readBy: [{ role: u.myRole, userId: u.myIdStr, at: new Date() }],
  });

  await H2HConversation.findByIdAndUpdate(id, {
    $set: { lastMessageText: text, lastMessageAt: msg.createdAt },
  });

  res.status(201).json({ message: msg });
};
