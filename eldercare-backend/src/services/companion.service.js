const OpenAI = require("openai");
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

function clean(text = "") {
  return text
    .replace(/\r/g, "")
    .replace(/^\s*(agent|assistant|customer)\s*:\s*/i, "")
    .replace(/\n?\s*(agent|customer)\s*:\s*$/i, "")
    .trim();
}

function looksBad(raw = "") {
  const t = (raw || "").trim();
  if (!t) return true;

  // Wrong speaker / template artifacts from EmpatheticDialogues
  if (/^customer\s*:/i.test(t)) return true;
  if (t === "Agent:" || t === "Customer:") return true;
  if (t.endsWith("\nAgent:") || t.endsWith("\nCustomer:")) return true;

  return false;
}

// 1) Try fine-tuned model (your trained model)
async function callFineTuned({ system, transcript }) {
  const prompt =
    `You are the Agent.\n` +
    `Reply with ONLY the Agent message text (no labels).\n\n` +
    `${transcript}\nAgent:`;

  const resp = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL, // ✅ your fine-tuned model ft:...
    messages: [
      { role: "system", content: system },
      { role: "user", content: prompt },
    ],
    temperature: 0.6,
    max_tokens: 220,
  });

  return resp.choices?.[0]?.message?.content || "";
}

// 2) Backup model (fallback) if fine-tuned output is bad/empty
async function callFallback({ system, history, userMessage }) {
  const resp = await client.chat.completions.create({
    model: process.env.OPENAI_FALLBACK_MODEL || "gpt-4o-mini",
    messages: [
      { role: "system", content: system },
      ...(Array.isArray(history) ? history.slice(-12) : []),
      { role: "user", content: userMessage },
    ],
    temperature: 0.6,
    max_tokens: 220,
  });

  return resp.choices?.[0]?.message?.content || "";
}

async function generateReply({ system, transcript, history, userMessage }) {
  // Try fine-tuned first
  const rawFT = await callFineTuned({ system, transcript });

  if (!looksBad(rawFT)) {
    const reply = clean(rawFT);
    if (reply) return reply;
  }

  // Fallback if fine-tuned failed
  const rawFB = await callFallback({ system, history, userMessage });
  const replyFB = clean(rawFB);

  return replyFB || "I’m here with you. Tell me more.";
}

module.exports = { generateReply };
