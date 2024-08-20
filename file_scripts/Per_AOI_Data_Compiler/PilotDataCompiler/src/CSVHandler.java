import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import com.opencsv.CSVWriter;

public abstract class CSVHandler {
    static public ArrayList<List<String>> csvToArrayList(String filePath) { //Converts a CSV file into an ArrayList<List<String>> of all the data.
        ArrayList<List<String>> records = new ArrayList<>();
        try {
            BufferedReader br = new BufferedReader(new FileReader(filePath));
            String line;
            while ((line = br.readLine()) != null) {
                String[] values = line.split(",");
                records.add(new ArrayList<>());
                for (int i = 0; i < values.length; i++) {
                    records.get(records.size() - 1).add(values[i].replace("\"","")); //Removes quotations in the data (Some is double-quoted)
                }
            }
            br.close();
        } catch(Exception e) {
            return null;
        }
        return records;
    }
    
    static public void writeToCSV(ArrayList<List<String>> data, String fileName) { //Saves a 2D arraylist of strings as a CSV file. The filename must include full path.
        try {
            String fString = fileName.contains(".csv") ? fileName : fileName + ".csv";
            
            File file = new File(fString);
            FileWriter fileWriter = new FileWriter(file);
            CSVWriter csvWriter = new CSVWriter(fileWriter);

            for (int i = 0; i < data.size(); i++) {
                List<String> row = data.get(i);
                int rowLength = row.size();
                String[] csvData = row.toArray(new String[rowLength]);
                csvWriter.writeNext(csvData);
            }

            csvWriter.close();
        } catch (Exception e) {
            System.err.println(e);
        }
    }

    static public int getHeaderIndex(ArrayList<List<String>> data, String header) { //Returns the column index of a particular header. Returns -1 if none found.
        if (data.size() == 0) return -1;
        for (int i = 0; i < data.get(0).size(); i++) {
            if (data.get(0).get(i).equals(header)) {
                return i;
            }
        }
        return -1;
    }
    static public int[] findValue(ArrayList<List<String>> data, String value) { //Finds a value in the array and returns its location in the format int[] {row, column}. Returns {-1, -1} if none found.
        for (int j = 0; j < data.size(); j++) {
            for (int i = 0; i < data.get(0).size(); i++) {
                if (data.get(j).get(i).equals(value)) {
                    return new int[]{j, i};
                }
            }   
        }
        return new int[] {-1,-1};
    }
    static public String getValue(ArrayList<List<String>> data, String header, int row) { //Gets the value in the desired row under the specified header. Returns an empty string if none found.
        if (row >= data.size()) return "Out of range";
        int headerIndex = getHeaderIndex(data, header);
        if (headerIndex == -1) return "";
        return data.get(row).get(headerIndex);   
    }
}