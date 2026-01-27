# ============================================================
# Title:    English Proficiency Analysis Script
# Project:  Individual Differences of Inhibition Control in Bilingual Sentence Processing: A Self Paced Reading Approach
# OSF:      https://osf.io/uyvxw
# Author:   Niranjana Hegde Bhimanakone Satyanarayana
# Created:  07/11/2025
# R version: 4.3.2
#
# Description:
# This script analyses (and prints the descriptive statistics) of the
# English proficiency measures based on the ratings and responses
# provided by the participants for LexTALE and LEAP-Q tasks,
# & writes the results back to a file to be used later for reading time analysis.
#
#
# Note:
# The descriptive statistics reported in the thesis is collected after
# removing 2 participants with below chance level accuracy at comprehension
# questions of SPR. An additional filter condition was added to this file
# by manually extracting the user ID of them
# ============================================================

# Load libraries
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(ggplot2)
library("jsonlite")

# Response files from tasks
leapq_results_file <- "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\data\\proficiency\\LEAPQFinal.csv"
lexTale_results_file <- "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\data\\proficiency\\LexTALEFinal.csv"

leap_q_df <- read.csv(leapq_results_file)
lexTale_df <- read.csv(lexTale_results_file)

# ============================================================
# LexTALE Analysis
# ============================================================
lexTale_df <- lexTale_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        selected = ifelse(is.null(parsed[["selected"]]), NA_real_, as.numeric(parsed[["selected"]][1]))
    )

lexTale_performance <- lexTale_df %>%
    filter(itemno != 0) %>% # Remove all the dummy values
    group_by(workerid) %>%
    summarise(
        correctWord = sum(wordstatus == 1 & selected == 1, na.rm = TRUE),
        correctNonWord = sum(wordstatus == 0 & selected == 0, na.rm = TRUE),
        totalCorrect = correctNonWord + correctWord,
        score = (((correctNonWord / 20) * 100) + ((correctWord / 40) * 100)) / 2 # Formula from LexTALE paper
    )

# List the no. of participants who performed below chance level for each type of words
print(paste0("Participants who scored below chance level for words: ", nrow(lexTale_performance %>% filter(correctWord < 20))))
print(paste0("Participants who scored below chance level for non-words: ", nrow(lexTale_performance %>% filter(correctNonWord < 10))))
print(paste0("Participants who scored below chance level in the task: ", nrow(lexTale_performance %>% filter(totalCorrect < 30))))

# The score threshold comes from Lemhöfer and Broersma (2012).
# 60 or above corresponds to B1 CFBR level or above
lex_filtered <- lexTale_performance %>%
    filter(score >= 60)
print(paste0("Participants who scored above 60: ", nrow(lex_filtered)))


# ============================================================
# Modified LEAP-Q Analysis
# ============================================================
# Filter those participants who have scored above 60 in LexTALE
leap_q_df <- leap_q_df %>%
    filter(workerid %in% lex_filtered$workerid)

leap_q_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        age = ifelse(is.null(parsed[["age"]]), NA_real_, as.numeric(parsed[["age"]][1])),
        gender = ifelse(is.null(parsed[["gender"]]), NA_character_, parsed[["gender"]][1]),
        motherTongue = ifelse(is.null(parsed[["motherTongue"]]), NA_character_, str_to_lower(parsed[["motherTongue"]][1])),
        engExposure = ifelse(is.null(parsed[["motherTongue"]]), NA_character_, parsed[["motherTongue"]][1]),
        q1 = ifelse(is.null(parsed[["q1"]]), NA, list(parsed[["q1"]])),
        l1 = str_to_lower(q1$l1),
        l2 = str_to_lower(q1$l2),
        l3 = str_to_lower(q1$l3),
        l4 = str_to_lower(q1$l4),
        l5 = str_to_lower(q1$l5),
        q2 = ifelse(is.null(parsed[["q2"]]), NA, list(parsed[["q2"]])),
        q3 = ifelse(is.null(parsed[["q3"]]), NA, list(parsed[["q3"]])),
        q4 = ifelse(is.null(parsed[["q4"]]), NA, list(parsed[["q4"]])),
        q5 = ifelse(is.null(parsed[["q5"]]), NA, list(parsed[["q5"]])),
        q7 = ifelse(is.null(parsed[["q5"]]), NA, list(parsed[["q7"]])),
        q9 = ifelse(is.null(parsed[["q5"]]), NA, list(parsed[["q9"]])),
        eng = ifelse(is.null(parsed[["eng"]]), NA, list(parsed[["eng"]])),
    ) %>%
    ungroup()

# Disabilities
disabilities_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        disabilities = ifelse(is.null(q9) || is.null(q9$a), NA_character_, paste(q9$a, collapse = ", "))
    ) %>%
    ungroup() %>%
    select(workerid, disabilities)
table(disabilities_df$disabilities)

# Remove all those who have speech related disabilities
leap_q_df <- leap_q_df %>%
    rowwise() %>%
    filter(!is.null(q9) & !is.null(q9$a) & q9$a != "Sprachvermögens") %>%
    ungroup()

# Remove all those whose L1 is not German
# But for some reason, even those who mention that German is their mother tongue is German didn't report it in L1!
# So, only filter it based on mother tongue column
leap_q_df <- leap_q_df %>%
    rowwise() %>%
    filter(
        motherTongue %in% c("deutsch", "german", "deutch", "duetsch", "deutshc"),
    ) %>%
    ungroup()

calculate_months <- function(x) {
    if (is.null(x$year) || is.null(x$month)) {
        return(0)
    }
    if (is.na(x$year) && is.na(x$month)) {
        return(0)
    }
    return(as.integer(x$year * 12 + x$month))
}

# Duration of stay in English Speaking countries,
# and duration of exposure to English from schools,
# workplaces
duration_of_stay_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        durationOfStayInMonths =
            calculate_months(eng$q2$a),
        durationOfExposureAtSchoolWorkplaceInMonths =
            calculate_months(eng$q2$c)
    ) %>%
    ungroup() %>%
    select(
        workerid,
        durationOfStayInMonths,
        durationOfExposureAtSchoolWorkplaceInMonths
    )

# I cannot control for Immersion effects if they have lived in English speaking country for a long time.
# This was missed in preregistration process
leap_q_df <- leap_q_df %>%
    filter(
        workerid %in% duration_of_stay_df$workerid[duration_of_stay_df$durationOfStayInMonths < 50]
    )

summary(duration_of_stay_df$durationOfStayInMonths)
sd(duration_of_stay_df$durationOfStayInMonths)

summary(duration_of_stay_df$durationOfExposureAtSchoolWorkplaceInMonths)
sd(duration_of_stay_df$durationOfExposureAtSchoolWorkplaceInMonths)

# Map all variations of language names to standard versions - applicable only for English and German
leap_q_df <- leap_q_df %>%
    mutate(
        l1 = case_when(
            l1 %in% c("deutsch", "german", "deutch", "duetsch") ~ "German",
            l1 %in% c("englisch", "english", "englsich") ~ "English",
            TRUE ~ l1
        ),
        l2 = case_when(
            l2 %in% c("deutsch", "german", "deutch", "duetsch") ~ "German",
            l2 %in% c("englisch", "english", "englsich") ~ "English",
            TRUE ~ l2
        ),
        l3 = case_when(
            l3 %in% c("deutsch", "german", "deutch", "duetsch") ~ "German",
            l3 %in% c("englisch", "english", "englsich") ~ "English",
            TRUE ~ l3
        ),
        l4 = case_when(
            l4 %in% c("deutsch", "german", "deutch", "duetsch") ~ "German",
            l4 %in% c("englisch", "english", "englsich") ~ "English",
            TRUE ~ l4
        ),
        l5 = case_when(
            l5 %in% c("deutsch", "german", "deutch", "duetsch") ~ "German",
            l5 %in% c("englisch", "english", "englsich") ~ "English",
            TRUE ~ l5
        )
    )

# Now I keep track of the column that contains English so that I can reuse this column later
# Reference: https://www.rdocumentation.org/packages/dplyr/versions/1.0.10/topics/c_across
leap_q_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        eng_index = which(c_across(l1:l5) == "English")[1]
    ) %>%
    ungroup()

# There are different levels of LEAP-Q questions with different scales.
# Age
age_df <- leap_q_df %>%
    group_by(workerid) %>%
    select(workerid, age)
summary(age_df$age)
sd(age_df$age)

# Gender
gender_df <- leap_q_df %>%
    group_by(workerid) %>%
    select(workerid, gender)
table(gender_df$gender)

# English Exposure
english_exposure_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        english_exposure = if (is.null(q3[[eng_index]])) NA_integer_ else as.integer(q3[[eng_index]])
    ) %>%
    ungroup() %>%
    select(workerid, english_exposure)

summary(english_exposure_df$english_exposure)
sd(english_exposure_df$english_exposure)

# English Reading preferences
reading_preferences_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        english_reading_preference = if (is.null(q4[[eng_index]])) NA_integer_ else as.integer(q4[[eng_index]])
    ) %>%
    ungroup() %>%
    select(workerid, english_reading_preference)
summary(reading_preferences_df$english_reading_preference)
sd(reading_preferences_df$english_reading_preference)

# Speaking Preferences
speaking_preferences_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        english_speaking_preference = if (is.null(q5[[eng_index]])) NA_integer_ else as.integer(q5[[eng_index]])
    ) %>%
    ungroup() %>%
    select(workerid, english_speaking_preference)
summary(speaking_preferences_df$english_speaking_preference)
sd(speaking_preferences_df$english_speaking_preference)

# Q7 (a) - Formal Education
formal_education_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        years = ifelse(is.null(q7) || is.null(q7$a), NA_integer_, as.integer(q7$a)),
        educationLevel = ifelse(is.null(q7) || is.null(q7$b), NA_character_, q7$b)
    ) %>%
    ungroup() %>%
    select(workerid, years, educationLevel)
table(formal_education_df$educationLevel)

# Screen 2 - Dedicated to English Proficiency
english_proficiency_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        AoA = ifelse(is.null(eng$q1$a), 0, as.integer(eng$q1$a)),
        readingAcquistion = ifelse(is.null(eng$q1$c), 0, as.integer(eng$q1$c)),
        selfRatedProficiencySpeaking = ifelse(is.null(eng$q3$speaking), NA_integer_, as.integer(substr(eng$q3$speaking, 1, 1))),
        selfRatedProficiencyUnderstanding = ifelse(is.null(eng$q3$understanding), NA_integer_, as.integer(substr(eng$q3$understanding, 1, 1))),
        selfRatedProficiencyReading = ifelse(is.null(eng$q3$reading), NA_integer_, as.integer(substr(eng$q3$reading, 1, 1))),
    ) %>%
    ungroup() %>%
    select(workerid, AoA, readingAcquistion, selfRatedProficiencySpeaking, selfRatedProficiencyUnderstanding, selfRatedProficiencyReading)
summary(english_proficiency_df$AoA)
sd(english_proficiency_df$AoA)

summary(english_proficiency_df$selfRatedProficiencyReading)
sd(english_proficiency_df$selfRatedProficiencyReading)

summary(english_proficiency_df$selfRatedProficiencyUnderstanding)
sd(english_proficiency_df$selfRatedProficiencyUnderstanding)


summary(english_proficiency_df$selfRatedProficiencySpeaking)
sd(english_proficiency_df$selfRatedProficiencySpeaking)

# Contributing factors to learning (Also quoted as Language Entropy in some literature)
contributing_factors_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        friends = ifelse(is.null(eng$q4$friends), NA_integer_, as.integer(substr(eng$q4$friends, 1, 1))),
        family = ifelse(is.null(eng$q4$family), NA_integer_, as.integer(substr(eng$q4$family, 1, 1))),
        reading = ifelse(is.null(eng$q4$reading), NA_integer_, as.integer(substr(eng$q4$reading, 1, 1))),
        self_instructions = ifelse(is.null(eng$q4$self_instructions), NA_integer_, as.integer(substr(eng$q4$self_instructions, 1, 1))),
        tv = ifelse(is.null(eng$q4$tv), NA_integer_, as.integer(substr(eng$q4$tv, 1, 1))),
        radio = ifelse(is.null(eng$q4$radio), NA_integer_, as.integer(substr(eng$q4$radio, 1, 1))),
        education = ifelse(is.null(eng$q4$education), NA_integer_, as.integer(substr(eng$q4$education, 1, 1))),
        internet = ifelse(is.null(eng$q4$internet), NA_integer_, as.integer(substr(eng$q4$internet, 1, 1)))
    ) %>%
    ungroup() %>%
    select(workerid, friends, family, reading, self_instructions, tv, radio, education, internet)

summary(contributing_factors_df$friends)
sd(contributing_factors_df$friends)

summary(contributing_factors_df$family)
sd(contributing_factors_df$family)

summary(contributing_factors_df$reading)
sd(contributing_factors_df$reading)

summary(contributing_factors_df$self_instructions)
sd(contributing_factors_df$self_instructions)

summary(contributing_factors_df$tv)
sd(contributing_factors_df$tv)

summary(contributing_factors_df$radio)
sd(contributing_factors_df$radio)

summary(contributing_factors_df$education)
sd(contributing_factors_df$education)

summary(contributing_factors_df$internet)
sd(contributing_factors_df$internet)

# Factors that one is most exposed to
exposed_factors_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        friends = ifelse(is.null(eng$q5$friends), NA_integer_, as.integer(substr(eng$q5$friends, 1, 1))),
        family = ifelse(is.null(eng$q5$family), NA_integer_, as.integer(substr(eng$q5$family, 1, 1))),
        reading = ifelse(is.null(eng$q5$reading), NA_integer_, as.integer(substr(eng$q5$reading, 1, 1))),
        self_instructions = ifelse(is.null(eng$q5$self_instructions), NA_integer_, as.integer(substr(eng$q5$self_instructions, 1, 1))),
        tv = ifelse(is.null(eng$q5$tv), NA_integer_, as.integer(substr(eng$q5$tv, 1, 1))),
        radio = ifelse(is.null(eng$q5$radio), NA_integer_, as.integer(substr(eng$q5$radio, 1, 1))),
        workplace = ifelse(is.null(eng$q5$workplace), NA_integer_, as.integer(substr(eng$q5$workplace, 1, 1))),
        internet = ifelse(is.null(eng$q5$internet), NA_integer_, as.integer(substr(eng$q5$internet, 1, 1)))
    ) %>%
    ungroup() %>%
    select(workerid, friends, family, reading, self_instructions, tv, radio, workplace, internet)

summary(exposed_factors_df$friends)
sd(exposed_factors_df$friends)

summary(exposed_factors_df$family)
sd(exposed_factors_df$family)

summary(exposed_factors_df$reading)
sd(exposed_factors_df$reading)

summary(exposed_factors_df$self_instructions)
sd(exposed_factors_df$self_instructions)

summary(exposed_factors_df$tv)
sd(exposed_factors_df$tv)

summary(exposed_factors_df$radio)
sd(exposed_factors_df$radio)

summary(exposed_factors_df$workplace)
sd(exposed_factors_df$workplace)

summary(exposed_factors_df$internet)
sd(exposed_factors_df$internet)


# LexTALE Histogram Plot
plot_path <- "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/Plots/lmer"
lexTale_hist <- ggplot(lex_filtered, aes(x = score)) +
    geom_histogram(color = "#575555", fill = "#00bfc4") +
    labs(
        x = "LexTALE Score",
        y = "Frequency",
        title = "LexTALE Distribution Plot"
    ) +
    theme_minimal(base_size = 12) +
    theme(
        plot.title = element_text(hjust = 0.5, size = 10)
    )
ggsave(filename = file.path(plot_path, "lexTale_dist.png"), lexTale_hist, width = 4, height = 4, dpi = 300)


summary(lex_filtered$score)
sd(lex_filtered$score)

# Correlational section between LEAP-Q and LexTALE
# Self Reported proficiency and LexTALE
proficiency_matrix <- english_proficiency_df %>%
    left_join(
        lexTale_performance %>% select(workerid, score),
        by = "workerid"
    ) %>%
    select(-selfRatedProficiencySpeaking) %>%
    rename(
        Reading = selfRatedProficiencyReading,
        Understanding = selfRatedProficiencyUnderstanding,
        LexTALE = score
    )
cor(proficiency_matrix %>% select(-workerid), use = "complete.obs", method = "spearman")


leap_q_df <- leap_q_df %>%
    left_join(
        lexTale_performance,
        by = "workerid"
    )

final_participants <- leap_q_df %>% dplyr::select(workerid, score)
nrow(final_participants)

write.csv(final_participants, "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/final analysis/participants_based_on_proficiency.csv", row.names = FALSE)
