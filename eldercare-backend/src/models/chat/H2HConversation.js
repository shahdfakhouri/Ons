const mongoose = require("mongoose");

const ParticipantSchema = new mongoose.Schema(
  {
    role: { type: String, enum: ["family", "caregiver"], required: true },
    userId: { type: String, required: true },
  },
  { _id: false }
);

const H2HConversationSchema = new mongoose.Schema(
  {
    elderId: { type: Number, required: true },
    elderName: { type: String, default: "" },

    caregiverId: { type: Number, required: true },
    caregiverName: { type: String, default: "" },

    familyId: { type: Number, required: true },
    familyName: { type: String, default: "" },

    participants: { type: [ParticipantSchema], required: true },

    lastMessageText: { type: String, default: "" },
    lastMessageAt: { type: Date, default: null },
  },
  { timestamps: true }
);

H2HConversationSchema.index({ elderId: 1, caregiverId: 1, familyId: 1 }, { unique: true });
H2HConversationSchema.index({ "participants.userId": 1, lastMessageAt: -1 });

module.exports = mongoose.model("H2HConversation", H2HConversationSchema);
