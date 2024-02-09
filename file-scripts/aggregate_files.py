from glob import glob
import os
import shutil
import sys

def aggregate_files(in_dir: str, out_dir: str, patterns: list[str]):
   '''
   Copies files that match patterns to another directory

   Parameters:
      in_dir (str): directory with files
      out_dir (str): directory to copy to
      patterns (list[str]): file patterns to match
   
   '''
   files = []
   
   # for each (sub)directory, find all files that match patterns
   for dir, _, _ in os.walk(in_dir):
      for pattern in patterns:
         files.extend(glob(os.path.join(dir,pattern)))
   print(f"{len(files)} files found")

   # copy files to output directory
   os.makedirs(name=out_dir, exist_ok=True)
   for f in files:
      shutil.copy(f, out_dir)
   print(f"Files copied to {out_dir}")


if __name__ == '__main__':
   '''
   Copies files that match patterns to another directory

   Parameters:
      argv[1] input directory
      argv[2] output directory
      argv[3..n] patterns to match
   
   '''
   if len(sys.argv) < 4:
      print("Not enough command line arguments")
      exit()
   input_dir = sys.argv[1]
   output_dir = sys.argv[2]
   file_patterns = sys.argv[3:]

   aggregate_files(input_dir, output_dir, file_patterns)


   
   

