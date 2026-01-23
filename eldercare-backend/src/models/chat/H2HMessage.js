const mongoose = require("mongoose");

const ReadBySchema = new mongoose.Schema(
  {
    role: { type: String, enum: ["family", "caregiver"], required: true },
    userId: { type: String, required: true },
    at: { type: Date, default: Date.now },
  },
  { _id: false }
);

const H2HMessageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "H2HConversation",
      required: true,
    },
    senderRole: { type: String, enum: ["family", "caregiver"], required: true },
    senderId: { type: Number, required: true },
    text: { type: String, required: true, trim: true, maxlength: 2000 },
    readBy: { type: [ReadBySchema], default: [] },
  },
  { timestamps: true }
);

H2HMessageSchema.index({ conversationId: 1, createdAt: -1 });

module.exports = mongoose.model("H2HMessage", H2HMessageSchema);
