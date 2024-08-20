import csv
from enum import Enum
from glob import glob
import os
import numpy as np
import pandas as pd
import seaborn as sns 
import matplotlib.pyplot as plt
from PIL import Image
from textwrap import wrap

metric = 'Proportion excluding self-transitions'

class Masks(Enum):
   NONE = 0
   DIAGONAL = 1
   UPPER_TRI = 2
   LOWER_TRI = 3

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
      hm_table.at[aoi_pair[0], aoi_pair[1]] = row[metric]
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


def draw_heatmap(tabular_hm: pd.DataFrame, out_file: str, top_title="heatmap", show: bool=False, apply_mask: Masks=Masks.NONE) -> str:
   mask = np.zeros_like(tabular_hm)
   if apply_mask == Masks.DIAGONAL:
      np.fill_diagonal(mask, 1)
   elif apply_mask == Masks.UPPER_TRI:
      mask = np.triu(np.ones_like(mask))
   elif apply_mask == Masks.LOWER_TRI:
      mask = np.tril(np.ones_like(mask))
   figure = sns.heatmap(tabular_hm, cmap='Blues', annot=True, mask=mask, vmin=0, vmax=.5)
   plt.rcParams.update({'axes.titlesize':16})
   # use commented line if not setting specific title breaks
   # figure.set_title('\n'.join(wrap(top_title,40)), pad=25)
   figure.set_title(top_title, pad=25)
   figure.xaxis.tick_top()
   figure.tick_params(length=0)
   plt.tight_layout()
   plt.savefig(out_file, dpi=300)
   if show:
      plt.show()
   plt.clf() # clear figure for next run
   return out_file


def draw_directory(
      in_dir: str,
      aoi_csv: str,
      out_dir: str="./",
      title: str="Transitions",
      include: str="",
      exclude: str="",
      apply_mask: Masks=Masks.NONE
   ):
   """
   Creates a heatmap for all transition files in a directory.

   Parameters:
   in_dir(str): the directory to read data from
   aoi_csv(str): csv with list of aois
   out_dir(str): directory to save output files to
   title(str): heatmap title
   include(str): filename wild cards to include
   exclude(str): filename wild cards to exclude
   """
   in_files = []

   for dir,_,_ in os.walk(in_dir):
      in_files.extend(glob_filter(dir, include, exclude))

   in_files.sort()
   drawings = [] 
   for f in in_files:
      id = os.path.basename(f).split('_')[0]
      chart_title = f"{id} {title}"
      aois = read_aois_from_file(aoi_csv)  
      df = parse_transitions(f, aois)
      out_file = os.path.join(out_dir, chart_title.replace(" ", "_") + ".png")
      drawings.append(Image.open(draw_heatmap(df, out_file, chart_title, apply_mask=apply_mask)))

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
      exclude: str="",
      apply_mask: Masks=Masks.NONE
):
   """
   Creates a heatmap of averages of transition data from a directory.

   Parameters:
   in_dir(str): the directory to read data from
   aoi_csv(str): csv with list of aois
   out_file(str): were to save the heatmap
   title(str): heatmap title
   include(str): filename wild cards to include
   exclude(str): filename wild cards to exclude
   """
   aois = read_aois_from_file(aoi_csv)

   in_files = []

   for dir,_,_ in os.walk(in_dir):
      in_files.extend(glob_filter(dir, include, exclude))

   hm_table = pd.DataFrame(index=aois, columns=aois).infer_objects(copy=False).replace(np.nan, 0)
   for file in in_files:
      hm_table = hm_table.add(parse_transitions(file, aois))

   hm_table= hm_table.div(len(in_files)).round(2)
   draw_heatmap(hm_table, out_file, title, True, apply_mask)
   

if __name__ == '__main__':
   """
   Update the code here to run new graphs. 
   TODO: support command line arguments or a gui
   """
   avg_directory(
      in_dir='/Users/ashleyjones/Documents/CSULB/EyeTracking/approach_gaze/unsuccessful',
      aoi_csv='/Users/ashleyjones/Documents/CSULB/EyeTracking/D2-util-scripts/local/aoi_list.csv',
      out_file='/Users/ashleyjones/Documents/CSULB/EyeTracking/D2-util-scripts/local/unSuccessful_heatmap_transitions.png',
      title='Unsuccessful Group \nMean Transition Proportions',
      include='*AOI_Transitions.csv',
      apply_mask=Masks.DIAGONAL
   )

   # draw_directory(
   #    in_dir='/Users/ashleyjones/Documents/CSULB/EyeTracking/approach_gaze/results',
   #    aoi_csv='/Users/ashleyjones/Documents/CSULB/EyeTracking/D2-util-scripts/local/aoi_list.csv',
   #    out_dir='/Users/ashleyjones/Documents/CSULB/EyeTracking/D2-util-scripts/local/',
   #    title='Transition Proportions',
   #    include='*AOI_Transitions.csv'
   # )
