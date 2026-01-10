const db = require("../config/db"); // MySQL
const Conversation = require("../models/Conversation");
const Message = require("../models/Message");
const { generateReply } = require("../services/companion.service");

function getElderContext(elderId) {
  return new Promise((resolve) => {
    if (!elderId) return resolve("");

    db.query(
      `SELECT elder_id, name, age
       FROM elders
       WHERE elder_id = ?
       LIMIT 1`,
      [elderId],
      (err, rows) => {
        // if MySQL fails or elder not found, just skip context
        if (err || !rows?.length) return resolve("");
        const e = rows[0];
        resolve(`Elder: ${e.name}, age ${e.age}.`);
      }
    );
  });
}

exports.chat = async (req, res) => {
  try {
    const { elderId, message, conversationId } = req.body;

    if (!elderId || !message) {
      return res.status(400).json({ error: "elderId and message are required" });
    }

    // 1) get/create conversation
    let conv = null;
    if (conversationId) conv = await Conversation.findById(conversationId);
    if (!conv) conv = await Conversation.create({ elderId });

    // 2) save user msg
    await Message.create({
      conversationId: conv._id,
      role: "user",
      content: message,
    });

    // 3) load last 16 msgs (oldest -> newest)
    const historyDocs = await Message.find({ conversationId: conv._id })
      .sort({ createdAt: 1 })
      .limit(16);

    const history = historyDocs.map((m) => ({
      role: m.role,
      content: m.content,
    }));

    // 4) context injection (basic)
    const elderCtx = await getElderContext(elderId);

    const system = `
You are ONS Companion for elderly users.
Be warm, simple, and brief (1–3 short sentences).
Ask at most ONE gentle question.
Do not diagnose or give medical instructions.
If asked about meds/health decisions: encourage following caregiver/doctor plan.
${elderCtx ? "\n" + elderCtx : ""}
`.trim();

    // 5) Convert history into EmpatheticDialogues transcript (Customer/Agent)
    const transcript = history
      .map((m) => (m.role === "user" ? `Customer: ${m.content}` : `Agent: ${m.content}`))
      .join("\n");

    // 6) AI reply (fine-tuned first, fallback if needed)
    const reply = await generateReply({
      system,
      transcript,
      history,           // for fallback model (chat format)
      userMessage: message,
    });

    // 7) save assistant msg
    await Message.create({
      conversationId: conv._id,
      role: "assistant",
      content: reply,
    });

    return res.json({ conversationId: conv._id, reply });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "companion_failed" });
  }
};
