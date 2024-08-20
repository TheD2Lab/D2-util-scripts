* Encoding: UTF-8.
begin program.
import spss,spssaux

"""
   Adds labels to variables in the AOI in SPSS sav files.

   How to run the code:
      1. Update the aoi names and file paths.
      2. Open in SPSS.
      3. Select/highlight program.
      4. Click green arrow/run program.
      
   Note: Entropy is not included because the value will always be 0 for an AOI.
   Note: Left Button clicks is not included because the mouse was not used during the ILS study.
   Note: The AOIs are for the ILS Approach Study. Change the code to match the AOIs used in your data.
"""

DATA_SETS = [
  ['AI', 'AI', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/AI_AOI_Data.sav'],
  ['Alt_VSI', 'Alt_VSI', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Alt_VSI_AOI_Data.sav'],
  ['ASI', 'ASI', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/ASI_AOI_Data.sav'],
  ['NoAOI', 'No AOI', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/No_AOI_Data.sav'],
  ['RPM', 'RPM', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/RPM_AOI_Data.sav'],
  ['SSI', 'SSI', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/SSI_AOI_Data.sav'],
  ['TI_HSI', 'TI_HSI', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/TI_HSI_AOI_Data.sav'],
  ['Window', 'Window' ,'/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Window_AOI_Data.sav'],
]
for var_aoi, label_aoi, file in DATA_SETS:
  spss.Submit(f"GET FILE = '{file}'")
  variables = [
    f"{var_aoi}_Total_Number_of_Fixations",
    f"{var_aoi}_sum_of_all_fixation_duration_s",
    f"{var_aoi}_mean_fixation_duration_s",
    f"{var_aoi}_median_fixation_duration_s",
    f"{var_aoi}_stdev_of_fixation_durations_s",
    f"{var_aoi}_min_fixation_duration_s",
    f"{var_aoi}_max_fixation_duration_s",
    f"{var_aoi}_total_number_of_saccades",
    f"{var_aoi}_sum_of_all_saccade_length",
    f"{var_aoi}_mean_saccade_length",
    f"{var_aoi}_median_saccade_length",
    f"{var_aoi}_stdev_of_saccade_lengths",
    f"{var_aoi}_min_saccade_length",
    f"{var_aoi}_max_saccade_length",
    f"{var_aoi}_sum_of_all_saccade_durations",
    f"{var_aoi}_mean_saccade_duration",
    f"{var_aoi}_median_saccade_duration",
    f"{var_aoi}_stdev_of_saccade_durations",
    f"{var_aoi}_min_saccade_duration",
    f"{var_aoi}_max_saccade_duration",
    f"{var_aoi}_scanpath_duration",
    f"{var_aoi}_fixation_to_saccade_ratio",
    f"{var_aoi}_average_peak_saccade_velocity",
    f"{var_aoi}_sum_of_all_absolute_degrees",
    f"{var_aoi}_mean_absolute_degree",
    f"{var_aoi}_median_absolute_degree",
    f"{var_aoi}_stdev_of_absolute_degrees",
    f"{var_aoi}_min_absolute_degree",
    f"{var_aoi}_max_absolute_degree",
    f"{var_aoi}_sum_of_all_relative_degrees",
    f"{var_aoi}_mean_relative_degree",
    f"{var_aoi}_median_relative_degree",
    f"{var_aoi}_stdev_of_relative_degrees",
    f"{var_aoi}_min_relative_degree",
    f"{var_aoi}_max_relative_degree",
    f"{var_aoi}_convex_hull_area",
    f"{var_aoi}_average_blink_rate_per_minute",
    f"{var_aoi}_total_number_of_valid_recordings",
    f"{var_aoi}_average_pupil_size_of_left_eye",
    f"{var_aoi}_average_pupil_size_of_right_eye",
    f"{var_aoi}_average_pupil_size_of_both_eyes",
    f"{var_aoi}_proportion_of_fixations_spent_in_aoi",
    f"{var_aoi}_proportion_of_fixations_durations_spent_in_aoi",
    f"{var_aoi}_to_AI_transitions_count",
    f"{var_aoi}_to_AI_proportion_including_selftransitions",
    f"{var_aoi}_to_AI_proportion_excluding_selftransitions",
    f"{var_aoi}_to_No_AOI_transitions_count",
    f"{var_aoi}_to_No_AOI_proportion_including_selftransitions",
    f"{var_aoi}_to_No_AOI_proportion_excluding_selftransitions",
    f"{var_aoi}_to_Alt_VSI_transitions_count",
    f"{var_aoi}_to_Alt_VSI_proportion_including_selftransitions",
    f"{var_aoi}_to_Alt_VSI_proportion_excluding_selftransitions",
    f"{var_aoi}_to_ASI_transitions_count",
    f"{var_aoi}_to_ASI_proportion_including_selftransitions",
    f"{var_aoi}_to_ASI_proportion_excluding_selftransitions",
    f"{var_aoi}_to_Window_transitions_count",
    f"{var_aoi}_to_Window_proportion_including_selftransitions",
    f"{var_aoi}_to_Window_proportion_excluding_selftransitions",
    f"{var_aoi}_to_SSI_transitions_count",
    f"{var_aoi}_to_SSI_proportion_including_selftransitions",
    f"{var_aoi}_to_SSI_proportion_excluding_selftransitions",
    f"{var_aoi}_to_TI_HSI_transitions_count",
    f"{var_aoi}_to_TI_HSI_proportion_including_selftransitions",
    f"{var_aoi}_to_TI_HSI_proportion_excluding_selftransitions",
    f"{var_aoi}_to_RPM_transitions_count",
    f"{var_aoi}_to_RPM_proportion_including_selftransitions",
    f"{var_aoi}_to_RPM_Proportion_excluding_selftransitions",
  ]

  labels = [
    f"Total Number of Fixations in {label_aoi}",
    f"Sum of All Fixation Durations in {label_aoi} (s)",
    f"Mean Fixation Duration in {label_aoi} (s)",
    f"Median Fixation Duration in {label_aoi} (s)",
    f"Standard Deviation of Fixation Duration in {label_aoi} (s)",
    f"Minimum Fixation Duration in {label_aoi} (s)",
    f"Maximum Fixation Duration in {label_aoi} (s)",
    f"Total Number of Saccades in {label_aoi}",
    f"Sum of All Saccade Lengths in {label_aoi} (pixels)",
    f"Mean Saccade Length in {label_aoi} (pixels)",
    f"Median Saccade Length in {label_aoi} (pixels)",
    f"Standard Deviation of Saccade Length in {label_aoi} (pixels)",
    f"Minimum Saccade Length in {label_aoi} (pixels)",
    f"Maximum Saccade Length in {label_aoi} (pixels)",
    f"Sum of All Saccade Durations in {label_aoi} (s)",
    f"Mean Saccade Duration in {label_aoi} (s)",
    f"Median Saccade Duration in {label_aoi} (s)",
    f"Standard Deviation of Saccade Duration in {label_aoi} (s)",
    f"Minimum Saccade Duration in {label_aoi} (s)",
    f"Maximum Saccade Duration in {label_aoi} (s)",
    f"Scanpath Duration in {label_aoi} (s)",
    f"Fixation to Saccade Ratio in {label_aoi}",
    f"Average Peak Saccade Velocity in {label_aoi} (degrees/s)",
    f"Sum of all Absolute Angles in {label_aoi} (degrees)",
    f"Mean Absolute Angle in {label_aoi} (degrees)",
    f"Median Absolute Angle in {label_aoi} (degrees)",
    f"Standard Deviation of Absolute Angle in {label_aoi} (degrees)",
    f"Minimum Absolute Angle in {label_aoi} (degrees)",
    f"Maximum Absolute Angle in {label_aoi} (degrees)",
    f"Sum of All Relative Angles in {label_aoi} (degrees)",
    f"Mean Relative Angle in {label_aoi} (degrees)",
    f"Median Relative Angle in {label_aoi} (degrees)",
    f"Standard Deviation of Relative Angle in {label_aoi} (degrees)",
    f"Minimum Relative Angle in {label_aoi} (degrees)",
    f"Maximum Relative Angle in {label_aoi} (degrees)",
    f"Convex Hull Area in {label_aoi} (pixels²)",
    f"Average Blink Rate Per Minute in {label_aoi}",
    f"Total Number of Valid Recordings in {label_aoi}",
    f"Average Pupil Size of Left Eye in {label_aoi} (mm)",
    f"Average Pupil Size of Right Eye in {label_aoi} (mm)",
    f"Average Pupil Size of Both Eyes in {label_aoi} (mm)",
    f"Proportion of Fixations Spent in {label_aoi}",
    f"Proportion of Fixation Durations Spent in {label_aoi}",
    f"{label_aoi}→AI Transition Count",
    f"{label_aoi}→AI Transition Proportion Including Self Transitions",
    f"{label_aoi}→AI Transition Proportion Excluding Self Transitions",
    f"{label_aoi}→No AOI Transition Count",
    f"{label_aoi}→No AOI Transition Proportion Including Self Transitions",
    f"{label_aoi}→No AOI Transition Proportion Excluding Self Transitions",
    f"{label_aoi}→Alt_VSI Transition Count",
    f"{label_aoi}→Alt_VSI Transition Proportion Including Self Transitions",
    f"{label_aoi}→Alt_VSI Transition Proportion Excluding Self Transitions",
    f"{label_aoi}→ASI Transition Count",
    f"{label_aoi}→ASI Transition Proportion Including Self Transitions",
    f"{label_aoi}→ASI Transition Proportion Excluding Self Transitions",
    f"{label_aoi}→Window Transition Count",
    f"{label_aoi}→Window Transition Proportion Including Self Transitions",
    f"{label_aoi}→Window Transition Proportion Excluding Self Transitions",
    f"{label_aoi}→SSI Transition Count",
    f"{label_aoi}→SSI Transition Proportion Including Self Transitions",
    f"{label_aoi}→SSI Transition Proportion Excluding Self Transitions",
    f"{label_aoi}→TI_HSI Transition Count",
    f"{label_aoi}→TI_HSI Transition Proportion Including Self Transitions",
    f"{label_aoi}→TI_HSI Transition Proportion Excluding Self Transitions",
    f"{label_aoi}→RPM Transition Count",
    f"{label_aoi}→RPM Transition Proportion Including Self Transitions",
    f"{label_aoi}→RPM Transition Proportion Excluding Self Transitions"
  ]
  for var_name, label in zip(variables, labels):
    syntax = f"""
      VARIABLE LABELS {var_name} '{label}'.
      VARIABLE LEVEL {var_name} (scale).
    """
    spss.Submit(syntax)
  spss.Submit(f"SAVE OUTFILE = '{file}'")

end program.
