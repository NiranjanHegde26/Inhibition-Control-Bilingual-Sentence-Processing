library(dplyr)
library(tidyr)
library(stringr)

# Main CSV file with Critical sentences
main_csv <- "materials/FinalMaterials.csv"
main_df <- read.csv(main_csv)

# Ensure that the trailing spaces are removed (not to mess up SPR), and
# the sentences are capitalized
main_df$Sentence <- str_trim(main_df$Sentence, side = "both")
main_df$Sentence <- str_to_upper(main_df$Sentence, locale = "en")
main_df$SentenceID <- seq_len(nrow(main_df))

critical_material_df <- main_df[main_df$Type != "Filler", ]
fillers_df <- main_df[main_df$Type == "Filler", ]

data_df <- critical_material_df %>%
    group_by(ItemID) %>%
    mutate(
        ListName = paste0(
            "List", ((row_number() - 1 + (ItemID - 1)) %% 4) + 1 # We want to create 4 lists and rotate the list numbers across each item and condition
        ),
    ) %>%
    ungroup()

table(data_df$Type, data_df$ListName)

list1_df <- data_df %>%
    filter(ListName == "List1")

list2_df <- data_df %>%
    filter(ListName == "List2")

list3_df <- data_df %>%
    filter(ListName == "List3")

list4_df <- data_df %>%
    filter(ListName == "List4")

# Add fillers to each list
list1_df <- bind_rows(list1_df, fillers_df)
list2_df <- bind_rows(list2_df, fillers_df)
list3_df <- bind_rows(list3_df, fillers_df)
list4_df <- bind_rows(list4_df, fillers_df)

# Remove some columns and update the sentence Ids
list1_df <- list1_df %>%
    select(-Phrase.2.structure) %>%
    ungroup() %>%
    mutate(
        SentenceIDInList = row_number(),
        ListName = if_else(is.na(ListName), "List1", ListName)
    )

list2_df <- list2_df %>%
    select(-Phrase.2.structure) %>%
    ungroup() %>%
    mutate(SentenceIDInList = row_number(), ListName = if_else(is.na(ListName), "List2", ListName))

list3_df <- list3_df %>%
    select(-Phrase.2.structure) %>%
    ungroup() %>%
    mutate(SentenceIDInList = row_number(), ListName = if_else(is.na(ListName), "List3", ListName))

list4_df <- list4_df %>%
    select(-Phrase.2.structure) %>%
    ungroup() %>%
    mutate(SentenceIDInList = row_number(), ListName = if_else(is.na(ListName), "List4", ListName))

# Write the list details into CSV files
write.csv(list1_df, "materials\\List1.csv")
write.csv(list2_df, "materials\\List2.csv")
write.csv(list3_df, "materials\\List3.csv")
write.csv(list4_df, "materials\\List4.csv")
