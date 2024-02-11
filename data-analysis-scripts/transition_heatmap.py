import csv
from glob import glob
import os
import pandas as pd
import seaborn as sns 
import matplotlib.pyplot as plt

def parse_transitions(in_csv: str, aois: list[str]) -> pd.DataFrame:
   """
   Parses transition feature results to create tabular data for heat map. 
   Each cell is a the number of transitions that occurred from row AOI to
   column AOI.

   Parameters:
      in_csv (str): path to input csv with transitions
      aois (list[str]): list of AOI names
   """
   all_data = pd.read_csv(in_csv, header=0)
   hm_table = pd.DataFrame(index=aois, columns=aois).fillna(0)

   for index, row in all_data.iterrows():
      aoi_pair = [aoi.strip() for aoi in row['AOI Pair'].split('->')]
      hm_table.at[aoi_pair[0], aoi_pair[1]] = row['Transition Count']

   return hm_table


def read_aois_from_file(in_file: str) -> list[str]:
   """
   Reads the AOIs from a single line csv.

   Parameters:
      in_file (str): path to csv containing AOIs

   Returns:
      list[str]: list of AOIs
   """

   with open(in_file, 'r') as csv_file:
      csv_reader = csv.reader(csv_file)
      return next(csv_reader)
   

def draw_heatmap(tabular_hm: pd.DataFrame, out_dir: str, top_title="heatmap", show=False):
   figure = sns.heatmap(tabular_hm, cmap='Blues', annot=True, fmt="g")
   figure.set(title=top_title)
   save_file = os.path.join(out_dir, top_title.replace(" ", "_") + ".png")
   print(save_file)
   plt.savefig(save_file)
   if show:
      plt.show()
   plt.clf() # clear figure for next run


def draw_directory(in_dir: str, aoi_csv: str, include: str="", exclude: str="", out_dir: str="./"):

   def glob_filter(dir: str, add_pattern: str, remove_pattern: str) -> list[str]:
      temp_files = glob(os.path.join(dir,add_pattern))
      if exclude: # not an empty string
         temp_files = filter(lambda f: remove_pattern not in f, temp_files)
      return temp_files
   in_files = []

   for dir, a, b in os.walk(in_dir):
         in_files.extend(glob_filter(dir, include, exclude))

   for f in in_files:
      id = os.path.basename(f).split('_')[0]
      title = f"{id} Transitions"
      aois = read_aois_from_file(aoi_csv)
      df = parse_transitions(f, aois)
      draw_heatmap(df, out_dir, title)


if __name__ == '__main__':
   draw_directory(
      '/Users/ashleyjones/Desktop/approach_gaze_analysis',
      '/Users/ashleyjones/Documents/CSULB/EyeTracking/D2-util-scripts/local/aoi_list.csv',
      "*aoi_transitionFeatures.csv"
   )
