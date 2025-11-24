"
    Author: Niranjana Hegde B S
    Date of Creation: Oct 28, 2025
    This script calculates a composite score for inhibition control tasks based on Pivneva et al. (2014)
"
library(dplyr)
library(tidyr)
library(ggplot2)
library("jsonlite")

# File paths
getwd()
nl_stroop_file <- "data/inhibition control/NLStroop.csv"
nl_simon_file <- "data/inhibition control/Simon.csv"
number_stroop_file <- "data/inhibition control/NumberStroop.csv"

nl_stroop_df <- read.csv(nl_stroop_file)
nl_simon_df <- read.csv(nl_simon_file)
number_stroop_df <- read.csv(number_stroop_file)

# Process NL Stroop Data by extracting response and RT from answer and then using it as a column
nl_stroop_df <- nl_stroop_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        response = ifelse(is.null(parsed[["response"]]), NA_character_, parsed[["response"]][1]), # Handle null cases (no response)
        rt = ifelse(is.null(parsed[["RT"]]), NA_real_, parsed[["RT"]][1]) # Handle null cases (no response)
    ) %>%
    ungroup()
nl_stroop_df$item
# Now add a column to capture the accuracy
nl_stroop_df <- nl_stroop_df %>%
    rowwise() %>%
    mutate(
        is_correct = case_when(
            is.na(response) ~ 0,
            (response == "left" & item == "←") |
                (response == "right" & item == "→") ~ 1,
            TRUE ~ 0
        )
    ) %>%
    ungroup()
nl_stroop_df$is_correct

# Process NL Stroop Data by extracting response and RT from answer and then using it as a column
nl_simon_df <- nl_simon_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        response = ifelse(is.null(parsed[["response"]]), NA_character_, parsed[["response"]][1]), # Handle null cases (no response)
        rt = ifelse(is.null(parsed[["RT"]]), NA_real_, parsed[["RT"]][1]) # Handle null cases (no response)
    ) %>%
    ungroup()

# Now add a column to capture the accuracy
nl_simon_df <- nl_simon_df %>%
    rowwise() %>%
    mutate(
        is_correct = case_when(
            is.na(response) ~ 0,
            (response == "left" & item == "↑") |
                (response == "right" & item == "↓") ~ 1,
            TRUE ~ 0
        )
    ) %>%
    ungroup()
nl_simon_df$rt


# Process Number Stroop Data by extracting response and RT from answer and then using it as a column
number_stroop_df <- number_stroop_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        response = ifelse(is.null(parsed[["response"]]), NA_real_, as.numeric(parsed[["response"]][1])), # Handle null cases (no response)
        rt = ifelse(is.null(parsed[["RT"]]), NA_real_, parsed[["RT"]][1]) # Handle null cases (no response)
    ) %>%
    ungroup()
number_stroop_df$response

# Now add a column to capture the accuracy
number_stroop_df <- number_stroop_df %>%
    rowwise() %>%
    mutate(
        is_correct = case_when(
            is.na(response) ~ 0,
            (response == nchar(item)) ~ 1,
            TRUE ~ 0
        )
    ) %>%
    ungroup()

# Create tibbles to hold the scores for each task per each participant
nl_stroop_tibble <- nl_stroop_df %>%
    group_by(workerid) %>%
    summarise(
        nl_stroop_accuracy = mean(is_correct, na.rm = TRUE),
        nl_stroop_rt = mean(rt[is_correct == 1], na.rm = TRUE), # Mean RT for correct responses only
        nl_stroop_rt_congruent = mean(rt[is_correct == 1 & trialtype == "congruent"], na.rm = TRUE),
        nl_stroop_rt_incongruent = mean(rt[is_correct == 1 & trialtype == "incongruent"], na.rm = TRUE),
        nl_stroop_proportion_cost = (nl_stroop_rt_incongruent - nl_stroop_rt_congruent) / nl_stroop_rt_congruent
    )

nl_simon_tibble <- nl_simon_df %>%
    group_by(workerid) %>%
    summarise(
        nl_simon_accuracy = mean(is_correct, na.rm = TRUE),
        nl_simon_rt = mean(rt[is_correct == 1], na.rm = TRUE),
        nl_simon_rt_congruent = mean(rt[is_correct == 1 & trialtype == "congruent"], na.rm = TRUE),
        nl_simon_rt_incongruent = mean(rt[is_correct == 1 & trialtype == "incongruent"], na.rm = TRUE),
        nl_simon_proportion_cost = (nl_simon_rt_incongruent - nl_simon_rt_congruent) / nl_simon_rt_incongruent
    )

number_stroop_tibble <- number_stroop_df %>%
    group_by(workerid) %>%
    summarise(
        number_stroop_accuracy = mean(is_correct, na.rm = TRUE),
        number_stroop_rt = mean(rt[is_correct == 1], na.rm = TRUE),
        number_stroop_rt_congruent = mean(rt[is_correct == 1 & trialtype == "congruent"], na.rm = TRUE),
        number_stroop_rt_incongruent = mean(rt[is_correct == 1 & trialtype == "incongruent"], na.rm = TRUE),
        number_stroop_proportion_cost = (number_stroop_rt_incongruent - number_stroop_rt_congruent) / number_stroop_rt_congruent
    )

# Create a DF with scores for each task per each participant
inhibition_control_scores <- nl_simon_tibble %>%
    inner_join(number_stroop_tibble, by = "workerid") %>%
    inner_join(nl_stroop_tibble, by = "workerid")

# First scale the raw proportion cost
inhibition_control_scores$nl_simon_proportion_cost_z <- scale(inhibition_control_scores$nl_simon_proportion_cost, center = TRUE, scale = TRUE)
inhibition_control_scores$number_stroop_proportion_cost_z <- scale(inhibition_control_scores$number_stroop_proportion_cost, center = TRUE, scale = TRUE)
inhibition_control_scores$nl_stroop_proportion_cost_z <- scale(inhibition_control_scores$nl_stroop_proportion_cost, center = TRUE, scale = TRUE)

# Now take average for each participant
inhibition_control_scores <- inhibition_control_scores %>%
    rowwise() %>%
    mutate(
        composite_score = as.numeric((inhibition_control_scores$nl_simon_proportion_cost_z + inhibition_control_scores$number_stroop_proportion_cost_z + inhibition_control_scores$nl_stroop_proportion_cost_z) / 3)
    ) %>%
    ungroup()

# Write this to a CSV file
output_file <- "data/final analysis/inhibition_control_composite_scores.csv"
write.csv(inhibition_control_scores, output_file, row.names = FALSE)
