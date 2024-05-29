# D2-util-scripts
Various utility scripts used in the lab

## Contents

**data-analysis-scripts/**: *programs that preform analysis or generate graphs*

- **spss-scripts/**: *SPSS Syntax files*

  - **add_aoi_labels.sps**: *Adds variable labels to AOI data in a sav file*
  - **add_DGM_labels.sps**: *Adds variable labels to whole screen DGM data in a sav file*
  - **anova_script.sps**: *Performs ANOVA tests and automatically generates box plots*
  - **bulk_merge_datasets.sps**: *Merge variables from one file into multiple other files on a primary key*
  - **prefix_variable_name.sps**: *Adds a prefix to variables names in a sav file*
  - **ttest_script.sps**: *Performs t-tests and automatically generates box plots*

- **transition_heatmap.py**: *draws heatmaps of transition data*

**file-scripts/**: *programs that modify files or directories*

- **aggregate_files.py**: *copy files to new directory using pattern matching*
- **csv_utils.py**: *modify/combine contents of csv files using pattern matching*
- **rename_files**: *rename files in directory using pattern matching*
- **Per_AOI_Data_Compiler**: *java software used to compile pilot data with AOI descriptive gaze measures and AOI transition data*

**ils-scripts/**: *programs for the Boeing ILS project*

- **XPlaneNetworkOutput.py**: *communicate with XPlane over network*
- **data_processing_by_daniel**


## Notes:
1. Please keep scripts organized in appropriate folders.
2. Add documentation/descriptions within the scripts for future lab members.