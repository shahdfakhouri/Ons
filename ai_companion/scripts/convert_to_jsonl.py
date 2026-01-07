import pandas as pd
import json
import os

# 1. Paths
input_file = os.path.join('..', 'data', 'ons_clean_data.csv')
output_file = os.path.join('..', 'data', 'ons_training_data.jsonl')

# 2. Load the clean data
df = pd.read_csv(input_file)

# 3. Define the ONS Identity (The System Prompt)
# This is where you tell the AI how to act
SYSTEM_PROMPT = "أنت أنس (ONS)، رفيق متعاطف لكبار السن. استمع بعمق، رد بلطف، وكن صبوراً جداً."

print("Converting CSV to JSONL format...")

with open(output_file, 'w', encoding='utf-8') as f:
    # We will use the first 500 rows for a fast first training session
    # (Using all 15,000 would be very expensive and slow for your first test)
    for i, row in df.head(500).iterrows():
        # Create the conversation structure
        conversation = {
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": str(row['Situation'])},
                {"role": "assistant", "content": str(row['empathetic_dialogues'])}
            ]
        }
        # Save as one line in the JSONL file
        f.write(json.dumps(conversation, ensure_ascii=False) + '\n')

print("-" * 30)
print("SUCCESS!")
print(f"Created training file: {output_file}")
print("This file is now ready to be uploaded to OpenAI!")
print("-" * 30)