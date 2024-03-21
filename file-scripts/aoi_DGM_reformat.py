import os
import pandas as pd
import csv_utils as cu

def single_file(csv: str) -> pd.DataFrame:
   participant = os.path.basename(csv).split("_")[0]
   original = pd.read_csv(csv, index_col="AOI", usecols=[
      "Total Number of Fixations",
      "Sum of all fixation duration (s)",
      "Mean fixation duration (s)",
      "Median fixation duration (s)",
      "St.Dev. of fixation durations (s)",
      "Min. fixation duration (s)",
      "Max. fixation duration (s)",
      "total number of saccades",
      "sum of all saccade length",
      "mean saccade length",
      "median saccade length",
      "StDev of saccade lengths",
      "min saccade length",
      "max saccade length",
      "sum of all saccade durations",
      "mean saccade duration",
      "median saccade duration",
      "StDev of saccade durations",
      "Min. saccade duration",
      "Max. saccade duration",
      "scanpath duration",
      "fixation to saccade ratio",
      "Average Peak Saccade Velocity",
      "sum of all absolute degrees",
      "mean absolute degree",
      "median absolute degree",
      "StDev of absolute degrees",
      "min absolute degree",
      "max absolute degree",
      "sum of all relative degrees",
      "mean relative degree",
      "median relative degree",
      "StDev of relative degrees",
      "min relative degree",
      "max relative degree",
      "convex hull area",
      "stationary entropy",
      "transition entropy",
      "Average Blink Rate per Minute",
      "total number of valid recordings",
      "average pupil size of left eye",
      "average pupil size of right eye",
      "average pupil size of both eyes",
      "total number of L mouse clicks",
      "AOI"
   ])
   
   reformat = pd.DataFrame({'PID': participant}, index=[0])

   for ind in original.index:
      for header in original.columns:
         reformat = reformat.join(pd.DataFrame({f'{ind}_{header.replace(" ", "_")}': original[header].loc[ind]}, index=[0]))
   return reformat.reset_index(drop=True)

def run_directory(in_dir: str, out_file: str):
   all_data = None
   in_files = []
   for dir, _, _ in os.walk(in_dir):
      in_files.extend(cu.glob_filter(dir, "*AOI_DGMs.csv"))
   for file in in_files:
      single = single_file(file)
      if (all_data is None): 
         all_data = single
      else:
         all_data = pd.concat([all_data, single])
   all_data.to_csv(out_file)
   
         
if __name__ == "__main__":
   # single_file("/Users/ashleyjones/Desktop/approach_gaze_analysis/all_participants_results/p1/p1_AOI_DGMs.csv")
   run_directory("/Users/ashleyjones/Desktop/approach_gaze_analysis/all_participants_results", "local_outputs/combined_aoi_dgm.csv")


