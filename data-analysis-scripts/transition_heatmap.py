import csv
from glob import glob
import os
import numpy as np
import pandas as pd
import seaborn as sns 
import matplotlib.pyplot as plt
from PIL import Image

def parse_transitions(in_csv: str, aois: list[str]) -> pd.DataFrame:
   """
   Parses transition feature results to create tabular data for heat map. 
   Each cell is a the number of transitions that occurred from row AOI to
   column AOI.

   Parameters:
      in_csv (str): path to input csv with transitions
      aois (list[str]): list of AOI names

   Returns:
      transitions organized in a heatmap table
   """
   all_data = pd.read_csv(in_csv, header=0)
   hm_table = pd.DataFrame(index=aois, columns=aois,).infer_objects(copy=False).replace(np.nan, 0)

   for index, row in all_data.iterrows():
      aoi_pair = [aoi.strip() for aoi in row['AOI Pair'].split('->')]
      hm_table.at[aoi_pair[0], aoi_pair[1]] = row['Proportion including self-transitions']
   hm_table=hm_table.round(3)
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


def draw_heatmap(tabular_hm: pd.DataFrame, out_file: str, top_title="heatmap", show=False) -> str:
   figure = sns.heatmap(tabular_hm, cmap='Blues', annot=True, fmt="g")
   plt.rcParams.update({'axes.titlesize':16})
   figure.set_title(top_title, pad=25)
   figure.xaxis.tick_top()
   figure.tick_params(length=0)
   plt.savefig(out_file)
   if show:
      plt.show()
   plt.clf() # clear figure for next run
   return out_file


def draw_directory(in_dir: str, aoi_csv: str, include: str="", exclude: str="", out_dir: str="./"):

   in_files = []

   for dir, a, b in os.walk(in_dir):
         in_files.extend(glob_filter(dir, include, exclude))
   in_files.sort()
   drawings = [] 
   for f in in_files:
      id = os.path.basename(f).split('_')[0]
      title = f"{id} Transition Proportions"
      aois = read_aois_from_file(aoi_csv)  
      df = parse_transitions(f, aois)
      out_file = os.path.join(out_dir, title.replace(" ", "_") + ".png")
      drawings.append(Image.open(draw_heatmap(df, out_file, title)))

   pdf_path = os.path.join(out_dir, "all_heatmaps.pdf")
   drawings[0].save(
      pdf_path, "PDF" ,resolution=100.0, save_all=True, append_images=drawings[1:]
   )


def glob_filter(dir: str, add_pattern: str, remove_pattern: str) -> list[str]:
   """
   Returns list of files in a directory that match a pattern and do not match
   another pattern. Use glob friendly patterns.

   Parameters:
   dir (str): path to directory to search through
   add_pattern (str): filename pattern to include
   remove_pattern (str): filename pattern to exclude

   Returns:
   list[str] list of file paths
   """
   temp_files = glob(os.path.join(dir,add_pattern))
   if remove_pattern: # not an empty string
      temp_files = filter(lambda f: remove_pattern not in f, temp_files)
   return temp_files


def avg_directory(
      in_dir: str,
      aoi_csv: str,
      out_file: str,
      title: str="Average Transitions",
      include: str="",
      exclude: str=""
):
   """
   """
   aois = read_aois_from_file(aoi_csv)

   in_files = []

   for dir,_,_ in os.walk(in_dir):
      in_files.extend(glob_filter(dir, include, exclude))

   hm_table = pd.DataFrame(index=aois, columns=aois).infer_objects(copy=False).replace(np.nan, 0)
   for file in in_files:
      hm_table = hm_table.add(parse_transitions(file, aois))

   hm_table= hm_table.div(len(in_files)).round(3)
   draw_heatmap(hm_table, out_file, title, True)
   
if __name__ == '__main__':
   """
   Update the code here to run new graphs. 
   TODO: support command line arguments
   """
   draw_directory(
      '/Users/ashleyjones/Desktop/approach_gaze_analysis/all/',
      '/Users/ashleyjones/Documents/CSULB/EyeTracking/D2-util-scripts/local/aoi_list.csv',
      "*aoi_transitionFeatures.csv",
      out_dir='./local/'
   )
   avg_directory(
      '/Users/ashleyjones/Desktop/approach_gaze_analysis/all/',
      '/Users/ashleyjones/Documents/CSULB/EyeTracking/D2-util-scripts/local/aoi_list.csv',
      out_file='/Users/ashleyjones/Desktop/approach_gaze_analysis/all/transition_hm.png',
      title='All Pilots Transition Proportions',
      include='*aoi_transitionFeatures.csv'
   )
