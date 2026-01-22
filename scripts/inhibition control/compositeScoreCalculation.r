# ============================================================
# Title:    Inhibition Control Score Calculation Script
# Project:  Individual Differences of Inhibition Control in Bilingual Sentence Processing: A Self Paced Reading Approach
# OSF:      https://osf.io/uyvxw
# Author:   Niranjana Hegde Bhimanakone Satyanarayana
# Created:  28/10/2025
# R version: 4.3.2
#
# Description:
# This script calculates the composite score of inhibition control score
# from individual scores of each participant from Flanker Squared, Simon
# Squared and Stroop Squared task and
# provides descriptive statistics for each task.
# Additional validation of tasks are done by checking the inter-correlation of
# all tasks, and using PCA to identify the principle components.
# Later each participants' score are written back to a separate file.
#
# Dependency:
# - People should be already filtered based on English Proficiency by running the script Inhibition-Control-Bilingual-Sentence-Processing\scripts\proficiency\proficiency _analysis.r
# ============================================================

# Load libraries
library(dplyr)
library(tidyr)
library(ggplot2)
library(Hmisc)
library(stats)
library("jsonlite")

# File paths
squared_stroop_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/StroopFinal.csv"
squared_simon_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/SimonFinal.csv"
squared_flanker_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/inhibition control/FlankerFinal.csv"
participants_based_on_proficiency_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/final analysis/participants_based_on_proficiency.csv"

squared_stroop_df <- read.csv(squared_stroop_file)
squared_simon_df <- read.csv(squared_simon_file)
squared_flanker_df <- read.csv(squared_flanker_file)

participants_based_on_proficiency <- read.csv(participants_based_on_proficiency_file)

# A participant mistakenly wrote "English" in place of ID, only for Stroop task.
# But this participant had correctly written their ID everywhere else,
# including the tasks that followed Stroop.
# So we are just replacing the wrong ID entry.
id_missing_in_stroop <- squared_simon_df %>%
    anti_join(squared_stroop_df, by = "workerid")

missing_id <- unique(id_missing_in_stroop$workerid)

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

# Create a dataframe with scores for each task per each participant
inhibition_control_scores <- squared_simon_tibble %>%
    inner_join(squared_flanker_tibble, by = "workerid") %>%
    inner_join(squared_stroop_tibble, by = "workerid")

# Only retain those participants who have cleared the proficiency filters
inhibition_control_scores_filtered <- inhibition_control_scores[
    inhibition_control_scores$workerid %in% participants_based_on_proficiency$workerid,
]

# Now include only those whose comprehension accuracy at SPR is greater than 0.5
inhibition_control_scores_filtered <- inhibition_control_scores_filtered %>%
    filter(workerid %in% participants_based_on_proficiency$workerid[participants_based_on_proficiency$comprehensionAccuracy > 0.50])

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

# Use the task raw scores and composite scores into a single plot with facet histograms
plot_path <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/Plots/lmer"
stroop_hist <- ggplot(inhibition_control_scores_filtered, aes(x = squared_stroop_accuracy)) +
    geom_histogram(color = "#575555", fill = "#00bfc4") +
    labs(
        x = "Stroop Squared Task Accuracy",
        y = "Frequency",
        title = "Stroop Squared Task Accuracy Distribution Plot"
    ) +
    theme_minimal(base_size = 12) +
    theme(
        plot.title = element_text(hjust = 0.5, size = 10)
    )
ggsave(filename = file.path(plot_path, "stroop_hist.png"), stroop_hist, width = 4, height = 4, dpi = 300)


simon_hist <- ggplot(inhibition_control_scores_filtered, aes(x = squared_simon_accuracy)) +
    geom_histogram(color = "#575555", fill = "#f8766d") +
    labs(
        x = "Simon Squared Task Accuracy",
        y = "Frequency",
        title = "Simon Squared Task Accuracy Distribution Plot"
    ) +
    theme_minimal(base_size = 12) +
    theme(
        plot.title = element_text(hjust = 0.5, size = 10)
    )
ggsave(filename = file.path(plot_path, "simon_hist.png"), simon_hist, width = 4, height = 4, dpi = 300)


flanker_hist <- ggplot(inhibition_control_scores_filtered, aes(x = squared_flanker_accuracy)) +
    geom_histogram(color = "#575555", fill = "#00bfc4") +
    labs(
        x = "Flanker Squared Task Accuracy",
        y = "Frequency",
        title = "Flanker Squared Task Accuracy Distribution Plot"
    ) +
    theme_minimal(base_size = 12) +
    theme(
        plot.title = element_text(hjust = 0.5, size = 10)
    )
ggsave(filename = file.path(plot_path, "flanker_hist.png"), flanker_hist, width = 4, height = 4, dpi = 300)


comp_hist <- ggplot(inhibition_control_scores_filtered, aes(x = composite_score)) +
    geom_histogram(color = "#575555", fill = "#f8766d") +
    labs(
        x = "Inhibition Control Composite Score (Scaled)",
        y = "Frequency",
        title = "Inhibition Control Composite Score Distribution Plot"
    ) +
    theme_minimal(base_size = 12) +
    theme(
        plot.title = element_text(hjust = 0.5, size = 10)
    )
ggsave(filename = file.path(plot_path, "comp_hist.png"), comp_hist, width = 4, height = 4, dpi = 300)


## Check for intercorrelations and PCA
# Correlation matrix
# Reference: https://statsandr.com/blog/correlation-coefficient-and-correlation-test-in-r/#correlation-matrix-correlations-for-all-variables

mtx_for_correlation <- inhibition_control_scores_filtered %>%
    select(squared_simon_accuracy_z, squared_flanker_accuracy_z, squared_stroop_accuracy_z)

correlation_matrix <- rcorr(as.matrix(mtx_for_correlation), type = "spearman") # Since the data isn't normal

# PCA analysis
pca_inhibition_scores <- prcomp(mtx_for_correlation, scale. = TRUE)
# Rotation Values were negative for PC1. So reversed it by multiplying it by -1
# Reference: https://stats.stackexchange.com/questions/30348/is-it-acceptable-to-reverse-a-sign-of-a-principal-component-score
pca_inhibition_scores$rotation <- -1 * pca_inhibition_scores$rotation
pca_inhibition_scores$x <- -1 * pca_inhibition_scores$x

# Checking the correlation between calculated composite score and PC1
cor.test(inhibition_control_scores_filtered$composite_score, pca_inhibition_scores$x[, 1])

# Write this to a CSV file
output_file <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data//final analysis/inhibition_control_composite_scores.csv"
write.csv(inhibition_control_scores_filtered, output_file, row.names = FALSE)
