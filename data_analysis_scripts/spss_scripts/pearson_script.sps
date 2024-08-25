* Encoding: UTF-8.
BEGIN PROGRAM PYTHON.
from typing import OrderedDict
import spss, spssaux, SpssClient
from pathlib import Path
import os
from collections import defaultdict
import csv

# temporary file because spss is dumb
TEMP_FILE = os.path.join(os.path.curdir, "temp_file_with_unique_name.sav")

GRAPH_TEMPLATE = '/Users/ashleyjones/Documents/EyeTracking/Statistics/Graph_Templates/scatterplot_top_legend.sgt'

ACTIVE_SET_NAME = "alldata"

VARIABLE_INDEX = 1
SUBHEADER_INDEX = 3
SUBHEADER_MODULUS = 3
P_OFFSET = 1
R_OFFSET = 0

class GraphParams:
   def __init__(self, start_var, end_var, suffix):
      self.start_var = start_var
      self.end_var = end_var
      self.end_suffix = suffix


class Grouping:
   def __init__(self, group_var: str, parent_fname: str):
      self.group_var = group_var
      self.parent_fname = parent_fname


class Job:
   def __init__(self, job_id: str, data_files: list[str], category_file: str, key: str = '',
      test_vars: list[str] = [], groups: list[Grouping] = [],
      output_dir: str = os.path.curdir, graphInfo: list[GraphParams] = [], end_prefix: str = "",
      start_var: str = "", end_var: str = ""
   ):
      '''
      Settings for running a pearson analysis and graphing.
      '''
      self.job_id = job_id
      self.data_files = data_files
      self.category_file = category_file
      self.key = key
      self._test_vars = test_vars
      self.groups = groups
      self.output_dir = output_dir
      self.end_prefix = end_prefix
      self.start_var = start_var
      self.end_var = end_var

   @property 
   def test_vars(self):
      if len(self._test_vars) > 0:
         return self._test_vars
      spss.StartDataStep()
      if not self.start_var or not self.end_var:
         datasetObj = spss.Dataset()
         varListObj = datasetObj.varlist
      if not self.start_var:
         self.start_var = varListObj[1].name
      if not self.end_var:
         self.end_var = varListObj[len(varListObj)-1].name
      var_range = f'{self.start_var} to {self.end_var}' # Specify range of variables to tests.
      self._test_vars = spssaux.VariableDict().expand(var_range) # get a list of variables test
      spss.EndDataStep()
      return self._test_vars


class PearsonValues:
   def __init__(self, x_var: str, y_var: str, r_val: float, p_val: float):
      self.x_var: str = x_var
      self.y_var: str = y_var
      self.r_val: float = float(r_val)
      self.p_val: float = float(p_val)
   
   def to_list(self) -> list:
      return [self.x_var, self.y_var, self.r_val, self.p_val]
   
   def __repr__(self):
      return f'Pearson: {self.x_var} {self.y_var} {self.r_val:.2f} {self.p_val:.2f}'

   def __str__(self):
      return f'Pearson: {self.x_var} {self.y_var} {self.r_val:.2f} {self.p_val:.2f}'


def merge_files(files_paths, key):
   # open the dataset and make a copy to protect it
   set_name = 'mydata'
   file_command = []
   for path in files_paths:
      file_command.append(f"/FILE = '{path}'")
   syntax = f"""
      MATCH FILES
      {" ".join(file_command)}
      /BY {key}.
      
      DATASET NAME {set_name}.
      SAVE OUTFILE = '{TEMP_FILE}'.

      EXECUTE.
   """
   spss.Submit(syntax)


def open_single_file(file_path):
   set_name = 'mydata'
   syntax = f"""
      DATASET CLOSE ALL.
      
      GET FILE = '{file_path}'.
      DATASET NAME original.
      DATASET COPY {set_name}.
      DATASET ACTIVATE {set_name}.
      DATASET CLOSE original.

      SAVE OUTFILE = '{TEMP_FILE}'.

      EXECUTE.
   """
   spss.Submit(syntax)


def open_data(data_files, key):
   if len(data_files) == 1:
      open_single_file(data_files[0])
   else:
      merge_files(data_files, key)


def run_pearson(output_dir, job_id, end_prefix, test_vars, group_var=""):
   directory = os.path.join(OUTPUT_DIR, output_dir)
   Path(directory).mkdir(exist_ok=True)
   filename_end = f'_{end_prefix}' if end_prefix else ''
   file_name = f'{directory}/pearson_{job_id}{filename_end}.spv'
   group_string =f"""
      SORT CASES  BY {group_var}.
      SPLIT FILE SEPARATE BY {group_var}.
      
   """ if group_var else ''
   syntax=f"""
      {group_string}
      CORRELATIONS
      /VARIABLES={" ".join(test_vars)}
      /PRINT=TWOTAIL NOSIG LNODIAG
      /MISSING=PAIRWISE.
        
      OUTPUT SAVE OUTFILE = '{file_name}'.

      EXECUTE.
   """
   spss.Submit(syntax)
   return file_name


def find_all_sig_correlations(out_dir, csv_filename_base, pearson_file, group_values: list = None) -> dict[int, list[list[PearsonValues]]]:
   output_doc = SpssClient.GetDesignatedOutputDoc()
   output_item_list = output_doc.GetOutputItems()
   sigs: dict[int, list[list[PearsonValues]]] = defaultdict(list)

   for index in range(output_item_list.Size()):
      output_item = output_item_list.GetItemAt(index)
      if output_item.GetDescription() != 'Correlations' or output_item.GetType() != SpssClient.OutputItemType.PIVOT: # get table of interest
         continue # skip if not correlations table
      single_table_sigs = []
      pivot_table = output_item.GetSpecificType()
      pivot_table.SetVarNamesDisplay(SpssClient.VarNamesDisplay.Names) # change labels to var names
      # get rows that contain Between Groups p-value
      row_labels = pivot_table.RowLabelArray()
      col_labels = pivot_table.ColumnLabelArray()
      data_cells = pivot_table.DataCellArray()
      for i in range(0, data_cells.GetNumRows(), SUBHEADER_MODULUS):
         x_var = row_labels.GetValueAt(i, VARIABLE_INDEX)
         for j in range(0, data_cells.GetNumColumns()):
            r_value_raw = data_cells.GetValueAt(i+R_OFFSET, j, True)
            if len(r_value_raw) < 1:
               break # empty data on upper triangle
            if r_value_raw.endswith("**"):
               data_cells.SetBackgroundColorAt(i+R_OFFSET, j, 65280)  # green
            elif r_value_raw.endswith("*"):
               data_cells.SetBackgroundColorAt(i+R_OFFSET, j, 65535)  # yellow
            else:
               continue # not significant
            r_value = float(data_cells.GetValueAt(i+R_OFFSET, j, False))
            p_value = float(data_cells.GetValueAt(i+P_OFFSET, j, False))
            y_var = col_labels.GetValueAt(VARIABLE_INDEX, j)
            single_table_sigs.append(PearsonValues(x_var, y_var, r_value, p_value))
      sigs[output_item.GetTreeLevel()].append(single_table_sigs)
      pivot_table.SetVarNamesDisplay(SpssClient.VarNamesDisplay.Labels) # change var names to labels
      spss.Submit(f"""
         OUTPUT SAVE OUTFILE = '{pearson_file}'.
         EXECUTE.
      """)
   if 2 in sigs: # first level correlation; not a group file
      write_single_sigs_to_csv(os.path.join(out_dir, f'{csv_filename_base}.csv'), sigs[2][0])
   if 3 in sigs:
      for i in range(len(sigs[3])):
         group_string = f'_{group_values[i]:.0f}' if group_values and i < len(group_values) else ''
         write_single_sigs_to_csv(os.path.join(out_dir, f'{csv_filename_base}{group_string}.csv'), sigs[3][i]) # these are integers but spss give float
   return sigs


def write_single_sigs_to_csv(write_file: str, data: list[PearsonValues]):
   headers = ['x_variable', 'y_variable', 'r_value', 'p_value']
   with open(write_file, 'w') as csv_file:
      csv_writer = csv.writer(csv_file)
      csv_writer.writerow(headers)
      for ele in data:
         csv_writer.writerow(ele.to_list())


def write_multi_sigs_to_csv(write_file: str, data: dict[int, list[PearsonValues]]):
   headers = ['label_value', 'x_variable', 'y_variable', 'r_value', 'p_value']
   with open(write_file, 'w') as csv_file:
      csv_writer = csv.writer(csv_file)
      csv_writer.writerow(headers)
      for key in data.keys():
         for values in data[key]:
            csv_writer.writerow([key, values.x_var, values.y_var, values.r_val, values.p_val])


def find_correlations_values(in_pearson: list[PearsonValues], values: list[int]) -> dict[int | str, list[PearsonValues]]:
   output_doc = SpssClient.GetDesignatedOutputDoc()
   output_item_list = output_doc.GetOutputItems()
   value_index = 0
   results = OrderedDict()
   for index in range(output_item_list.Size()):
      output_item = output_item_list.GetItemAt(index)
      if (
         output_item.GetDescription() == 'Correlations'
         and output_item.GetType() == SpssClient.OutputItemType.PIVOT
         and output_item.GetTreeLevel() == 3 # get table of interest
      ):
         pivot_table = output_item.GetSpecificType()
         pivot_table.SetVarNamesDisplay(SpssClient.VarNamesDisplay.Names) # change labels to var names
         # get rows that contain Between Groups p-value
         row_labels = pivot_table.RowLabelArray()
         col_labels = pivot_table.ColumnLabelArray()
         data_cells = pivot_table.DataCellArray()
         col_dict = dict()
         row_dict = dict()
         for i in range(0, row_labels.GetNumRows(), SUBHEADER_MODULUS):
            row_dict[row_labels.GetValueAt(i, VARIABLE_INDEX)] = i
         for i in range(col_labels.GetNumColumns()):
            col_dict[col_labels.GetValueAt(VARIABLE_INDEX, i)] = i
         out_pearson = []
         for in_vals in in_pearson:
            x = row_dict[in_vals.x_var]
            y = col_dict[in_vals.y_var]
            p = data_cells.GetValueAt(x+P_OFFSET, y, False)
            r = data_cells.GetValueAt(x+R_OFFSET, y, False)
            out_pearson.append(PearsonValues(in_vals.x_var, in_vals.y_var, r, p))
         results[values[value_index]] = out_pearson
         pivot_table.SetVarNamesDisplay(SpssClient.VarNamesDisplay.Labels)
         value_index += 1
   # results['all'] = in_pearson
   return results


def read_sigs_from_csv(in_file) -> list[PearsonValues]:
   sig_list = []
   with open(in_file, 'r') as csvfile:
      csv_reader = csv.reader(csvfile)
      headers = next(csv_reader)
      for row in csv_reader:
         sig_list.append(PearsonValues(row[0], row[1], float(row[2]), float(row[3])))
      
   return sig_list


def graph_scatterplot(x_var, y_var, x_title="", y_title="", title="", group_var="", legend_label="", template=""):
   x_title = x_title if x_title else x_var
   y_title = y_title if y_title else y_var
   legend_label = legend_label if legend_label else group_var
   if len(group_var) > 0:
      syntax = f"""
         SPLIT FILE OFF.
         formats {x_var} {y_var} (f7.1).
         GGRAPH
            /GRAPHDATASET NAME="graphdataset" VARIABLES={x_var} {y_var} {group_var}
            MISSING=LISTWISE REPORTMISSING=NO
            /GRAPHSPEC SOURCE=INLINE
            TEMPLATE = ["{template}"]
            /FITLINE TOTAL=NO SUBGROUP=NO.
         BEGIN GPL
            SOURCE: s=userSource(id("graphdataset"))
            DATA: {x_var}=col(source(s), name("{x_var}"))
            DATA: {y_var}=col(source(s), name("{y_var}"))
            DATA: {group_var}=col(source(s), name("{group_var}"), unit.category())
            GUIDE: axis(dim(1), label("{x_title}"))
            GUIDE: axis(dim(2), label("{y_title}"))
            GUIDE: legend(aesthetic(aesthetic.color.interior), label("{legend_label}"))
            ELEMENT: point(position({x_var}*{y_var}), color.interior({group_var}))
            ELEMENT: line( position( smooth.linear({x_var}*{y_var} )), color({group_var}))
         END GPL.

         EXECUTE.
         """
   else:
      syntax = f"""
         SPLIT FILE OFF.
         formats {x_var} {y_var} (f7.1).
         GGRAPH
            /GRAPHDATASET NAME="graphdataset" VARIABLES={x_var} {y_var}
            MISSING=LISTWISE REPORTMISSING=NO
            /GRAPHSPEC SOURCE=INLINE
            /FITLINE TOTAL=NO SUBGROUP=NO.
            TEMPLATE=["{template}"].
         BEGIN GPL
            SOURCE: s=userSource(id("graphdataset"))
            DATA: {x_var}=col(source(s), name("{x_var}"))
            DATA: {y_var}=col(source(s), name("{y_var}"))
            GUIDE: axis(dim(1), label("{x_title}"))
            GUIDE: axis(dim(2), label("{y_title}"))
            GUIDE: text.title(label("{title}"))
            SCALE: linear( dim( 1 ), include())
            SCALE: linear( dim( 2 ), include())
            ELEMENT: point(position({x_var}*{y_var}))
            ELEMENT: line( position( smooth.linear({x_var}*{y_var} )))
         END GPL.

         EXECUTE.
      """
   spss.Submit(syntax)


def graph_scatter_plots_with_new_labels(group_var, pearsonValues: dict[float, list[PearsonValues]], old_labels):
   # make a plot for each pearson value in list, hopefully each entry's list size is the same
   first_items = next(iter(pearsonValues.values()))
   for i in range(len(first_items)):
      spss.StartDataStep()
      varListObj = spss.Dataset().varlist
      variableObj = varListObj[group_var]
      group_label = variableObj.label
      # change value labels to have r and p-values
      for val in variableObj.valueLabels.data.keys():
         corr = pearsonValues[val][i]
         variableObj.valueLabels[val] = old_labels[val] + format_rp(corr.r_val, corr.p_val)

      x_label = varListObj[first_items[i].x_var].label # x variable label
      y_label = varListObj[first_items[i].y_var].label # x variable label
      spss.EndDataStep()

      # this has to be outside the data step
      graph_scatterplot(
         x_var=corr.x_var, 
         y_var=corr.y_var, 
         x_title=x_label,
         y_title=y_label,
         group_var=group_var,
         legend_label=group_label,
         template=GRAPH_TEMPLATE
      )

   spss.StartDataStep()
   datasetObj = spss.Dataset()
   varListObj = datasetObj.varlist
   variableObj = varListObj[group_var]
   for val in variableObj.valueLabels.data.keys():
      variableObj.valueLabels[val] = old_labels[val]
   spss.EndDataStep()


def format_rp(r_value, p_value):
   if p_value > 0.05:
      title = f"\nr={r_value:.2f}, p>0.05"
   elif p_value < 0.01:
      title = f"\nr={r_value:.2f}, p<0.01"
   elif p_value == 0.01:
      title = f"\nr={r_value:.2f}, p=0.01"
   elif p_value < 0.05:
      title = f"\nr={r_value:.2f}, p<0.05"
   else:
      title = f"\nr={r_value:.2f}, p=0.05"

   return title


def generate_for_group(grouping: Grouping, test_vars, sig_list, out_dir, data_fname):
   # Get a list of the values in a group
   spss.StartDataStep()
   varObj = spss.Dataset().varlist[grouping.group_var]
   vals_labels: dict[int, str] = OrderedDict()
   for val, label in varObj.valueLabels.data.items():
      vals_labels[val] = label
   spss.EndDataStep()

   # generate pearson correlation table
   pearson_output = run_pearson(out_dir, data_fname, grouping.parent_fname, test_vars, grouping.group_var)

   # highlight and write the individual significant data files
   csv_fbase = f'sigCorrelations_{grouping.parent_fname}_{data_fname}'
   val_list = list(vals_labels)
   find_all_sig_correlations(out_dir, csv_fbase, pearson_output, val_list)

   # make a list of the correlations that will be graphed (based on sig_list input)
   corr_of_interest = find_correlations_values(sig_list, val_list)
   csv_fbase = f'graphCorrelation_{grouping.parent_fname}_{data_fname}.csv'
   corr_csv = os.path.join(out_dir, csv_fbase)
   write_multi_sigs_to_csv(corr_csv, corr_of_interest)

   # save and close output
   spss.Submit(f"""
      OUTPUT SAVE OUTFILE = '{pearson_output}'.
      OUTPUT CLOSE *.
      EXECUTE.
   """)

   # generate the scatter plots
   # del corr_of_interest['all']
   graph_scatter_plots_with_new_labels(grouping.group_var, corr_of_interest, vals_labels)

   graph_fname = os.path.join(out_dir, f'scatterplot_{grouping.parent_fname}_{data_fname}.spv')
   spss.Submit(f"""
      OUTPUT SAVE OUTFILE = '{graph_fname}'.
      OUTPUT CLOSE *.
      EXECUTE.
   """)


if __name__ == '__main__':

   # set how output is saved
   OUTPUT_DIR = '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/'
   OUTPUT_SUFFIX = ''   # empty string if you don't need a suffix

   CATEGORY_FILE = '/Users/ashleyjones/Documents/EyeTracking/Statistics/SAV Data Files/Categorical_Data.sav'

   Path(OUTPUT_DIR).mkdir(exist_ok=True)

   suffix = ""

   jobs = [
      Job(
         job_id='xplane',
         data_files=[
            # '/Users/ashleyjones/Documents/EyeTracking/Statistics/SAV Data Files/AI_AOI_Data.sav',
            # '/Users/ashleyjones/Documents/EyeTracking/Statistics/SAV Data Files/Survey_Data.sav',
            '/Users/ashleyjones/Documents/EyeTracking/Statistics/SAV Data Files/Xplane_Data.sav'
         ],
         category_file=CATEGORY_FILE,
         key='PID',
         groups=['pilot_success'],
         output_dir=os.path.join(OUTPUT_DIR, 'test'),
         end_prefix='success',
         start_var='Approach_Score',
         end_var='MAX_ILS_ABS_Bank_Angle'
      )
   ]

   grouping = Grouping(
      group_var='pilot_success',
      parent_fname='pilotSuccess',

   )
   SpssClient.StartClient() # must have spss communication open to call most functions

   for job in jobs:
      open_data(job.data_files, job.key)
      pearson_output = run_pearson(job.output_dir, job.job_id, "", job.test_vars)
      sig_file = f"sig_correlations_{job.job_id}_{job.end_prefix}"
      sig_dict = find_all_sig_correlations(job.output_dir, sig_file, pearson_output)
      sig_list = sig_dict[2][0]
      merge_files([TEMP_FILE, job.category_file], job.key)
      spss.Submit("""
         OUTPUT CLOSE *.
         EXECUTE.
      """)
      #sig_list = read_sigs_from_csv('/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/test/sig_correlations_xplane_success.csv')
      generate_for_group(
         grouping=grouping,
         test_vars=job.test_vars,
         sig_list=sig_list,
         out_dir=job.output_dir,
         data_fname=job.job_id
      )

   # End SPSS Communication
   SpssClient.StopClient()

   # delete the temp file we were writing to

END PROGRAM.