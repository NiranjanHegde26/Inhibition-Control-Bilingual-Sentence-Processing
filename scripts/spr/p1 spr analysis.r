"
    Author: Niranjana Hegde B S
    Date of Creation: Oct 28, 2025
"
library(dplyr)
library(tidyr)
library(lmerTest)
library(ggplot2)

spr_file_list1 <- "data/spr/556325c7-8208-4b0c-ba22-851e82b9aa14_results (2).csv"
spr_file_list2 <- "data/spr/556325c7-8208-4b0c-ba22-851e82b9aa14_results (2).csv"
spr_file_list3 <- "data/spr/556325c7-8208-4b0c-ba22-851e82b9aa14_results (2).csv"
spr_file_list4 <- "data/spr/556325c7-8208-4b0c-ba22-851e82b9aa14_results (2).csv"

spr_df_l1 <- read.csv(spr_file_list1)
spr_df_l2 <- read.csv(spr_file_list2)
spr_df_l3 <- read.csv(spr_file_list3)
spr_df_l4 <- read.csv(spr_file_list4)

list1 <- ""
list2 <- ""
list3 <- ""
list4 <- ""

l1_materials <- read.csv(list1)
l2_materials <- read.csv(list2)
l3_materials <- read.csv(list3)
l4_materials <- read.csv(list4)

materials_file <- "materials/FinalMaterials.csv"
subtlex_us_file <- ""
subtlex_de_e
load(file.path(parent_dir, "Code/main study", "SUBTLEXus.RData"))
subtlex_de <- read.csv(file.path(parent_dir, "Code/main study", "subtlex_de_cleaned.csv"))

inhibition_composite_score_file <- "data/final analysis/inhibition_control_composite_scores.csv"
spr_df <- read.csv(spr_file)
# materials_df <- read.csv(materials_file)
item_properties_df <- read.csv(item_properties_file)
inhibition_composite_score_df <- read.csv(inhibition_composite_score_file)

colnames(materials_df)

# Bind
spr_df <- bind_rows(spr_df_l1, spr_df_l2, spr_df_l3, spr_df_l4)
materials_df <- bind_rows(list1, list2, list3, list4)
materials_df <- materials_df %>%
    rename(
        WordatP1 = P1
    )

# Filter only DashedSentences
spr_df_filtered <- spr_df %>%
    filter(PennElementName == "DashedSentence") %>%
    filter(user_id == "nbs2510" | user_id == "X") %>%
    filter(Condition != "Filler")

spr_df_for_P1 <- spr_df_filtered %>%
    left_join(materials_df %>% select(SentenceID, Critical.Position.Index, WordatP1),
        by = "SentenceID"
    ) %>%
    filter(Parameter == Critical.Position.Index)

spr_df_for_P1$wordLengthP1 <- nchar(spr_df_for_P1$WordatP1)
# TODO : Remove any responses that are faster than 200ms and slower than 1000ms.


# Define P1 and P2 types
spr_df <- spr_df %>%
    mutate(
        P1 = as.factor(ifelse(grepl("IH", Condition), "IH", "C1")),
        P2 = as.factor(ifelse(grepl("TE", Condition), "TE", "C2")),
    )


spr_df$ItemID <- as.integer(spr_df$ItemID)

# calculate the frequency and log freq of P1


spr_df_filtered_for_P1 <- spr_df_filtered_for_P1 %>%
    left_join(item_properties_df %>% select(LogFreqUS, LogFreqDE, phonetic_distance, ItemID, orthographic_distance),
        by = "ItemID"
    )

# Log Frequency, and Phonetic distance applies only for IH. So substitute the same value for C1 as well where ItemID matches.
spr_df_filtered_for_P1 <- spr_df_filtered_for_P1 %>%
    mutate(
        LogFreqUS = ifelse(P1 == "C1", LogFreqUS[which(P1 == "IH" & ItemID == ItemID)], LogFreqUS),
        LogFreqUS = ifelse(P1 == "C1", LogFreqUS[which(P1 == "IH" & ItemID == ItemID)], LogFreqUS),
        phonetic_distance = ifelse(P1 == "C1", phonetic_distance[which(P1 == "IH" & ItemID == ItemID)], phonetic_distance),
        orthographic_distance = ifelse(P1 == "C1", orthographic_distance[which(P1 == "IH" & ItemID == ItemID)], orthographic_distance)
    )

# Include individual inhibition control composite scores
inhibition_composite_score_df <- inhibition_composite_score_df %>% rename(user_id = workerid)

spr_df_filtered_for_P1 <- spr_df_filtered_for_P1 %>%
    left_join(inhibition_composite_score_df %>% select(user_id, composite_z), by = "user_id") %>%
    rename(inhibition_control_score = composite_z)


spr_df_filtered_for_P1$P1 <- as.factor(spr_df_filtered_for_P1$P1)
spr_df_filtered_for_P1$P2 <- as.factor(spr_df_filtered_for_P1$P2)
contrasts(spr_df_filtered_for_P1$P1) <- contr.sum(2)
contrasts(spr_df_filtered_for_P1$P2) <- contr.sum(2)

# Scale and center the terms
spr_df_filtered_for_P1$orthographic_distance_z <- scale(spr_df_filtered_for_P1$orthographic_distance, scale = TRUE, center = TRUE)
spr_df_filtered_for_P1$phonetic_distance_z <- scale(spr_df_filtered_for_P1$phonetic_distance, scale = TRUE, center = TRUE)
spr_df_filtered_for_P1$LogFreqDE_z <- scale(spr_df_filtered_for_P1$LogFreqDE, scale = TRUE, center = TRUE)
spr_df_filtered_for_P1$LogFreqUS_z <- scale(spr_df_filtered_for_P1$LogFreqUS, scale = TRUE, center = TRUE)
spr_df_filtered_for_P1$wordLengthP1_z <- scale(spr_df_filtered_for_P1$wordLengthP1, scale = TRUE, center = TRUE)


# Convert the raw RT to log RT
colnames(spr_df_filtered_for_P1)
hist(spr_df_filtered_for_P1$Reading.time)
spr_df_filtered_for_P1$p1LogRT <- log(spr_df_filtered_for_P1$Reading.time)

# Formula
base_formula <- as.formula(
    "p1LogRT ~ P1 * inhibition_control_score + LogFreqDE_z + LogFreqUS_z + wordLengthP1_z + (1 + P1 | user_id) + (1 | ItemID)"
)

# Extended base formula for Exploratory analysis
extended_base_formula <- as.formula(
    "p1LogRT ~ P1 * inhibition_control_score + LogFreqDE_z + LogFreqUS_z + phonetic_distance_z * P1 + orthographic_distance_z * P1 + wordLengthP1 + (1 + P1 | user_id) + (1 | ItemID)"
)
# p1_formula <- as.formula(
#     "p1LogRT ~ P1 * inhibition_control_score + LogFreqDE_z + LogFreqUS_z + phonetic_distance_z + orthographic_distance_z + (1 + P1 | user_id) + (1 | ItemID)"
# )

# Model
model <- lmer(formula = p1_formula, data = spr_df_filtered_for_P1)
