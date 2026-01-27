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

leapq_results_file <- "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\data\\proficiency\\LEAP-Q_Final.csv"
lexTale_results_file <- "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\data\\proficiency\\LexTALE-Final.csv"

leap_q_df <- read.csv(leapq_results_file)
lexTale_df <- read.csv(lexTale_results_file)
unique(lexTale_df$workerid)
unique(leap_q_df$workerid)

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
hist(lexTale_performance$score)
nrow(lexTale_performance)

leap_q_df <- leap_q_df %>%
    filter(workerid %in% lexTale_performance$workerid)

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
leap_q_df$motherTongue

calculate_months <- function(x) {
    if (is.null(x$year) || is.null(x$month)) {
        return(0)
    }
    if (is.na(x$year) && is.na(x$month)) {
        return(0)
    }
    return(as.integer(x$year * 12 + x$month))
}


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

nrow(leap_q_df)
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

# English Reading preferences
reading_preferences_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        english_reading_preference = if (is.null(q4[[eng_index]])) NA_integer_ else as.integer(q4[[eng_index]])
    ) %>%
    ungroup() %>%
    select(workerid, english_reading_preference)
summary(reading_preferences_df$english_reading_preference)

# Speaking Preferences
speaking_preferences_df <- leap_q_df %>%
    rowwise() %>%
    mutate(
        english_speaking_preference = if (is.null(q5[[eng_index]])) NA_integer_ else as.integer(q5[[eng_index]])
    ) %>%
    ungroup() %>%
    select(workerid, english_speaking_preference)
summary(speaking_preferences_df$english_speaking_preference)

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

people_with_low_reported_proficiency <- english_proficiency_df %>%
    filter(
        selfRatedProficiencyUnderstanding < 4 & selfRatedProficiencyReading < 4
    ) %>%
    left_join(
        lexTale_performance %>% select(workerid, score),
        by = "workerid"
    ) %>%
    select(workerid, score, selfRatedProficiencyUnderstanding, selfRatedProficiencyReading)
people_with_low_reported_proficiency # These people who rated low in ratings have a C1 or C2 level proficiency as per Lemhöfer & Broersma, 2012. So I don't think I need to remove them


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
summary(contributing_factors_df$family)
summary(contributing_factors_df$friends)
summary(contributing_factors_df$reading)
summary(contributing_factors_df$self_instructions)
summary(contributing_factors_df$tv)
summary(contributing_factors_df$radio)
summary(contributing_factors_df$education)
summary(contributing_factors_df$internet)

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
summary(exposed_factors_df$family)
summary(exposed_factors_df$friends)
summary(exposed_factors_df$reading)
summary(exposed_factors_df$self_instructions)
summary(exposed_factors_df$tv)
summary(exposed_factors_df$radio)
summary(exposed_factors_df$workplace)
summary(exposed_factors_df$internet)

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

library(ggplot2)

ggplot(proficiency_matrix, aes(Reading, LexTALE)) +
    geom_jitter(width = 0.2, height = 0) +
    geom_smooth(method = "lm", se = FALSE) +
    theme_minimal()

ggplot(proficiency_matrix, aes(Understanding, LexTALE)) +
    geom_jitter(width = 0.2, height = 0) +
    geom_smooth(method = "lm", se = FALSE) +
    theme_minimal()

pairs(proficiency_matrix %>%
    select(Reading, Understanding, LexTALE))


proficiency_matrix %>%
    arrange(Reading) %>%
    select(Reading, LexTALE) %>%
    head(10)

proficiency_matrix %>%
    arrange(desc(Reading)) %>%
    select(Reading, LexTALE) %>%
    head(10)

install.packages("ppcor")
library(ppcor)

pcor.test(proficiency_matrix$Reading,
    proficiency_matrix$LexTALE,
    proficiency_matrix$Understanding,
    method = "spearman"
)
cor(proficiency_matrix$Reading,
    proficiency_matrix$Understanding,
    method = "spearman",
    use = "complete.obs"
)



cor_with_score <- proficiency_matrix %>%
    select(-score) %>%
    summarise(across(everything(), ~ cor(.x, proficiency_matrix$score, use = "complete.obs", method = "spearman")))
cor_with_score

# Correlation between scores and exposure duration
proficiency_matrix_with_exposure <- proficiency_matrix %>%
    left_join(
        duration_of_stay_df,
        by = "workerid"
    ) %>%
    rename(
        "Stay in English Speaking Country" = durationOfStayInMonths,
        Exposure = durationOfExposureAtSchoolWorkplaceInMonths,
        LexTALE = score,
        "Reading Acquistion" = readingAcquistion,
    )

cor(proficiency_matrix_with_exposure %>% select(-workerid), use = "complete.obs", method = "spearman")
colnames(leap_q_df)

leap_q_df <- leap_q_df %>%
    left_join(
        lexTale_performance,
        by = "workerid"
    )

final_participants <- leap_q_df %>% dplyr::select(workerid, score)

write.csv(final_participants, "D:/Studies/Thesis/Analysis/Inhibition-Control-Bilingual-Sentence-Processing/data/final analysis/participants_based_on_proficiency_full.csv", row.names = FALSE)
