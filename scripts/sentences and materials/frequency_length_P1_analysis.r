# ============================================================
# Title:    Word Frequency and Length Analysis Script
# Project:  Individual Differences of Inhibition Control in Bilingual Sentence Processing: A Self Paced Reading Approach
# OSF:      https://osf.io/uyvxw
# Author:   Niranjana Hegde Bhimanakone Satyanarayana
# Created:  13/10/2025
# R version: 4.3.2
#
# Description:
# This script obtains the raw frequencies of all words from Position P1
# from SUBTLEX-US and (SUBTLEX-DE for German word frequency if the word
# is interlingual homograph) and converts it into log10 form.
# Additionally, the distances of each word is also calculated for
# descriptive statistics. They are later analysed using pairwise t-tests.
#
#
# Note:
# SUBTLEX-US Excel file and Rmd script can be downloaded from: https://www.ugent.be/pp/experimentele-psychologie/en/research/documents/subtlexus
# SUBTLEX-DE can be downloaded from: https://osf.io/py9ba/files/y6ebr
# ============================================================

# Load libraries
library(dplyr)
library(tidyr)
library(coin)
subtlex_us_file <- "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\materials\\SUBTLEXus.Rdata"
subtlex_de_file <- "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\materials\\subtlex_de_cleaned.csv"
items_file <- "D:\\Studies\\Thesis\\Analysis\\Inhibition-Control-Bilingual-Sentence-Processing\\materials\\itemsWithDistances.csv"
load(subtlex_us_file)
subtlex_de_data <- read.csv(subtlex_de_file)
items_df <- read.csv(items_file)

# Calculate German log frequency for interlingual homographs only
matchesDE <- match(toupper(items_df$GermanWord), toupper(subtlex_de_data$Word))
items_df$FreqDE <- subtlex_de_data$CUMfreqcount[matchesDE]
items_df$LogFreqDE <- log10(items_df$FreqDE) + 1

# Calculate US English Frequency for both interlingual homograph and its control word.
matchesUS <- match(toupper(items_df$EnglishWord), toupper(subtlexus$Word))
matchesC1 <- match(toupper(items_df$C1), toupper(subtlexus$Word))

items_df$FreqUS <- subtlexus$FREQlow[matchesUS]
items_df$FreqC1 <- subtlexus$FREQlow[matchesC1]
items_df$LogFreqUS <- log10(items_df$FreqUS) + 1
items_df$LogFreqC1 <- log10(items_df$FreqC1) + 1

summary(items_df$LogFreqUS)
sd(items_df$LogFreqUS)

summary(items_df$LogFreqDE)
sd(items_df$LogFreqDE)

summary(items_df$LogFreqC1)
sd(items_df$LogFreqC1)

items_df$IHLength <- nchar(items_df$EnglishWord)
items_df$C1Length <- nchar(items_df$C1)

summary(items_df$IHLength)
sd(items_df$IHLength)

summary(items_df$C1Length)
sd(items_df$C1Length)

# Compare the lengths of IH and C1
shapiro.test(items_df$IHLength) # p < .05 - Not normal
shapiro.test(items_df$C1Length) # p < .05 - Not normal

items_df$ItemID <- as.factor(items_df$ItemID)
items_df_restructured <- items_df %>%
    select(ItemID, IHLength, C1Length) %>%
    pivot_longer(
        cols = c(IHLength, C1Length),
        names_to = "Condition",
        values_to = "Length"
    )

# Verify the differnce of means of length of IH and C1 groups.
items_df_restructured$Condition <- as.factor(items_df_restructured$Condition)
wilcoxsign_test(
    Length ~ Condition | ItemID,
    data = items_df_restructured,
    distribution = "exact"
)

# Compare the frequencies of IH and C1
shapiro.test(items_df$LogFreqUS) # p > .05 - Normal
shapiro.test(items_df$LogFreqC1) # p > .05 - Normal

# Use the paired t-test to verify the differnce of means of English log frequencies of IH and C1 groups.
t.test(items_df$LogFreqC1, items_df$LogFreqUS, paired = TRUE)

# Summary of distance metrics
summary(items_df$Orthographic.Distance.Normalised)
sd(items_df$Orthographic.Distance.Normalised)

summary(items_df$Phonetic.Distance.Normalised)
sd(items_df$Phonetic.Distance.Normalised)

# Write back to csv
write.csv(items_df, file = items_file, row.names = FALSE)
