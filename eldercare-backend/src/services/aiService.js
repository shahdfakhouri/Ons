//ai check cv
// src/services/aiService.js
const REQUIRED_KEYWORDS = [
  "elderly care",
  "nursing",
  "patient care",
  "first aid",
  "medical",
  "healthcare",
  "dementia",
  "assistance",
  "rehabilitation",
  "communication",
  "support",
  "experience"
];

// ✅ Simple keyword-based scoring system
exports.analyzeCaregiverCV = (cvText) => {
  if (!cvText) return { score: 0, matched: [] };

  const text = cvText.toLowerCase();
  let matched = [];

  REQUIRED_KEYWORDS.forEach((keyword) => {
    if (text.includes(keyword)) matched.push(keyword);
  });

  const score = Math.round((matched.length / REQUIRED_KEYWORDS.length) * 100);
  return { score, matched };
};
