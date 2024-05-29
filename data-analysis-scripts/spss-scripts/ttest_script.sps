* Encoding: UTF-8.
BEGIN PROGRAM PYTHON.
import spss, spssaux, SpssClient
from pathlib import Path

'''
  Performs ttests on multiple sav files with similar structure and generates boxplots.
  How to Run:
  1. Open Syntax file in SPSS.
  2. Set start and end variables to specify which data to test.
  3. Set groups to compare (numbers are mapped to values in the sav file. Short string may work as well).
  4. Set output file naming scheme.
  5. Set input files to run test on.
  6. Select/Highlight program in the SPSS viewer and hit run to generate output (.spv) file.

  Note: Make sure your output directory exist
'''
class TestGroup:
  def __init__(self, group_var: str, group_values: tuple, sub_dir: str, group_id: str = '') -> None:
    '''
    Represents the group parameter for the t-tests.

    Parameters:
      group_var (str): spss variable used to group data
      group_values (tuple): values of the groups to include
      sub_dir (str): name of enclosing directory/folder
      group_id (str): name of group to use when saving file
    '''
    self.group_var = group_var
    self.group_values = group_values
    self.sub_dir = sub_dir
    self.group_id = group_id if group_id else group_var


class VariableInfo:
  def __init__(self, name: str, p_value: float, label: str = ''):
    self.name = name
    self.p_value = p_value
    self.label = label if label else name


# Hardcoded for efficiency. Based on SPSS v29 output
TWO_SIDED_COL = 5
IS_EQUAL_VAR_COL = 3
VAR_COL = 1

# variables between start_var and end_var in the .sav file will be included
START_VAR = 'Total_Number_of_Fixations'
END_VAR = 'average_pupil_size_of_both_eyes'

# set how output is saved
OUTPUT_DIR = '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/outputs/'
Path(OUTPUT_DIR).mkdir(exist_ok=True)
OUTPUT_SUFFIX = 'DGM'

# set number of decimal places on y-axis
DECIMAL_PLACES = 0

# set groups to perform tests for
GROUPS = [
  TestGroup(
    group_var='TLX_Overall_Workload_Binned',
    group_values=(1,2),
    sub_dir='tlx-overall-workload-group',
    group_id='tlxWorkload',
  ),
  TestGroup(
    group_var='pilot_success',
    group_values=(1,2),
    sub_dir='pilot-success-group',
    group_id='pilotSuccess'
  ),
  TestGroup(
    group_var='Instrument_Rating',
    group_values=(0,1),
    sub_dir='instrument-rating-group',
    group_id='instrument'
  ),
  TestGroup(
    group_var='Commercial_License',
    group_values=(0,1),
    sub_dir='commercial-license-group',
    group_id='commercial'
  ),
  TestGroup(
    group_var='Airline_Transport_Pilot',
    group_values=(0,1),
    sub_dir='airline-transport-pilot-group',
    group_id='ATP',
  ),
  TestGroup(
    group_var='Multi_Engine',
    group_values=(0,1),
    sub_dir='multi-engine-rating-group',
    group_id='multiEngine',
  ),
  TestGroup(
    group_var='Complex_Endorsement',
    group_values=(0,1),
    sub_dir='complex-endorsement-group',
    group_id='complex',
  ),
  TestGroup(
    group_var='High_Performance_Endorsement',
    group_values=(0,1),
    sub_dir='high-performance-endorsement-group',
    group_id='highPerformance',
  ),
  TestGroup(
    group_var='CFI',
    group_values=(0,1),
    sub_dir='certified-flight-instructor-group',
    group_id='CFI',
  ),
  TestGroup(
    group_var='CFII',
    group_values=(0,1),
    sub_dir='certified-flight-instrument-instructor-group',
    group_id='CFII',
  ),
  TestGroup(
    group_var='Q7_Regroup',
    group_values=(1,2),
    sub_dir='quiz-question-7',
    group_id='quiz7',
  ),
  TestGroup(
    group_var='Q8_Green_Or_Magenta_num',
    group_values=(1,3),
    sub_dir='quiz-question-8',
    group_id='quiz8',
  ),
]

# data files run through. Structure each entry as:
# [Prefix on variable names (leave blank if none), Path to data file]
DATA_SETS = [
  ['AI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/AI_AOI_Data.sav'],
  ['Alt_VSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Alt_VSI_AOI_Data.sav'],
  ['ASI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/ASI_AOI_Data.sav'],
  ['NoAOI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/No_AOI_Data.sav'],
  ['RPM_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/RPM_AOI_Data.sav'],
  ['SSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/SSI_AOI_Data.sav'],
  ['TI_HSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/TI_HSI_AOI_Data.sav'],
  ['Window_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Window_AOI_Data.sav'],
  ['wholeScreen_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/wholeScreen_Data.sav'],
  # ['', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Xplane_Data.sav'],
  # ['', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Survey_Data.sav'],
]

def run_ttest(group: TestGroup, variables, prefix):
  '''
  Perform t-tests and highlight p-values in pivot table.

  Parameters:
    group (TestGroup)
  '''
  directory = OUTPUT_DIR+group.sub_dir+'/ttests'
  Path(directory).mkdir(parents=True, exist_ok=True)
  syntax = f"""
    T-TEST GROUPS={group.group_var}({group.group_values[0]} {group.group_values[1]})
      /MISSING=ANALYSIS
      /VARIABLES= {" ".join(variables)}
      /CRITERIA=CI(.95).

    OUTPUT MODIFY
      /REPORT PRINTREPORT=NO
      /SELECT TABLES
      /IF COMMANDS=["T-Test(1)"] LABELS=[EXACT("Independent Samples Test")] INSTANCES=[1]
      /DELETEOBJECT DELETE=NO
      /OBJECTPROPERTIES   VISIBLE=ASIS
      /TABLECELLS SELECT = ["Two-Sided p"] SELECTDIMENSION=COLUMNS FORMAT= 'f3.4'
      /TABLECELLS SELECT=["Two-Sided p"] SELECTDIMENSION=COLUMNS SELECTCONDITION="0.01<=x<0.05"
      BACKGROUNDCOLOR=RGB(251, 248, 115) APPLYTO=CELL
      /TABLECELLS SELECT=["Two-Sided p"] SELECTDIMENSION=COLUMNS SELECTCONDITION="0.0<=x<0.01"
      BACKGROUNDCOLOR=RGB(112, 220, 132) APPLYTO=CELL.

    OUTPUT SAVE OUTFILE = '{directory}/ttests_{group.group_id}_{prefix}{OUTPUT_SUFFIX}.spv'.
  """
  spss.Submit(syntax)

def find_significant_vars() -> list[VariableInfo]:
  output_doc = SpssClient.GetDesignatedOutputDoc()
  output_item_list = output_doc.GetOutputItems()

  assume_equal_rows = dict() # key: rows of p-values to look at, value: variable name

  stat_sig = []

  for index in range(output_item_list.Size()):
    output_item = output_item_list.GetItemAt(index)
    if output_item.GetDescription() == 'Independent Samples Test': # get table of interest
      pivot_table = output_item.GetSpecificType()
      pivot_table.SetVarNamesDisplay(SpssClient.VarNamesDisplay.Names) # change labels to var names

      # get rows that contain Equal variance assumed p values
      row_labels = pivot_table.RowLabelArray()
      for i in range(row_labels.GetNumRows()):
        if row_labels.GetValueAt(i,IS_EQUAL_VAR_COL) == 'Equal variances assumed':
          assume_equal_rows[i] = row_labels.GetValueAt(i,VAR_COL)

      data_cells = pivot_table.DataCellArray()
      for row, var in assume_equal_rows.items():
        p_value = float(data_cells.GetValueAt(row, TWO_SIDED_COL))
        if (p_value < 0.05):
          stat_sig.append(VariableInfo(var, p_value))
  
  return stat_sig

def generate_boxplots(variables: list[VariableInfo], group: TestGroup, prefix):
  directory = OUTPUT_DIR+group.sub_dir+'/boxplots'
  Path(directory).mkdir(exist_ok=True)

  # Note: Cannot use spss.Submit inside DataStep, so use two loops

  # Get labels.
  spss.StartDataStep()
  data_set = spss.Dataset()
  group_label = data_set.varlist[group.group_var].label
  for var in variables:
    var.label = data_set.varlist[var.name].label
  spss.EndDataStep()

  ESCAPE_QUOTE = '\\"'

  # graph boxplot
  for var in variables:
    syntax = f"""
      FORMATS {var.name} (f2.{DECIMAL_PLACES}).
      GGRAPH
        /GRAPHDATASET NAME="graphdataset" VARIABLES= {group.group_var} {var.name}
          MISSING=LISTWISE REPORTMISSING=NO
        /GRAPHSPEC SOURCE=INLINE.
      BEGIN GPL
        GUIDE: axis(dim(1), label("{group_label.replace('"', ESCAPE_QUOTE)} (p<{"0.01" if var.p_value<0.01 else "0.05"})"))
        GUIDE: axis(dim(2), label("{var.label}"))
        SCALE: cat(dim(1), include("{str(group.group_values[0])}", "{str(group.group_values[1])}"))
        SCALE: linear(dim(2), include(0))
        ELEMENT: schema(position(bin.quantile.letter({group.group_var}*{var.name})))
      END GPL.
    """
    spss.Submit(syntax)
  
  syntax = f"""
    OUTPUT SAVE OUTFILE = '{directory}/boxplots_{group.group_id}_{prefix}{OUTPUT_SUFFIX}.spv'.
  """
  spss.Submit(syntax)


# start SPSS communication
SpssClient.StartClient()

for i, [prefix, data_file] in enumerate(DATA_SETS):

  if i > 0: # close the previous dataset
    spss.Submit(f"DATASET CLOSE copy{i-1}")

  # open the dataset and make a copy to protect it
  syntax = f"""
    GET FILE = '{data_file}'.
    DATASET NAME original{i}.
    DATASET COPY copy{i}.
    DATASET ACTIVATE copy{i}.
    DATASET CLOSE original{i}.
  """
  spss.Submit(syntax)  # Open the sav (data) file
  var_range = f'{prefix}{START_VAR} to {prefix}{END_VAR}' # Specify range of variables to tests.
  variables = spssaux.VariableDict().expand(var_range) # get a list of variables test

  for g in GROUPS:
    run_ttest(group=g, variables=variables, prefix=prefix)

    sig_list = find_significant_vars()  # get the statistically sig variables

    spss.Submit('OUTPUT CLOSE *.')  # close the t-test output file

    if len(sig_list) > 0:
      generate_boxplots(sig_list, g, prefix)
      spss.Submit('OUTPUT CLOSE *.')  # close the boxplot output file

# End SPSS Communication
SpssClient.StopClient()

END PROGRAM.