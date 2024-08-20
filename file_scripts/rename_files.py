import os
import sys

def replace_substring(filename: str, old_string: str, new_string: str='', dir: str=''):
   """
   Renames a file by replacing a substring

   Parameters:
      filename (str): name of the file to rename
      old_string (str): substring to replace
      new_string (str): replacement string
      dir (str): file path to directory with file

   """
   new_filename = filename.replace(old_string, '')
   # need to rejoin dir name after replace to prevent modifying parent dir name
   os.rename(os.path.join(dir,filename), os.path.join(dir,new_filename))


def multi_remove(dir: str, substring: str):
   """
   Removes a substring from the filename of all files in a directory

   Parameter:
      dir (str): target directory
      substring (str): substring to remove from file names
   """

   for filename in os.listdir(dir):
      replace_substring(filename=filename, old_string=substring, dir=dir)
   print(f'Removed "{substring}" from filenames in {dir}')


if __name__ == '__main__':
   """
   Renames files by removing a substring

   Parameters:
      argv[1] directory with files
      argv[2] substring to remove from filenames
   """
   dir = sys.argv[1]
   substring = sys.argv[2]
   multi_remove(dir, substring)