"
    Author: Niranjana Hegde B S
    Date of Creation: Nov 07, 2025
"
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(ggplot2)
library("jsonlite")

leapq_results_file <- "data/proficiency/experiment_4681_results.csv"
lexTale_results_file <- "data/proficiency/experiment_4621_results(1).csv"
leap_q_df <- read.csv(leapq_results_file)
lexTale_df <- read.csv(lexTale_results_file)
names(lexTale_df)
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
        score = (((correctNonWord / 20) * 100) + ((correctWord / 40) * 100)) / 2 # Formula from LexTALE paper
    )
summary(lexTale_performance$score)

leap_q_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        parsed = list(fromJSON(fromJSON(answer))),
        age = ifelse(is.null(parsed[["age"]]), NA_real_, as.numeric(parsed[["age"]][1])),
        gender = ifelse(is.null(parsed[["gender"]]), NA_character_, parsed[["gender"]][1]),
        motherTongue = ifelse(is.null(parsed[["motherTongue"]]), NA_character_, str_to_lower(parsed[["motherTongue"]][1])),
        engExposure = ifelse(is.null(parsed[["motherTongue"]]), NA_character_, parsed[["motherTongue"]][1]),
        q1 = ifelse(is.null(parsed[["q1"]]), NA, list(parsed[["q1"]])),
        q2 = ifelse(is.null(parsed[["q2"]]), NA, list(parsed[["q2"]])),
        q3 = ifelse(is.null(parsed[["q3"]]), NA, list(parsed[["q3"]])),
        q4 = ifelse(is.null(parsed[["q4"]]), NA, list(parsed[["q4"]])),
        q5 = ifelse(is.null(parsed[["q5"]]), NA, list(parsed[["q5"]])),
        q7 = ifelse(is.null(parsed[["q5"]]), NA, list(parsed[["q7"]])),
        q9 = ifelse(is.null(parsed[["q5"]]), NA, list(parsed[["q9"]])),
        eng = ifelse(is.null(parsed[["eng"]]), NA, list(parsed[["eng"]])),
    ) %>%
    ungroup()
leap_q_df$eng

# Remove all those whose L1 is not German and L2 is not English
# This is applicable for multiple columns but if we do filter them at Q2 (Order of Acquistion), it is taken care at all levels.
leap_q_df <- leap_q_df %>%
    filter(
        !is.na(motherTongue) & !is.na(q2[[1]]) &
            motherTongue %in% c("deutsch", "german", "deutch", "duetsch") &
            str_to_lower(q2[[1]]$l1) %in% c("deutsch", "german", "deutch", "duetsch") &
            str_to_lower(q2[[1]]$l2) %in% c("englisch", "english")
    )

leap_q_df$parsed[[1]]$q3

leap_q_df <- leap_q_df %>%
    mutate(
        q1 = map(q1, \(x) {
            x$l1 <- case_when(
                str_to_lower(x$l1) %in% c("deutsch", "german", "deutch", "duetsch") ~ "German",
                TRUE ~ x$l1
            )
            x$l2 <- case_when(
                str_to_lower(x$l2) %in% c("englisch", "english") ~ "English",
                TRUE ~ x$l2
            )
            x
        }),
        q2 = map(q2, \(x) {
            x$l1 <- case_when(
                str_to_lower(x$l1) %in% c("deutsch", "german", "deutch", "duetsch") ~ "German",
                TRUE ~ x$l1
            )
            x$l2 <- case_when(
                str_to_lower(x$l2) %in% c("englisch", "english") ~ "english",
                TRUE ~ x$l2
            )
            x
        }),
    )

# There are different levels of LEAP-Q questions with different scales.
# Age
age_df <- leap_q_df %>%
    group_by(workerid) %>%
    select(workerid, age)

age_df$age

# Gender
gender_df <- leap_q_df %>%
    group_by(workerid) %>%
    select(workerid, gender)

gender_counts_df <- gender_df %>%
    group_by(gender) %>%
    summarise(count = n())

print(gender_counts_df)

# Mother tongue
mother_tongue_df <- leap_q_df %>%
    group_by(workerid) %>%
    select(workerid, motherTongue)
summary(mother_tongue_df)

# Order of dominant languages
dominant_languages_df <- leap_q_df %>%
    rowwise() %>% # Add this
    mutate(
        l1 = ifelse(is.null(q1) || is.null(q1$l1), NA_character_, q1$l1),
        l2 = ifelse(is.null(q1) || is.null(q1$l2), NA_character_, q1$l2)
    ) %>%
    ungroup() %>% # Add this
    select(workerid, l1, l2)


# Language Exposure
language_exposure_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        l1Exposure = ifelse(is.null(q3) || is.null(q3$l1), NA_integer_, as.integer(q3$l1)),
        l2Exposure = ifelse(is.null(q3) || is.null(q3$l2), NA_integer_, as.integer(q3$l2))
    ) %>%
    ungroup() %>%
    select(workerid, l1Exposure, l2Exposure)

# Reading preferences
reading_preferences_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        l1readingPreference = ifelse(is.null(q4) || is.null(q4$l1), NA_integer_, as.integer(q4$l1)),
        l2readingPreference = ifelse(is.null(q4) || is.null(q4$l2), NA_integer_, as.integer(q4$l2))
    ) %>%
    ungroup() %>%
    select(workerid, l1readingPreference, l2readingPreference)
reading_preferences_df

# Speaking Preferences
speaking_preferences_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        l1speakingPreference = ifelse(is.null(q5) || is.null(q5$l1), NA_integer_, as.integer(q5$l1)),
        l2speakingPreference = ifelse(is.null(q5) || is.null(q5$l2), NA_integer_, as.integer(q5$l2))
    ) %>%
    ungroup() %>%
    select(workerid, l1speakingPreference, l2speakingPreference)
speaking_preferences_df

# Q7 (a) - Formal Education
formal_education_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        years = ifelse(is.null(q7) || is.null(q7$a), NA_integer_, as.integer(q7$a)),
        educationLevel = ifelse(is.null(q7) || is.null(q7$b), NA_character_, q7$b)
    ) %>%
    ungroup() %>%
    select(workerid, years, educationLevel)
formal_education_df

# Disabilities
disabilities_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        disabilities = ifelse(is.null(q9) || is.null(q9$a), NA_character_, paste(q9$a, collapse = ", "))
    ) %>%
    ungroup() %>%
    select(workerid, disabilities)
disabilities_df

# Screen 2 - Dedicated to English Proficiency
english_proficiency_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        AoA = ifelse(is.null(eng$q1$a), NA_integer_, as.integer(eng$q1$a)),
        readingAcquistion = ifelse(is.null(eng$q1$c), NA_integer_, as.integer(eng$q1$c)),
        selfRatedProficiencySpeaking = ifelse(is.null(eng$q3$speaking), NA_integer_, as.integer(substr(eng$q3$speaking, 1, 1))),
        selfRatedProficiencyUnderstanding = ifelse(is.null(eng$q3$understanding), NA_integer_, as.integer(substr(eng$q3$understanding, 1, 1))),
        selfRatedProficiencyReading = ifelse(is.null(eng$q3$reading), NA_integer_, as.integer(substr(eng$q3$reading, 1, 1))),
    ) %>%
    ungroup() %>%
    select(workerid, AoA, readingAcquistion, selfRatedProficiencySpeaking, selfRatedProficiencyUnderstanding, selfRatedProficiencyReading)
english_proficiency_df

# Duration of stay and exposure
duration_of_stay_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        durationOfStayInMonths = if_else(
            is.null(eng) || is.null(eng$q2) || is.null(eng$q2$a),
            NA_integer_,
            as.integer(as.numeric(eng$q2$a$years) * 12 + as.numeric(eng$q2$a$months))
        ),
        durationOfExposureAtSchoolWorkplaceInMonths = if_else(
            is.null(eng) || is.null(eng$q2) || is.null(eng$q2$c),
            NA_integer_,
            as.integer(as.numeric(eng$q2$c$years) * 12 + as.numeric(eng$q2$c$months))
        )
    ) %>%
    ungroup() %>%
    select(workerid, durationOfStayInMonths, durationOfExposureAtSchoolWorkplaceInMonths)
duration_of_stay_df

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


# Analyse the LexTALE data here
lexTale_df$itemNo <- as.numeric(lexTale_df$itemNo)
lexTale_df <- lexTale_df$itemNo[lexTale_df$itemNo > 0, ] # Ignore the dummy items added
lexTale_scores <- lexTale_df %>%
    group_by(workerid) %>%
    summarise()
