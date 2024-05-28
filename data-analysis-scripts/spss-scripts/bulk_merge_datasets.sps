* Encoding: UTF-8.
BEGIN PROGRAM PYTHON.
import spss

'''
Merges variables from a sav file into a list of other sav files based on the key/variables.

How to run:
1. Update sav file paths.
2. Select the 'key' to perform merge on.
3. Open program in SPSS and highlight/select all lines in the editor.
4. Press the green/run button.
'''
key = 'PID'

# Variables to add to other files
ADD_VARIABLES_DATA = '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Categorical_Data_Relabel.sav'

MERGE_INTO_SETS = [ # to be merged into
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/AI_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Alt_VSI_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/ASI_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/No_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/RPM_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/SSI_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/TI_HSI_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Window_AOI_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/wholeScreen_Data.sav',
  '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Xplane_Data_Relabel.sav'
]

syntax = f'''
  GET FILE = '{ADD_VARIABLES_DATA}'.
  SORT CASE BY {key}.
  SAVE OUTFILE = '{ADD_VARIABLES_DATA}'.
'''

spss.Submit(syntax)

for i, file in enumerate(MERGE_INTO_SETS):
  syntax = f'''
    GET FILE = '{file}'.
    SORT CASE by {key}.
    SAVE OUTFILE = '{file}'.
    
    MATCH FILES
    /FILE = '{file}'
    /FILE = '{ADD_VARIABLES_DATA}'
    /BY {key}.

    SAVE OUTFILE = '{file}'.
  '''
  spss.Submit(syntax)

END PROGRAM.
