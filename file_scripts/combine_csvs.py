import os
import pandas as pd
from tqdm import tqdm

# Define paths and dictionary
# Base path where the data is stored
base_path = '/Volumes/storage/ILS Approach Gaze Data (New AOI)/results'

# List of folders containing different types of data to process
folders = ['FPOGD', 'LPMM', 'LPMM+RPMM', 'RPMM', 'SACCADE_DIR', 'SACCADE_MAG', 'BKPMIN']

# Dictionary mapping participant IDs (PIDs) to their landing success status (True for success, False for failure)
landing_success_dict = {
    'p1': True, 'p10': False, 'p11': False, 'p12': True, 'p14': False, 'p15': False,
    'p16': False, 'p17': False, 'p18': True, 'p19': True, 'p2': True, 'p21': True,
    'p22': True, 'p23': True, 'p24': True, 'p26': False, 'p28': False, 'p29': True,
    'p3': True, 'p30': True, 'p31': True, 'p32': False, 'p33': True, 'p34': True,
    'p36': True, 'p37': True, 'p38': True, 'p39': True, 'p40': True, 'p41': False,
    'p42': False, 'p43': False, 'p44': False, 'p46': True, 'p47': True, 'p5': True,
    'p7': False, 'p8': True, 'p9': True
}

# Create main output folder for all combined results
combined_results_base_path = os.path.join(base_path, 'combined_results_all')
# Create the directory if it doesn't exist
os.makedirs(combined_results_base_path, exist_ok=True)

# Define specific columns to keep for each feature set
# Columns related to processing features
processing_columns = [
    "sum_of_all_fixation_duration_s", "mean_fixation_duration_s", "median_fixation_duration_s",
    "stdev_of_fixation_durations_s", "min_fixation_duration_s", "max_fixation_duration_s",
    "fixation_to_saccade_ratio", "success"
]

# Columns related to searching features
searching_columns = [
    "total_number_of_fixations", "total_number_of_saccades", "sum_of_all_saccade_lengths",
    "mean_saccade_length", "median_saccade_length", "stdev_of_saccade_lengths",
    "min_saccade_length", "max_saccade_length", "sum_of_all_saccade_durations",
    "mean_saccade_duration", "median_saccade_duration", "stdev_of_saccade_durations",
    "min_saccade_duration", "max_saccade_duration", "scanpath_duration",
    "convex_hull_area", "average_peak_saccade_velocity", "success"
]

# Columns related to workload features
workload_columns = [
    "average_pupil_size_of_left_eye", "average_pupil_size_of_right_eye", "average_pupil_size_of_both_eyes",
    "sum_of_all_absolute_degrees", "mean_absolute_degree", "median_absolute_degree",
    "stdev_of_absolute_degrees", "min_absolute_degree", "max_absolute_degree",
    "sum_of_all_relative_degrees", "mean_relative_degree", "median_relative_degree",
    "stdev_of_relative_degrees", "min_relative_degree", "max_relative_degree",
    "average_blink_rate_per_minute", "success"
]

# Initialize total file counters
total_files_read = 0
total_files_created = 0

# Initialize a dictionary to collect ARFF files per subfolder (not used in this script but initialized for potential future use)
arff_files_per_subfolder = {
    'all_features': {},
    'processing': {},
    'searching': {},
    'workload': {}
}

# Function to save different versions of combined data
def save_processed_files(combined_df, output_folder, file_prefix, folder_name):
    global total_files_created, arff_files_per_subfolder

    # Create output directories for different feature sets
    all_features_folder = os.path.join(output_folder, 'all_features')
    processing_folder = os.path.join(output_folder, 'processing')
    searching_folder = os.path.join(output_folder, 'searching')
    workload_folder = os.path.join(output_folder, 'workload')
    os.makedirs(all_features_folder, exist_ok=True)
    os.makedirs(processing_folder, exist_ok=True)
    os.makedirs(searching_folder, exist_ok=True)
    os.makedirs(workload_folder, exist_ok=True)

    # Save combined data with all features
    all_features_file_path = os.path.join(all_features_folder, f'{file_prefix}_all_features.csv')
    combined_df.to_csv(all_features_file_path, index=False)  # Keep 'Pid' and all columns
    total_files_created += 1
    print(f'Combined file saved at: {all_features_file_path}')

    # Save data with processing features
    processing_file_path = os.path.join(processing_folder, f'{file_prefix}_processing.csv')
    combined_df[processing_columns + ['Pid']].to_csv(processing_file_path, index=False)
    total_files_created += 1

    # Save data with searching features
    searching_file_path = os.path.join(searching_folder, f'{file_prefix}_searching.csv')
    combined_df[searching_columns + ['Pid']].to_csv(searching_file_path, index=False)
    total_files_created += 1

    # Save data with workload features
    workload_file_path = os.path.join(workload_folder, f'{file_prefix}_workload.csv')
    combined_df[workload_columns + ['Pid']].to_csv(workload_file_path, index=False)
    total_files_created += 1

    print(f'Processed files saved in "processing", "searching", and "workload" folders for {file_prefix}.')

# Function to combine CSV files for a given folder and data type (baseline or windowed data)
def combine_csv_files(folder_name, data_type):
    global total_files_read
    combined_data = []
    file_count = 0

    # Description for the progress bar
    pbar_desc = f'Combining CSV files for {folder_name} - {data_type}'
    # Iterate over each participant ID and their landing success status
    pbar = tqdm(landing_success_dict.items(), desc=pbar_desc)
    for pid, success in pbar:
        # Determine the subfolder based on data type
        if data_type == 'baseline':
            data_subfolder = 'baseline'
        else:
            data_subfolder = os.path.join('event', data_type)
        # Construct the file path to the participant's data file
        file_path = os.path.join(
            base_path, folder_name, pid, data_subfolder, f'{data_type}_DGMs.csv'
        )
        # Update progress bar postfix with current participant ID
        pbar.set_postfix({'PID': pid})

        # Check if the file exists
        if os.path.exists(file_path):
            # Read the CSV file into a DataFrame
            df = pd.read_csv(file_path)

            # Add 'Pid' and 'success' columns to the DataFrame
            df['Pid'] = pid
            df['success'] = success

            # Append the DataFrame to the list of combined data
            combined_data.append(df)
            file_count += 1
            total_files_read += 1

    # If data was found and combined
    if combined_data:
        # Concatenate all participant DataFrames into one
        combined_df = pd.concat(combined_data, ignore_index=True)

        # Create output directory for the current folder
        output_folder = os.path.join(combined_results_base_path, folder_name)
        # Save the combined data using the function defined above
        save_processed_files(combined_df, output_folder, f'combined_{data_type}_{folder_name}', folder_name)
    else:
        # If no data was found for the given folder and data type
        print(f"No data available to combine for folder: {folder_name}, data type: {data_type}")

    print(f"Total files read for {data_type} in folder '{folder_name}': {file_count}")

# Main execution flow with progress bars
if __name__ == '__main__':
    # Process baseline data for each folder
    for folder in tqdm(folders, desc='Processing Baseline Folders'):
        combine_csv_files(folder, 'baseline')

    # Process windowed data (window1 to window14) for each folder
    for folder in tqdm(folders, desc='Processing Window Folders'):
        # Iterate over each window
        for window in tqdm([f'window{i}' for i in range(1, 15)], desc=f'Processing Windows in {folder}', leave=False):
            combine_csv_files(folder, window)

    # Print the total counts of files read and created
    print(f"\nTotal files read across all folders and windows: {total_files_read}")
    print(f"Total files created across all folders and versions: {total_files_created}")