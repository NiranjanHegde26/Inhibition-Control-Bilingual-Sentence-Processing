import pandas as pd
from pathlib import Path

spr_file_list1 = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/spr/29107b08-8dc4-4987-b1a3-1f0596ac3c7e_results.csv")
spr_file_list2 = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/spr/06a109e9-1300-45b0-8445-c45643f19279_results.csv")
spr_file_list3 = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/spr/25e35492-fc79-4a22-bcc5-7f7d89a9aee8_results.csv")
spr_file_list4 = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/spr/eed95789-5869-4db7-8a1c-210b900bcd14_results.csv")
leapq_results_file = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/proficiency/LEAP-Q_Final.csv")
lexTale_results_file = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/proficiency/LexTALE-Final.csv")

squared_stroop_file = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/StroopFinal.csv")
squared_simon_file = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/SimonFinal.csv")
squared_flanker_file = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/FlankerFinal.csv")
participants_based_on_proficiency_file = Path(r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/final analysis/participants_based_on_proficiency_full.csv")

lexTale = pd.read_csv(lexTale_results_file)
unique_users = lexTale["workerid"].unique()

user_map = {
    user_id: f"P{i+1}"
    for i, user_id in enumerate(unique_users)
}

list1 = [spr_file_list1, spr_file_list2, spr_file_list3, spr_file_list4]
for file in list1:
    temp_df = pd.read_csv(file)
    temp_df["user_id"] = temp_df["user_id"].map(user_map)
    anon_out = file.with_name(file.stem + "_anonym.csv")
    temp_df.to_csv(anon_out, index=False)
    
list2 = [leapq_results_file, lexTale_results_file, squared_stroop_file, squared_simon_file, squared_flanker_file, participants_based_on_proficiency_file]
for file in list2:
    temp_df = pd.read_csv(file)
    temp_df["workerid"] = temp_df["workerid"].map(user_map)
    anon_out = file.with_name(file.stem + "_anonym.csv")
    temp_df.to_csv(anon_out, index=False)
    
mapping_file = Path(
    r"D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/user_id_mapping.csv"
)

pd.DataFrame(
    user_map.items(),
    columns=["original_userId", "pseudo_userId"]
).to_csv(mapping_file, index=False)