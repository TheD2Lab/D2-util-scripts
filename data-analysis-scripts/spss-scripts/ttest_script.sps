* Encoding: UTF-8.
begin program.
import spss,spssaux
from pathlib import Path

'''
    Performs ttests on multiple sav files with similar structure.
    How to Run:
    1. Open Syntax file in SPSS.
    2. Set start and end variables to specify which data to test.
    3. Set groups to compare (numbers are mapped to values in the sav file. Short string may work as well).
    4. Set output file naming scheme.
    5. Set input files to run test on.
    6. Select/Highlight program in the SPSS viewer and hit run to generate output (.spv) file.

    Note: Make sure your output directory exist
'''

# variables between start_var and end_var in the .sav file will be included
start_var = 'Total_Number_of_Fixations'
end_var = 'average_pupil_size_of_both_eyes'

# Pick the groups to compare
group_var = 'pilot_success'
groups = [1,2]

# Set how output file is saved
out_dir = '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/Variance Tests/Success Group T-tests'
Path(out_dir).mkdir(exist_ok=True)

out_group_id = 'successGroup'
out_file_suffix = 'DGM'

# data files run through. Structure each entry as:
# [Prefix on variable names (leave blank if none), Path to data file]
data_sets = [
    ['AI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/AI_AOI_Data.sav'],
    ['Alt_VSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Alt_VSI_AOI_Data.sav'],
    ['ASI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/ASI_AOI_Data.sav'],
    ['NoAOI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/No_AOI_Data.sav'],
    ['RPM_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/RPM_AOI_Data.sav'],
    ['SSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/SSI_AOI_Data.sav'],
    ['TI_HSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/TI_HSI_AOI_Data.sav'],
    ['Window_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Window_AOI_Data.sav'],
    ['wholeScreen_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/wholeScreen_Data.sav']
]

# Perform t-tests and highligth p-values
for prefix, data_file in data_sets:
    spss.Submit(f"GET FILE = '{data_file}'")
    varDict = f'{prefix}{start_var} to {prefix}{end_var}' #Specify variables to be prefix.
    variables = spssaux.VariableDict().expand(varDict)
    syntax = f"""
        T-TEST GROUPS={group_var}({groups[0]} {groups[1]})
            /MISSING=ANALYSIS
            /VARIABLES= {" ".join(variables)}
            /CRITERIA=CI(.95).
            
        OUTPUT MODIFY
            /REPORT PRINTREPORT=NO
            /SELECT TABLES 
            /IF COMMANDS=["T-Test(1)"] LABELS=[EXACT("Independent Samples Test")] INSTANCES=[1]
            /DELETEOBJECT DELETE=NO
            /OBJECTPROPERTIES   VISIBLE=ASIS
            /TABLECELLS SELECT=["Two-Sided p"] SELECTDIMENSION=COLUMNS SELECTCONDITION="0.015<=x<0.055" 
            BACKGROUNDCOLOR=RGB(251, 248, 115) APPLYTO=CELL
            /TABLECELLS SELECT=["Two-Sided p"] SELECTDIMENSION=COLUMNS SELECTCONDITION="0.0<=x<0.015" 
            BACKGROUNDCOLOR=RGB(112, 220, 132) APPLYTO=CELL.
        
        OUTPUT SAVE OUTFILE = '{out_dir}/ttests_{out_group_id}_{prefix}{out_file_suffix}.spv'.
        OUTPUT CLOSE *.
    """
    spss.Submit(syntax)
end program.
