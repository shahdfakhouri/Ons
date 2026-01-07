const mongoose = require("mongoose");

const ConversationSchema = new mongoose.Schema(
  {
    elderId: { type: Number, required: true }, // maps to MySQL elder_id
  },
  { timestamps: true }
);

module.exports = mongoose.model("Conversation", ConversationSchema);
