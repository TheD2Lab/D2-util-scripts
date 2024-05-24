* Encoding: UTF-8.
begin program.
import spss,spssaux

"""
   Adds labels to whole screen DGM variables in SPSS sav files.
   Use the Add_AOI_Labels.sps if working with AOI data.

   How to run the code:
      1. Open syntax file and target sav file in SPSS.
      2. Update prefix variable.
      3. Select/highlight program.
      4. Click green arrow/run program.
      
   Note: Left Button clicks is not included because the mouse was not used during the ILS study.
"""

prefix ='wholeScreen_' # prefix. Use empty string if no prefix.
variables = [
   f"{prefix}Total_Number_of_Fixations",
   f"{prefix}sum_of_all_fixation_duration_s",
   f"{prefix}mean_fixation_duration_s",
   f"{prefix}median_fixation_duration_s",
   f"{prefix}st.dev._of_fixation_durations_s",
   f"{prefix}min._fixation_duration_s",
   f"{prefix}max._fixation_duration_s",
   f"{prefix}total_number_of_saccades",
   f"{prefix}sum_of_all_saccade_length",
   f"{prefix}mean_saccade_length",
   f"{prefix}median_saccade_length",
   f"{prefix}stdev_of_saccade_lengths",
   f"{prefix}min_saccade_length",
   f"{prefix}max_saccade_length",
   f"{prefix}sum_of_all_saccade_durations",
   f"{prefix}mean_saccade_duration",
   f"{prefix}median_saccade_duration",
   f"{prefix}stdev_of_saccade_durations",
   f"{prefix}min._saccade_duration",
   f"{prefix}max._saccade_duration",
   f"{prefix}scanpath_duration",
   f"{prefix}fixation_to_saccade_ratio",
   f"{prefix}average_peak_saccade_velocity",
   f"{prefix}sum_of_all_absolute_degrees",
   f"{prefix}mean_absolute_degree",
   f"{prefix}median_absolute_degree",
   f"{prefix}stdev_of_absolute_degrees",
   f"{prefix}min_absolute_degree",
   f"{prefix}max_absolute_degree",
   f"{prefix}sum_of_all_relative_degrees",
   f"{prefix}mean_relative_degree",
   f"{prefix}median_relative_degree",
   f"{prefix}stdev_of_relative_degrees",
   f"{prefix}min_relative_degree",
   f"{prefix}max_relative_degree",
   f"{prefix}convex_hull_area",
   f"{prefix}stationary_entropy",
   f"{prefix}transition_entropy",
   f"{prefix}average_blink_rate_per_minute",
   f"{prefix}total_number_of_valid_recordings",
   f"{prefix}average_pupil_size_of_left_eye",
   f"{prefix}average_pupil_size_of_right_eye",
   f"{prefix}average_pupil_size_of_both_eyes",
]

labels = [
   f"Total Number of Fixations",
   f"Sum of All Fixation Durations (s)",
   f"Mean Fixation Duration (s)",
   f"Median Fixation Duration (s)",
   f"Standard Deviation of Fixation Duration (s)",
   f"Minimum Fixation Duration (s)",
   f"Maximum Fixation Duration (s)",
   f"Total Number of Saccades",
   f"Sum of All Saccade Lengths (pixels)",
   f"Mean Saccade Length (pixels)",
   f"Median Saccade Length (pixels)",
   f"Standard Deviation of Saccade Length (pixels)",
   f"Minimum Saccade Length (pixels)",
   f"Maximum Saccade Length (pixels)",
   f"Sum of All Saccade Durations (s)",
   f"Mean Saccade Duration (s)",
   f"Median Saccade Duration (s)",
   f"Standard Deviation of Saccade Duration (s)",
   f"Minimum Saccade Duration (s)",
   f"Maximum Saccade Duration (s)",
   f"Scanpath Duration (s)",
   f"Fixation to Saccade Ratio",
   f"Average Peak Saccade Velocity (degrees/s)",
   f"Sum of all Absolute Angles (degrees)",
   f"Mean Absolute Angle (degrees)",
   f"Median Absolute Angle (degrees)",
   f"Standard Deviation of Absolute Angle (degrees)",
   f"Minimum Absolute Angle (degrees)",
   f"Maximum Absolute Angle (degrees)",
   f"Sum of All Relative Angles (degrees)",
   f"Mean Relative Angle (degrees)",
   f"Median Relative Angle (degrees)",
   f"Standard Deviation of Relative Angle (degrees)",
   f"Minimum Relative Angle (degrees)",
   f"Maximum Relative Angle (degrees)",
   f"Convex Hull Area (pixels²)",
   f"Stationary Entropy",
   f"Transition Entropy",
   f"Average Blink Rate Per Minute",
   f"Total Number of Valid Recordings",
   f"Average Pupil Size of Left Eye (mm)",
   f"Average Pupil Size of Right Eye (mm)",
   f"Average Pupil Size of Both Eyes (mm)",
]
for varname, label in zip(variables, labels):
   spss.Submit("VARIABLE LABELS " + varname + " '" + label + "'")

end program.