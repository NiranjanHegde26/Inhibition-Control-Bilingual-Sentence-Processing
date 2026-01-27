"
    Author: Niranjana Hegde B S
    Date of Creation: Oct 28, 2025
    This script calculates a composite score for inhibition control tasks based on Pivneva et al. (2014)
"
library(dplyr)
library(tidyr)
library(ggplot2)
library(Hmisc)
# install.packages("Hmisc")
library(stats)
library("jsonlite")

# File paths
getwd()
squared_stroop_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/StroopFinal.csv"
squared_simon_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/SimonFinal.csv"
squared_flanker_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/FlankerFinal.csv"
participants_based_on_proficiency_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/final analysis/participants_based_on_proficiency_full.csv"

squared_stroop_df <- read.csv(squared_stroop_file)
squared_simon_df <- read.csv(squared_simon_file)
squared_flanker_df <- read.csv(squared_flanker_file)
unique(squared_stroop_df$workerid)
participants_based_on_proficiency <- read.csv(participants_based_on_proficiency_file)

id_missing_in_stroop <- squared_simon_df %>%
    anti_join(squared_stroop_df, by = "workerid")

missing_id <- unique(id_missing_in_stroop$workerid) #  One has wrongly entered the ID in Stroop task
# Replace that ID with original ID and write it back to results
squared_stroop_df <- squared_stroop_df %>%
    mutate(
        workerid = ifelse(workerid == "Englisch", missing_id, workerid)
    )

# Process Stroop squared Data by extracting response and RT from answer and then using it as a column
squared_stroop_df <- squared_stroop_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        response = ifelse(is.null(parsed[["response"]]), NA_character_, parsed[["response"]][1]), # Handle null cases (no response)
        rt = ifelse(is.null(parsed[["RT"]]), NA_real_, parsed[["RT"]][1]), # Handle null cases (no response)
        isCorrect = ifelse(is.null(parsed[["isCorrect"]]), FALSE, parsed[["isCorrect"]][1]) # Handle null cases (no response)
    ) %>%
    ungroup()

# Process Simon Squared Data by extracting response and RT from answer and then using it as a column
squared_simon_df <- squared_simon_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        response = ifelse(is.null(parsed[["response"]]), NA_character_, parsed[["response"]][1]), # Handle null cases (no response)
        rt = ifelse(is.null(parsed[["RT"]]), NA_real_, parsed[["RT"]][1]), # Handle null cases (no response)
        isCorrect = ifelse(is.null(parsed[["isCorrect"]]), FALSE, parsed[["isCorrect"]][1]) # Handle null cases (no response)
    ) %>%
    ungroup()

# Process Flanker Squared Data by extracting response and RT from answer and then using it as a column
squared_flanker_df <- squared_flanker_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        response = ifelse(is.null(parsed[["response"]]), NA_real_, as.numeric(parsed[["response"]][1])), # Handle null cases (no response)
        rt = ifelse(is.null(parsed[["RT"]]), NA_real_, parsed[["RT"]][1]), # Handle null cases (no response)
        isCorrect = ifelse(is.null(parsed[["isCorrect"]]), FALSE, parsed[["isCorrect"]][1]) # Handle null cases (no response)
    ) %>%
    ungroup()

# Create tibbles to hold the scores for each task per each participant
squared_stroop_tibble <- squared_stroop_df %>%
    group_by(workerid) %>%
    summarise(
        squared_stroop_accuracy = sum(isCorrect, na.rm = TRUE),
        squared_stroop_rt = mean(rt[isCorrect == TRUE], na.rm = TRUE), # Mean RT for correct responses only
    )

squared_simon_tibble <- squared_simon_df %>%
    group_by(workerid) %>%
    summarise(
        squared_simon_accuracy = sum(isCorrect, na.rm = TRUE),
        squared_simon_rt = mean(rt[isCorrect == TRUE], na.rm = TRUE),
    )

squared_flanker_tibble <- squared_flanker_df %>%
    group_by(workerid) %>%
    summarise(
        squared_flanker_accuracy = sum(isCorrect, na.rm = TRUE),
        squared_flanker_rt = mean(rt[isCorrect == TRUE], na.rm = TRUE),
    )

# Create a DF with scores for each task per each participant
inhibition_control_scores <- squared_simon_tibble %>%
    inner_join(squared_flanker_tibble, by = "workerid") %>%
    inner_join(squared_stroop_tibble, by = "workerid")

# Only retain those participants who have cleared the proficiency filters
inhibition_control_scores_filtered <- inhibition_control_scores[
    inhibition_control_scores$workerid %in% participants_based_on_proficiency$workerid,
]

# First scale the raw accuracy scores
inhibition_control_scores_filtered$squared_simon_accuracy_z <- scale(inhibition_control_scores_filtered$squared_simon_accuracy, center = TRUE, scale = TRUE)
inhibition_control_scores_filtered$squared_flanker_accuracy_z <- scale(inhibition_control_scores_filtered$squared_flanker_accuracy, center = TRUE, scale = TRUE)
inhibition_control_scores_filtered$squared_stroop_accuracy_z <- scale(inhibition_control_scores_filtered$squared_stroop_accuracy, center = TRUE, scale = TRUE)

# Now take average for each participant
inhibition_control_scores_filtered <- inhibition_control_scores_filtered %>%
    rowwise() %>%
    mutate(
        composite_score = as.numeric((squared_simon_accuracy_z + squared_flanker_accuracy_z + squared_stroop_accuracy_z) / 3)
    ) %>%
    ungroup()

hist(inhibition_control_scores_filtered$composite_score)

# Normality Check for all scores
shapiro.test(inhibition_control_scores_filtered$squared_simon_accuracy_z)
shapiro.test(inhibition_control_scores_filtered$squared_flanker_accuracy_z)
shapiro.test(inhibition_control_scores_filtered$squared_stroop_accuracy_z)
shapiro.test(inhibition_control_scores_filtered$composite_score)

## Check for intercorrelations and PCA
# Correlation matrix
# Reference: https://statsandr.com/blog/correlation-coefficient-and-correlation-test-in-r/#correlation-matrix-correlations-for-all-variables

mtx_for_correlation <- inhibition_control_scores_filtered %>%
    select(squared_simon_accuracy_z, squared_flanker_accuracy_z, squared_stroop_accuracy_z)

correlation_matrix <- rcorr(as.matrix(mtx_for_correlation), type = "spearman") # Since the data isn't normal
correlation_matrix

# PCA
pca_inhibition_scores <- prcomp(mtx_for_correlation, scale. = TRUE)
pca_inhibition_scores$rotation <- -1 * pca_inhibition_scores$rotation
pca_inhibition_scores$rotation

# Write this to a CSV file
output_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data//final analysis/inhibition_control_composite_scores_full.csv"
write.csv(inhibition_control_scores_filtered, output_file, row.names = FALSE)
