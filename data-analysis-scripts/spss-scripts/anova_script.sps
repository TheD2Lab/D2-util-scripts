* Encoding: UTF-8.
BEGIN PROGRAM PYTHON.
import spss, spssaux, SpssClient
from pathlib import Path

'''
  Performs ANOVA tests on multiple sav files with similar structures and generates boxplots.
  How to Run:
  1. Open Syntax file in SPSS.
  2. Set start and end variables to specify which data to test.
  3. Set factors/variables to test.
  4. Set output file naming scheme.
  5. Set input files to run tests on.
  6. Set the template file (.sgt) to define box plot styles.
  7. Select/Highlight program in the SPSS viewer and hit run to generate output (.spv) file.

  Note: Make sure your base output directory exist
'''
class TestFactor:
  def __init__(self, var_name: str, sub_dir: str, factor_id: str = '') -> None:
    '''
    Represents the factor parameter for the ANOVA tests.

    Parameters:
      var_name (str): spss variable used to group data
      sub_dir (str): name of enclosing directory/folder
      factor_id (str): name of factor to use when saving file
    '''
    self.var_name = var_name
    self.sub_dir = sub_dir
    self.factor_id = factor_id if factor_id else var_name


class VariableInfo:
  def __init__(self, name: str, p_value: float, label: str = ''):
    self.name = name
    self.p_value = p_value
    self.label = label if label else name


# Hardcoded for efficiency. Based on SPSS v29 output
SIG_COL = 4
BETWEEN_GROUPS_COL = 3
VAR_COL = 1

# variables between start_var and end_var in the .sav file will be included
START_VAR = 'Approach_Score'
END_VAR = 'MAX_ILS_ABS_Bank_Angle'


# set how output is saved
OUTPUT_DIR = '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/population-comparison/'
Path(OUTPUT_DIR).mkdir(exist_ok=True)
OUTPUT_SUFFIX = 'xplane'

# Graph template file to use (can set scales, colors, etc)
TEMPLATE_FILE = '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/Graph_Templates/no_decimal_axis.sgt'

# set groups to perform tests for
FACTORS = [
  TestFactor(
    var_name='Expertise_Category',
    sub_dir='instrument-and-currency-factor',
    factor_id='instrumentCurrency',
  ),
  TestFactor(
    var_name='FAA_Sim_Hours_num',
    sub_dir='faa-sim-hours-factor',
    factor_id='faaSim'
  ),
  TestFactor(
    var_name='Home_Sim_Regroup',
    sub_dir='home-simulator-usage-factor',
    factor_id='homeSim',
  ),
  TestFactor(
    var_name='Video_Game_Regroup',
    sub_dir='video-game-usage-factor',
    factor_id='videoGame'
  ),
  TestFactor(
    var_name='Sleepiness_Change',
    sub_dir='sleepiness-change-factor',
    factor_id='sleepChange'
  ),
  TestFactor(
    var_name='Q3_Glidespeed_num',
    sub_dir='quiz-question-3-factor',
    factor_id='quiz3'
  ),
  TestFactor(
    var_name='Q9_Regroup',
    sub_dir='quiz-question-9-factor',
    factor_id='quiz9'
  ),
  TestFactor(
    var_name='Q10_Regroup',
    sub_dir='quiz-question-10-factor',
    factor_id='quiz10'
  )
]

# data files run through. Structure each entry as:
# [Prefix on variable names (leave blank if none), Path to data file]
DATA_SETS = [
  # ['AI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/AI_AOI_Data.sav'],
  # ['Alt_VSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Alt_VSI_AOI_Data.sav'],
  # ['ASI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/ASI_AOI_Data.sav'],
  # ['NoAOI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/No_AOI_Data.sav'],
  # ['RPM_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/RPM_AOI_Data.sav'],
  # ['SSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/SSI_AOI_Data.sav'],
  # ['TI_HSI_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/TI_HSI_AOI_Data.sav'],
  # ['Window_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Window_AOI_Data.sav'],
  # ['wholeScreen_', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/wholeScreen_Data.sav'],
  ['', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Xplane_Data.sav'],
  # ['', '/Users/ashleyjones/Documents/CSULB/EyeTracking/Statistics/SAV Data Files/Survey_Data.sav']
]

def run_anova(factor: TestFactor, variables, prefix):
  '''
  Perform ANOVA and highlight p-values in pivot table.

  Parameters:
    factor (TestFactor): grouping variables/factor
    variables (variables): expanded variables to test
  '''
  directory = OUTPUT_DIR+'/'+factor.sub_dir+'/anova'
  Path(directory).mkdir(parents=True, exist_ok=True)
  syntax = f"""
    ONEWAY {" ".join(variables)}
      BY {factor.var_name}
      /ES=OVERALL
      /STATISTICS DESCRIPTIVES 
      /MISSING ANALYSIS
      /CRITERIA=CILEVEL(0.95)
      /POSTHOC=TUKEY ALPHA(0.05).
          
    OUTPUT MODIFY
      /SELECT TABLES
      /IF COMMANDS = ['Oneway'] SUBTYPES = ['ANOVA']
      /TABLECELLS SELECT=["Sig."] SELECTDIMENSION=COLUMNS SELECTCONDITION="0.01<=x<0.05" 
      BACKGROUNDCOLOR=RGB(251, 248, 115) APPLYTO=CELL
      /TABLECELLS SELECT=["Sig."] SELECTDIMENSION=COLUMNS SELECTCONDITION="0.0<=x<0.01" 
      BACKGROUNDCOLOR=RGB(112, 220, 132) APPLYTO=CELL.
        
    OUTPUT SAVE OUTFILE = '{directory}/anova_{factor.factor_id}_{prefix}{OUTPUT_SUFFIX}.spv'.
  """
  spss.Submit(syntax)

def find_significant_vars() -> list[VariableInfo]:
  output_doc = SpssClient.GetDesignatedOutputDoc()
  output_item_list = output_doc.GetOutputItems()
  between_groups_rows = dict()
  stat_sig = []

  for index in range(output_item_list.Size()):
    output_item = output_item_list.GetItemAt(index)
    if output_item.GetDescription() == 'ANOVA': # get table of interest
      pivot_table = output_item.GetSpecificType()
      pivot_table.SetVarNamesDisplay(SpssClient.VarNamesDisplay.Names) # change labels to var names

      # get rows that contain Between Groups p-value
      row_labels = pivot_table.RowLabelArray()
      for i in range(row_labels.GetNumRows()):
        if row_labels.GetValueAt(i, BETWEEN_GROUPS_COL) == 'Between Groups':
          between_groups_rows[i] = row_labels.GetValueAt(i,VAR_COL)

      # get the variables that have p<0.05
      data_cells = pivot_table.DataCellArray()
      for row, var in between_groups_rows.items():
        raw_value = data_cells.GetValueAt(row, SIG_COL)
        try:
          p_value = float(raw_value)
        except: # raw = '<0.001' occurs when all the values are 0 and isn't actually significant
          p_value = 1 
        if (p_value < 0.05):
          stat_sig.append(VariableInfo(var, p_value))

  return stat_sig

def generate_boxplots(variables: list[VariableInfo], group: TestFactor, prefix):
  directory = OUTPUT_DIR+'/'+group.sub_dir+'/boxplots'
  Path(directory).mkdir(exist_ok=True)

  # Note: Cannot use spss.Submit inside DataStep, so use two loops

  # Get labels.
  spss.StartDataStep()
  data_set = spss.Dataset()
  group_label = data_set.varlist[group.var_name].label
  for var in variables:
    var.label = data_set.varlist[var.name].label
  spss.EndDataStep()

  ESCAPE_QUOTE = '\\"'

  # graph boxplot
  for var in variables:
    syntax = f"""
      GGRAPH
        /GRAPHDATASET NAME="graphdataset" VARIABLES= {group.var_name} {var.name}
          MISSING=LISTWISE REPORTMISSING=NO
        /GRAPHSPEC SOURCE=INLINE
        TEMPLATE=["{TEMPLATE_FILE}"].
      BEGIN GPL
        GUIDE: axis(dim(1), label("{group_label.replace('"', ESCAPE_QUOTE)} (p<{"0.01" if var.p_value<0.01 else "0.05"})"))
        GUIDE: axis(dim(2), label("{var.label}"))
        SCALE: linear(dim(2), include(0))
        ELEMENT: schema(position(bin.quantile.letter({group.var_name}*{var.name})))
      END GPL.
    """
    spss.Submit(syntax)
  
  syntax = f"""
    OUTPUT SAVE OUTFILE = '{directory}/boxplots_{group.factor_id}_{prefix}{OUTPUT_SUFFIX}.spv'.
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
  spss.Submit(syntax)

  var_range = f'{prefix}{START_VAR} to {prefix}{END_VAR}' # Specify range of variables to tests.
  variables = spssaux.VariableDict().expand(var_range) # get a list of variables test

  for g in FACTORS:
    run_anova(factor=g, variables=variables, prefix=prefix)

    sig_list = find_significant_vars()  # get the statistically sig variables

    spss.Submit('OUTPUT CLOSE *.')  # close the t-test output file

    if len(sig_list) > 0:
      generate_boxplots(sig_list, g, prefix)
      spss.Submit('OUTPUT CLOSE *.')  # close the boxplot output file

# End SPSS Communication
SpssClient.StopClient()

END PROGRAM.