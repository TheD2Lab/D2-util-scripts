import glob
from pathlib import Path
import pandas as pd
import os

def scrape_significant():

   def add_values(df: pd.DataFrame, x_var: str, y_vars: list, r_vals: list,
      p_vals: list, x_index: list = 0, y_indexes: list = []):

      if x_index and y_indexes:
         for y, r, p, y_i in zip(y_vars, r_vals, p_vals, y_indexes):
            df.loc[-1] = [x_var, y, r, p, x_index, y_i]
            df.index += 1
      else:
         for y, r, p in zip(y_vars, r_vals, p_vals):
            df.loc[-1] = [x_var, y, r, p]
            df.index += 1

   directory = '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants'
   group_tag = 'allParticipants'
   sub_data_tag = 'survey'
   data_tags = ['AI', 'Alt_VSI', 'ASI', 'RPM', 'SSI', 'TI_HSI', 'Windshield', 'wholeScreen', 'Undefined_Area']

   for tag in data_tags:
      sub_directory = os.path.join(directory, tag)
      excel_path = os.path.join(sub_directory, 'pearsons-tests', f'pearson_{group_tag}_{tag}_{sub_data_tag}.xlsx')
      in_data = pd.read_excel(excel_path)
      pearson_values = pd.DataFrame(columns=['x_variable', 'y_variable', 'r_value', 'p_value', 'x_index', 'y_index'])

      all_ys = in_data.iloc[0]
      
      x_var = None
      x_index = None
      r_vals = []
      y_indexes = []

      for i, row in enumerate(in_data.itertuples()):
         if type(row[1]) == str:
            x_var = row[1]
            x_index = i
            for j, cell in enumerate(row):
               if type(cell) == str and '*' in cell:
                  r_vals.append(cell.replace('*', ''))
                  y_indexes.append(j)
         elif y_indexes:
            p_values = [row[i] for i in y_indexes]
            y_vars = [all_ys.iloc[i-1] for i in y_indexes]
            add_values(pearson_values ,x_var, y_vars, r_vals, p_values, x_index, y_indexes)
            y_vars = []
            r_vals = []
            p_values = []
            y_indexes = []
      
      csv_path = os.path.join(sub_directory, 'coefficients')
      os.makedirs(csv_path, exist_ok=True)
      pearson_values.to_csv(os.path.join(csv_path, f'sigCoefficients_{group_tag}_{tag}_{sub_data_tag}.csv'), index=False)

def scrape_graph_values_partial():   
   root_directory = '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/pilot-success'
   pearson_dir = 'pearsons-tests'
   group_tag = 'pilotSuccess'
   sub_data_tag = 'survey'
   data_tags = {
      'AI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_AI.csv',
      'Alt_VSI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_Alt_VSI.csv',
      'ASI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_ASI.csv',
      'RPM': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_RPM.csv',
      'SSI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_SSI.csv',
      'TI_HSI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_TI_HSI.csv',
      'Windshield': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_Windshield.csv',
      'wholeScreen': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_wholeScreen.csv',
      'Undefined_Area': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_Undefined_Area.csv'}
   
   in_pattern = '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/{v1}/coefficients/sigCoefficients_allParticipants_{v1}_{v2}.csv'

   for tag in data_tags:
      file_start = os.path.join(root_directory, tag, pearson_dir, f'pearson_{group_tag}_{tag}_{sub_data_tag}')
      split_files = glob.glob(f'{file_start}_*.xlsx')
      sig_values = pd.read_csv(in_pattern.format(v1 = tag, v2 = sub_data_tag), header=0)
      sig_values[::-1] # reverse it so the output order matches the input file order
      graph_values = pd.DataFrame(columns=['label_value', 'x_variable', 'y_variable', 'r_value', 'p_value'])
      tag_lower = tag.lower() + '_'
      for file_path in split_files:
         val_label = Path(os.path.basename(file_path)).stem.split('_')[-1]
         table: pd.DataFrame = pd.read_excel(file_path)

         for row in sig_values.itertuples():
            x_var = table.iat[row.x_index, 0]
            y_var = table.iat[0, row.y_index-1]
            if (not tag_lower in x_var.lower()) == (not tag_lower in y_var.lower()):
               continue # aoi is in one and only one variable
            if not tag_lower in x_var.lower():
               x_var, y_var = y_var, x_var
            r_val = str(table.iat[row.x_index, row.y_index-1]).replace('*', '')
            p_val = table.iat[row.x_index+1, row.y_index-1]
            graph_values.loc[-1] = [val_label, x_var, y_var, r_val, p_val]
            graph_values.index += 1

      coefficient_dir = os.path.join(root_directory, tag, 'coefficients')
      Path(coefficient_dir).mkdir(parents=True, exist_ok=True)
      graph_values.to_csv(os.path.join(coefficient_dir, f'graphCoefficients_{group_tag}_partial_{tag}_{sub_data_tag}.csv'), index=False)

def scrape_graph_values_all():   
   root_directory = '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/pilot-success'
   pearson_dir = 'pearsons-tests'
   group_tag = 'pilotSuccess'
   sub_data_tag = 'xplane'
   data_tags = {
      'AI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_AI.csv',
      'Alt_VSI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_Alt_VSI.csv',
      'ASI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_ASI.csv',
      'RPM': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_RPM.csv',
      'SSI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_SSI.csv',
      'TI_HSI': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_TI_HSI.csv',
      'Windshield': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_Windshield.csv',
      'wholeScreen': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_wholeScreen.csv',
      'Undefined_Area': '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/coefficients/sigCoefficients_allParticipants_Undefined_Area.csv'}
   
   in_pattern = '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/{v1}/coefficients/sigCoefficients_allParticipants_{v1}_{v2}.csv'

   for tag in data_tags:
      file_start = os.path.join(root_directory, tag, pearson_dir, f'pearson_{group_tag}_{tag}_{sub_data_tag}')
      split_files = glob.glob(f'{file_start}_*.xlsx')
      sig_values = pd.read_csv(data_tags[tag], header=0)
      sig_values[::-1] # reverse it so the output order matches the input file order
      graph_values = pd.DataFrame(columns=['label_value', 'x_variable', 'y_variable', 'r_value', 'p_value'])
      tag_lower = tag.lower() + '_'
      for file_path in split_files:
         val_label = Path(os.path.basename(file_path)).stem.split('_')[-1]
         table: pd.DataFrame = pd.read_excel(file_path)

         for row in sig_values.itertuples():
            x_var = table.iat[row.x_index, 0]
            y_var = table.iat[0, row.y_index-1]
            if (not tag_lower in x_var.lower()) != (not tag_lower in y_var.lower()):
               continue # aoi is in one and only one variable
            r_val = str(table.iat[row.x_index, row.y_index-1]).replace('*', '')
            p_val = table.iat[row.x_index+1, row.y_index-1]
            graph_values.loc[-1] = [val_label, x_var, y_var, r_val, p_val]
            graph_values.index += 1

      coefficient_dir = os.path.join(root_directory, tag, 'coefficients')
      Path(coefficient_dir).mkdir(parents=True, exist=True)
      graph_values.to_csv(os.path.join(coefficient_dir, f'graphCoefficients_{group_tag}_all_{tag}_{sub_data_tag}.csv'), index=False)

if __name__ == '__main__':
   scrape_graph_values_partial()

