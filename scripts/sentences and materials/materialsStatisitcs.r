"
    Author: Niranjana Hegde B S
    Date of Creation: Nov 02, 2025
    This script goes through the materials and reports the basic descriptive statistics with regards to:
        - Sentence length
        - P1 word length
        - P2 word length
        - Phrase length before P1
        - Phrase length between P1 and P2 (reported as the lag)
        - Phrase length after P2
        - Difference beween P1-before-phrase and P2-after-phrase lengths
"
library(dpylr)
library(ggplot2)

materials_file <- "materials/List1.csv" # File containing all the sentences from all possible lists
materials_df <- read.csv(materials_file)
critical_items_df <- materials_df[materials_df$Type != "Filler", ]
fillers_df <- materials_df[materials_df$Type == "Filler", ]

# Sentence length
# critical_items_df$Sentence <- as.character(critical_items_df$Sentence)
critical_items_df$SentenceLength <- str_count(critical_items_df$Sentence, "\\S+")
summary(critical_items_df$SentenceLength)
sd(critical_items_df$SentenceLength)

fillers_df$SentenceLength <- str_count(fillers_df$Sentence, "\\S+")
summary(fillers_df$SentenceLength)
sd(fillers_df$SentenceLength)

# P1 word length
critical_items_df$P1 <- as.character(critical_items_df$P1)
critical_items_df$P1Length <- nchar(critical_items_df$P1)
summary(critical_items_df$P1Length)
sd(critical_items_df$P1Length)

# P2 word length
critical_items_df$P2 <- as.character(critical_items_df$P2)
critical_items_df$P2Length <- nchar(critical_items_df$P2)
summary(critical_items_df$P2Length)
sd(critical_items_df$P2Length)

# Phrase length before P1
critical_items_df$Critical.Position.Index <- as.numeric(critical_items_df$Critical.Position.Index)
critical_items_df$P1BeforePhraseLength <- critical_items_df$Critical.Position.Index - 1
summary(critical_items_df$P1BeforePhraseLength)
sd(critical_items_df$P1BeforePhraseLength)

# Phrase length after P2
critical_items_df$Post.Critical.Position.Index <- as.numeric(critical_items_df$Post.Critical.Position.Index)
critical_items_df$P2AfterPhraseLength <- critical_items_df$SentenceLength - critical_items_df$Post.Critical.Position.Index
summary(critical_items_df$P2AfterPhraseLength)
sd(critical_items_df$P2AfterPhraseLength)

# Lag between P1 and P2
critical_items_df$LagLength <- critical_items_df$Post.Critical.Position.Index - critical_items_df$Critical.Position.Index
summary(critical_items_df$LagLength)
sd(critical_items_df$LagLength)

print(critical_items_df[critical_items_df$LagLength > 6, ])

# Difference beween P1-before-phrase and P2-after-phrase lengths
critical_items_df$PhraseDiff <- critical_items_df$P2AfterPhraseLength - critical_items_df$P1BeforePhraseLength
summary(critical_items_df$PhraseDiff)
