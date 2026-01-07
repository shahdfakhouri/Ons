import pandas as pd
import os

# 1. Define the paths
input_file = os.path.join('..', 'data', 'ons_raw_data.csv')
output_file = os.path.join('..', 'data', 'ons_clean_data.csv')

# 2. Load the raw data
df = pd.read_csv(input_file)

# 3. Define emotions that are most relevant for an elder's companion
elder_emotions = ['sentimental', 'lonely', 'grateful', 'proud', 'sad', 'nostalgic', 'hopeful', 'apprehensive']

# 4. Filter: Keep only these emotions and remove empty rows
# We use .copy() to make sure we are working on a new version of the data
clean_df = df[df['emotion'].isin(elder_emotions)].copy()

# 5. Column Selection: We only need the Story, the Emotion, and the Human Reply
# Based on your output, these columns are: 'Situation', 'emotion', and 'empathetic_dialogues'
clean_df = clean_df[['Situation', 'emotion', 'empathetic_dialogues']]

# 6. Save the new "Clean" file
clean_df.to_csv(output_file, index=False)

print("-" * 30)
print("CLEANING COMPLETE!")
print(f"Original rows: {len(df)}")
print(f"New Elder-Focused rows: {len(clean_df)}")
print(f"File saved at: {output_file}")
print("-" * 30)