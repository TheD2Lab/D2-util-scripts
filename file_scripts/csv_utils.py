from glob import glob
import os
import sys
import pandas as pd

"""
   Generic version of Daniel's csv combining code
"""

def multi_concat(in_files: list[str], out_file: str, add_pid=False):
   """
   Concat a list of csv files

   Parameter:
      in_files (list[str]): csv files to combine
      out_file (str): file to save result
      add_pid (bool): whether to add participant id
   """

   all_data = pd.DataFrame()
   for file in in_files:
      #check if file exists
      if file == out_file:
         continue
      if not os.path.exists(file): 
         continue
      df = pd.read_csv(file)

      # we are assuming file name "pid_*" and has headers 
      if add_pid:
         pid = os.path.basename(file).split('_')[0]
         df.insert(0, "PID", pid, allow_duplicates=False)
      # # 
      # if all_data.empty:
      #    all_data = df
      #else:
      all_data = pd.concat([all_data, df], ignore_index=True)
   if "PID" in all_data.columns:
      all_data= all_data.sort_values(by=['PID'])
   all_data.to_csv(out_file, index=False)
   

def directory_concat(in_dir: str, out_file: str, include: str ='*.csv', exclude: str='', walk: bool=False, add_pid=False):
   """
   Concat all csv files within a director whose filename match a pattern.

   Parameters:
      in_dir (str): directory containing csv files to join
      out_file (str): file to save results
      pattern (str): regular expression to match
      walk (bool): whether to walk through subdirectories
      add_pid (bool): whether to add participant id
   """
   if "csv" not in include:
      print("Provided pattern does not look for csv files")
      return
   
   in_files = []

   if walk: 
      # look through subdirectories
      for dir, _, _ in os.walk(in_dir):
         in_files.extend(glob_filter(dir, include, exclude))
   else:
      in_files.extend(glob_filter(dir, include, exclude))
   
   if in_files: # in_file not empty
      multi_concat(in_files, out_file, add_pid)
   else: # in_file empty
      print(f"No files matched \"{include}")


def glob_filter(dir: str, add_pattern: str, remove_pattern: str = "") -> list[str]:
      temp_files = glob(os.path.join(dir,add_pattern))
      if remove_pattern: # not an empty string
         temp_files = filter(lambda f: remove_pattern not in f, temp_files)
      return temp_files


if __name__ == '__main__':
   """
   Combines/Concatenates csv files.

   Parameters:
      argv[1] directory with csv files to combine
      argv[2] file path to save output
      argv[3] include files that match pattern
      argv[4] exclude files that match pattern
      argv[5] True includes subdirectories
      argv[6] True if pid column needs to added

   """
   if len(sys.argv) < 4:
      print("not enough arguments")
      exit()
   # TODO: implement flags so params can be passed in different order or excluded
   in_dir = sys.argv[1]
   out_file = sys.argv[2]
   include = sys.argv[3] if len(sys.argv) >=3 else ".(.csv)"
   exclude = sys.argv[4] if len(sys.argv) >=4 else ""
   walk = bool(sys.argv[5]) if len(sys.argv) >=5 else False
   add_pid = bool(sys.argv[6]) if len(sys.argv) >=6 else False 
   
   directory_concat(in_dir, out_file, include, exclude, walk, add_pid)