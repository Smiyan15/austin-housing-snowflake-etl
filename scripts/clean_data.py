import pandas as pd
import csv

# 1. Load the original file
file_name = 'AustinHousingDATAShort.csv'
df = pd.read_csv(file_name)

# 2.  clean the description
df['description'] = df['description'].fillna('').apply(lambda x: " ".join(str(x).split()))

# 3. Save as a CSV
df.to_csv('Austin_Housing_LOAD_ME.csv', index=False, quoting=csv.QUOTE_ALL)

print("DONE!")
