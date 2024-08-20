import os
from pathlib import Path
import pandas as pd
import csv_utils as cu

class AOI:
   def __init__(self, name: str, x: float, y: float, width: float, height: float):
      """
      Constructs rectangular AOI using the same values used in the GazePoint UI.
      Parameters:
         name (str): name of the AOI
         x (float): x-coordinate of upper left corner of AOI
         y (float): y-coordinate of upper left corner of AOI
         width (float): width of the AOI
         height (float): height of the AOI
      """
      self.name = name
      self.x1 = x
      self.y1 = y
      self.x2 = x + width
      self.y2 = y + height


   def contains(self, x: float, y: float) -> bool:
      """
      Checks if a point is inside the AOI. Left and top bounds
      included. Right and bottom bounds excluded

      Parameters:
         x (float) :
            x-coordinate
         y (float) :
            y-coordinate
      
      Returns:
         whether the point is in the AOI
      """
      if (self.x1 <= x and x < self.x2):
         if (self.y1 <= y and y < self.y2):
            return True
      return False

# The aois to add to the file. All other areas are left blank (i.e., '')
all_aois = [
   AOI('ASI', 0.360, 0.585, 0.060, 0.265),
   AOI('SSI', 0.420, 0.585, 0.125, 0.085),
   AOI('Alt_VSI', 0.545, 0.585, 0.085, 0.275),
   AOI('AI', 0.420, 0.670, 0.125, 0.120),
   AOI('Windshield', 0, 0, 1, 0.430),
   AOI('TI_HSI', 0.420, 0.790, 0.123, 0.200),
   AOI('RPM', 0.875, 0.560, 0.075, 0.125)
]


def add_aoi_to_directory(in_dir: str, out_dir: str, in_pattern: str = "*all_gaze.csv"):
   """
   Tags all files in a directory with new AOIs.
   
   Parameters:
      in_dir (str):
         file path containing original files
      out_dir (str):
         file path to save the new files at
      in_patterns (str):
         optional glob pattern to match file names to
   """
   Path(out_dir).mkdir(parents=True, exist_ok=True)
   in_files = []
   for dir, _, _ in os.walk(in_dir):
      in_files.extend(cu.glob_filter(dir, in_pattern))
   for file in in_files:
      file_name = os.path.basename(file)
      out_file = os.path.join(out_dir, file_name)
      add_aoi_to_file(file, out_file)


def add_aoi_to_file(in_file: str, outfile: str):
   """
   Tags a file with new AOIs.

   Parameters:
      in_file (str):
         file path to the input/starting data
      out_file (str):
         file path to save the tagged data.
   """
   cols: list[str] = pd.read_csv(in_file, nrows=0).columns.tolist()
   data: pd.DataFrame = pd.read_csv(in_file, skiprows=[0])
   data.columns = cols
   tag_data(data)
   data.to_csv(outfile)


def tag_data(data: pd.DataFrame):
   """
   Tags gaze data with new AOIs. Modifies in-place.

   Parameters:
      data (DataFrame):
         gaze data to add AOIs to

   """
   aoi_header = "AOI"
   fpogx = "FPOGX"
   fpogy = "FPOGY"
   bpogx = "BPOGX"
   bpogy = "BPOGY"
   sac_mag = "SACCADE_MAG"
   # we may in the future only want to use fpog but gazepoint uses bpogx to determine the AOI
   # so I do the same for data records. The fixation summary lines will use fpog since that is the value we use
   # in the dgm stuff
   for i in data.index:
      if data.at[i, sac_mag] == 0:  # not fixation;
         data.at[i, aoi_header] = pick_aoi(data.at[i, bpogx], data.at[i, bpogy])
      else: # fixations because saccade mag is not 0
         data.at[i, aoi_header] = pick_aoi(data.at[i, fpogx], data.at[i, fpogy])


def pick_aoi(x: float, y: float) -> str:
   """
   Returns which AOI the point in inside, otherwise returns empty string.
   """
   for area in all_aois:
      if area.contains(x, y): 
         return area.name
   return ''


if __name__ == '__main__':
   # change the path names to the ones on your computer
   add_aoi_to_directory(
      'original_data_folder/',
      'i_want_my_data_here_folder/'
   )
