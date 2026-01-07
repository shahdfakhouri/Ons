from datasets import load_dataset
import pandas as pd
import os

# 1. Setup paths
data_dir = os.path.join('..', 'data')
if not os.path.exists(data_dir):
    os.makedirs(data_dir)

print("Attempting to download Empathetic Dialogues...")

try:
    # 2. Load the dataset using the standard 'datasets' method
    # We use 'trust_remote_code=True' which is now required for this dataset
    dataset = load_dataset("facebook/empathetic_dialogues", trust_remote_code=True)

    # 3. Convert the 'train' split to a Pandas DataFrame
    train_df = pd.DataFrame(dataset['train'])

    # 4. Save as a local CSV file
    output_path = os.path.join(data_dir, "ons_raw_train.csv")
    train_df.to_csv(output_path, index=False)

    print("-" * 30)
    print("SUCCESS!")
    print(f"Dataset saved at: {output_path}")
    print(f"Total rows: {len(train_df)}")
    print("-" * 30)

except Exception as e:
    print(f"Error: {e}")
    print("\nIf you see a 'scripts are no longer supported' error, try this command in terminal first:")
    print("pip install --upgrade datasets")