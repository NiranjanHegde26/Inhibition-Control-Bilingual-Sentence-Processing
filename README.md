# Individual Differences of Inhibition Control in Bilingual Sentence Processing: A Self-Paced Reading Approach

This repository contains all code, and data analyses for a Master's thesis investigating how individual differences in inhibition control affect bilingual sentence processing. The thesis title is **_Individual Differences of Inhibition Control in Bilingual Sentence Processing: A Self-Paced Reading Approach_**.

The project combines experimental tasks, comprehension measures, and statistical analyses to explore cognitive mechanisms underlying bilingual language processing.

## Directory Structure

```
.
├── data/            # Experimental and survey data used in the analyses
├── scripts/         # Data processing, anonymization, and analysis scripts
├── implementation/  # Code for implementing the experiments used in the thesis
├── Plots/           # Generated figures and visualizations
├── .gitignore       # Files and folders excluded from version control
├── LICENSE          # License for the repository
└── README.md        # Project overview and documentation
```

## Dependencies

### System Requirements

- R >= 4.4.3
- Tested on Windows 11

### R Packages

All analyses were conducted in R (v4.4.3).
The following R packages (and versions) were used in this project

```
tidyr      (v1.3.1)
dplyr      (v1.1.4)
ggplot2   (v3.5.1)
stringr   (v1.5.1)
ggeffects (v2.3.2)
emmeans   (v1.11.0)
lmerTest  (v3.1.3)
lme4      (v1.1.36)
Hmisc     (v5.2.4)
```

### Installation of R Packages

To install the required packages, run:

```
install.packages(c(
  "tidyr",
  "dplyr",
  "ggplot2",
  "stringr",
  "ggeffects",
  "emmeans",
  "lmerTest",
  "lme4",
  "Hmisc"
))
```

## Code execution

To reproduce the analyses, run the scripts in the following order:

Step 1. Participant exclusion based on proficiency
Run the script that performs participant exclusion based on proficiency criteria:
scripts/proficiency/proficiency_analysis.R

Step 2. Inhibition control composite score calculation
Compute the composite score for inhibition control tasks by executing:
scripts/inhibition_control/compositeScoreCalculation.R

Step 3. SPR comprehension accuracy analysis
Calculate participants’ accuracy on the SPR comprehension task by running:
scripts/spr/comprehension_analysis.Rmd

Step 4. Position P1 analysis
Perform the analysis for Position P1 using:
scripts/spr/final_p1_analysis.Rmd

Step 5. Position P2 analysis
Perform the analysis for Position P2 using:
scripts/spr/final_p2_analysis.Rmd

Step 6. Model diagnostics
Assess model diagnostics by running:
scripts/spr/final_diagnostics.Rmd

Step 7. Outlier analysis
Identify and analyze outliers using:
scripts/spr/outlier_analysis.Rmd

Step 8. Visualization of model effects
Generate visualizations of model effects with:
scripts/spr/final_plots.Rmd

Step 9. Reading time analysis from dataset
Analyse interference cost and translation processing cost from dataset with:
scripts/spr/raw_data_analysis.Rmd

## Experimental Design

The indivdual difference tasks and English language questionnaire and LexTALE are designed using Lingoturk (Pusse et al. , 2016) (https://github.com/FlorianPusse/Lingoturk/wiki). The individual difference tasks used in the thesis are Flanker Squared, Simon Squared and Stroop Squared. These tasks were designed based on the implementation from Liceralde and Burgoyne (2023) (https://github.com/vrtliceralde/squared_jspsych/tree/v1.0.0). LEAP-Q questionnaire can be found here in the MS Word format: (https://bilingualism.soc.northwestern.edu/wp-content/uploads/2015/02/LEAP-Q2007-GERMAN-2008_version2.doc), whereas the LexTALE experimental stimuli was implemented as is from Lemhöfer & Broersma (2012) and can be found here(https://www.lextale.com/downloads/ExperimenterInstructionsEnglish.pdf).

**Note**: Data will be made public soon!

## References

Liceralde, V. R. T., & Burgoyne, A. P. (2023). Squared tasks of attention control for jsPsych (Version 1.0. 0). Computer software, 10.

Lemhöfer, K., & Broersma, M. (2012). Introducing LexTALE: A quick and valid lexical test for advanced learners of English. Behavior research methods, 44(2), 325-343.

Pusse, F., Sayeed, A., & Demberg, V. (2016, June). LingoTurk: managing crowdsourced tasks for psycholinguistics. In Proceedings of the 2016 Conference of the North American Chapter of the Association for Computational Linguistics: Demonstrations (pp. 57-61).
