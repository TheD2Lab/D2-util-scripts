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

class Test_Group:
    def __init__(self, group_var: str, group_values: list, sub_dir: str, group_id: str = '') -> None:
        '''
        group_var (str): spss variable used to group data
        group_values (list): values of the groups to include
        sub_dir (str): name of enclosing directory/folder
        group_id (str): name of group to use when saving file
        '''
        self.group_var = group_var
        self.group_values = group_values
        self.sub_dir = sub_dir
        self.group_id = group_id if group_id else group_var

# variables between start_var and end_var in the .sav file will be included
start_var = 'to_AI_Transitions_count'
end_var = 'to_RPM_Proportion_excluding_selftransitions'

# set how output is saved
output_dir = '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/outputs/'
Path(output_dir).mkdir(exist_ok=True)
out_file_suffix = 'PTM'

# set groups to perform tests for
groups = [
    Test_Group(
        group_var='pilot_success',
        group_values=[1,2],
        sub_dir='pilot-success-group/t-tests',
        group_id='pilotSuccess'
    ),
    Test_Group(
        group_var='Instrument_Rating',
        group_values=[0,1],
        sub_dir='instrument-rating-group/t-tests',
        group_id='instrumentRating'
    ),
    Test_Group(
        group_var='Commercial_License',
        group_values=[0,1],
        sub_dir='commercial-license-group',
        group_id='commercialLicense'
    )
]

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
    # ['wholeScreen_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/wholeScreen_Data.sav']
]

# Perform t-tests and highlight p-values
for g in groups:
    Path(output_dir+g.sub_dir).mkdir(parents=True, exist_ok=True)
    for prefix, data_file in data_sets:
        spss.Submit(f"GET FILE = '{data_file}'")
        varDict = f'{prefix}{start_var} to {prefix}{end_var}' #Specify variables to be prefix.
        variables = spssaux.VariableDict().expand(varDict)
        syntax = f"""
            T-TEST GROUPS={g.group_var}({g.group_values[0]} {g.group_values[1]})
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
            
            OUTPUT SAVE OUTFILE = '{output_dir+g.sub_dir}/ttests_{g.group_id}_{prefix}{out_file_suffix}.spv'.
            OUTPUT CLOSE *.
        """
        spss.Submit(syntax)
end program.
