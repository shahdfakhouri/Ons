const OpenAI = require("openai");

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function generateReply({ system, messages }) {
  const resp = await client.chat.completions.create({
    model: process.env.OPENAI_MODEL, // your ft model
    messages: [{ role: "system", content: system }, ...messages],
    temperature: 0.6,
    max_tokens: 220,
  });

  return (
    resp.choices?.[0]?.message?.content?.trim() ||
    "I’m here with you. Tell me more."
  );
}

module.exports = { generateReply };
