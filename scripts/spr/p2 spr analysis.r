"
    Author: Niranjana Hegde B S
    Date of Creation: Oct 29, 2025
"

library(dplyr)
library(tidyr)
library(lmerTest)
library(ggplot2)
library(emmeans)

spr_file <- "data/spr/556325c7-8208-4b0c-ba22-851e82b9aa14_results (2).csv"
materials_file <- "materials/main.csv"
item_properties_file <- "materials/frequency_list.csv"
inhibition_composite_score_file <- "data/final analysis/inhibition_control_composite_scores.csv"
spr_df <- read.csv(spr_file)
materials_df <- read.csv(materials_file)
item_properties_df <- read.csv(item_properties_file)
inhibition_composite_score_df <- read.csv(inhibition_composite_score_file)


# Filter only DashedSentences
spr_df_filtered <- spr_df %>%
    filter(PennElementName == "DashedSentence") %>%
    filter(user_id == "nbs2510" | user_id == "X") %>%
    filter(Condition != "Filler")

# TODO : Remove any responses that are faster than 200ms and slower than 1000ms.

spr_df_filtered_for_P2 <- spr_df_filtered %>%
    left_join(materials_df %>% select(SentenceID, Post.Critical.Position.Index),
        by = "SentenceID"
    ) %>%
    filter(Parameter == Post.Critical.Position.Index)

spr_df_filtered_for_P2 <- spr_df_filtered_for_P2 %>%
    mutate(
        P1 = as.factor(ifelse(grepl("IH", Condition), "IH", "C1")),
        P2 = as.factor(ifelse(grepl("TE", Condition), "TE", "C2")),
    )
spr_df_filtered_for_P2$ItemID <- as.integer(spr_df_filtered_for_P2$ItemID)

# spr_df_filtered_for_P2 <- spr_df_filtered_for_P2 %>%
#     left_join(item_properties_df %>% select(LogFreqUS, LogFreqDE, phonetic_distance, ItemID, orthographic_distance),
#         by = "ItemID"
#     )

# Log Frequency, and Phonetic distance applies only for IH. So substitute the same value for C1 as well where ItemID matches.
# spr_df_filtered_for_P1 <- spr_df_filtered_for_P1 %>%
#     mutate(
#         LogFreqUS = ifelse(P1 == "C1", LogFreqUS[which(P1 == "IH" & ItemID == ItemID)], LogFreqUS),
#         LogFreqUS = ifelse(P1 == "C1", LogFreqUS[which(P1 == "IH" & ItemID == ItemID)], LogFreqUS),
#         phonetic_distance = ifelse(P1 == "C1", phonetic_distance[which(P1 == "IH" & ItemID == ItemID)], phonetic_distance),
#         orthographic_distance = ifelse(P1 == "C1", orthographic_distance[which(P1 == "IH" & ItemID == ItemID)], orthographic_distance)
#     )

# Include individual inhibition control composite scores
inhibition_composite_score_df <- inhibition_composite_score_df %>% rename(user_id = workerid)

spr_df_filtered_for_P2 <- spr_df_filtered_for_P2 %>%
    left_join(inhibition_composite_score_df %>% select(user_id, composite_z), by = "user_id") %>%
    rename(inhibition_control_score = composite_z)


spr_df_filtered_for_P2$P1 <- as.factor(spr_df_filtered_for_P2$P1)
spr_df_filtered_for_P2$P2 <- as.factor(spr_df_filtered_for_P2$P2)
contrasts(spr_df_filtered_for_P2$P1) <- contr.sum(2)
contrasts(spr_df_filtered_for_P2$P2) <- contr.sum(2)

# # Scale and center the terms
# spr_df_filtered_for_P1$orthographic_distance_z <- scale(spr_df_filtered_for_P1$orthographic_distance, scale = TRUE, center = TRUE)
# spr_df_filtered_for_P1$phonetic_distance_z <- scale(spr_df_filtered_for_P1$phonetic_distance, scale = TRUE, center = TRUE)
# spr_df_filtered_for_P1$LogFreqDE_z <- scale(spr_df_filtered_for_P1$LogFreqDE, scale = TRUE, center = TRUE)
# spr_df_filtered_for_P1$LogFreqUS_z <- scale(spr_df_filtered_for_P1$LogFreqUS, scale = TRUE, center = TRUE)


# Convert the raw RT to log RT
colnames(spr_df_filtered_for_P1)
hist(spr_df_filtered_for_P2$Reading.time)
spr_df_filtered_for_P2$p2LogRT <- log(spr_df_filtered_for_P2$Reading.time)

# Formula
p2_formula <- as.formula(
    "p2LogRT ~ P1 * P2 + P1 * P2 * inhibition_control_score + wordLengthP2 + (1 + P1 * P2| user_id) + (1 + P1 * P2| ItemID)"
)

# RT can be influenced by:
# - The type of word in P2 (well not as a main effect for sure, but still) - Not directly modelled
# - The type of word in P1 and P2 (main hypothesis)
# - The interaction between P1, P2 and inhibition control score (Those with higher inhibition control are slower at P2 (TE) when P1 is IH)


# Model
model <- lmer(formula = p2_formula, data = spr_df_filtered_for_P2)
summary(model)

pairwiseComp <- emmeans(model, ~ P1 | P2, at = list(inhibition_control_score = c(-2, 0, 2)))
pairs(pairwiseComp)
