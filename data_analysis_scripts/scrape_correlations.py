import pandas as pd
import os

def add_values(df: pd.DataFrame, x_var: str, y_vars: list, r_vals: list, p_vals: list):
   for y, r, p in zip(y_vars, r_vals, p_vals):
      df.loc[-1] = [x_var, y, r, p]
      df.index += 1


if __name__ == '__main__':
   directory = '/Users/ashleyjones/Documents/EyeTracking/Statistics/ILS-scatterplots/all-participants/pearson-tests'
   group_tag = 'allParticipants'
   data_tags = ['AI', 'Alt_VSI', 'ASI', 'RPM', 'SSI', 'TI_HSI', 'Windshield', 'wholeScreen', 'Undefined_Area']

   for tag in data_tags:
      excel_path = os.path.join(directory, f'pearson_{group_tag}_{tag}.xlsx')
      in_data = pd.read_excel(excel_path)
      pearson_values = pd.DataFrame(columns=['x_var', 'y_var', 'r_value', 'p_value'])

      in_data.drop(0, axis='index') # drop the title row
      all_ys = in_data.iloc[0]
      
      x_var = None
      r_vals = []
      copy_index = []
      for row in in_data.itertuples():
         if type(row[1]) == str:
            x_var = row[1]
            for i, cell in enumerate(row):
               if type(cell) == str and '*' in cell:
                  r_vals.append(cell.replace('*', ''))
                  copy_index.append(i)
         elif copy_index:
            p_values = [row[i] for i in copy_index]
            y_vars = [all_ys.iloc[i-1] for i in copy_index]
            add_values(pearson_values ,x_var, y_vars, r_vals, p_values)
            y_vars = []
            r_vals = []
            p_values = []
            copy_index = []
      
      csv_path = os.path.join(directory, 'coefficients')
      os.makedirs(csv_path, exist_ok=True)
      pearson_values.to_csv(os.path.join(csv_path, f'sigCoefficients_{group_tag}_{tag}.csv'), index=False)