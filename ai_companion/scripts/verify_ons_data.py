import pandas as pd
import os

# Path to the file
file_path = os.path.join('..', 'data', 'ons_raw_data.csv')

if os.path.exists(file_path):
    print("✅ SUCCESS: ONS folder has the data file!")
    
    # Load the data
    df = pd.read_csv(file_path)
    
    print("\n--- DATASET DETAILS ---")
    print(f"Total Rows: {len(df)}")
    
    # This line tells us the names of the columns (e.g., 'text', 'emotion', 'situation')
    print("\nColumn Names found in this file:")
    print(df.columns.tolist())
    
    print("\n--- PREVIEW (First 3 rows) ---")
    print(df.head(3))
else:
    print("❌ ERROR: File not found. Check the 'data' folder for 'ons_raw_data.csv'")