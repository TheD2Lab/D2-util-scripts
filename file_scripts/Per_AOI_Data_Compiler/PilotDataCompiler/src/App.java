import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

/**
    Aggregates the participants' AOI data into 1 file per AOI and 1 combined file with all data. 
    To run this: 
    1. Configure the paths below
    2. Verify all the desired participants are listed in DataConfig.java (the participantID variable). This shouldn't need to be changed unless new participants are added in the future.
    3. Verify all AOIs are listed in DataConfig.java (the aoiNames variable). This also shouldn't need changing unless new AOIs are added in the future.
    4. Comment out code as needed (e.g., remove allData if you only want the AOI specific data)
    5. Run the program. 
    NOTE: If you are re-running this code, make sure none of the output files from a previous run are open, as the code won't be able to overwrite any currently opened files. 
    NOTE: You may need to configure the java project's reference libraries settings in your IDE if it does not automatically detect the jar file.
*/
public class App {
    static ArrayList<List<String>> allData = new ArrayList<>();
    static ArrayList<String> headers;
    static boolean doneHeaders;
    private static final String DATA_PATH = "/Users/ashleyjones/Documents/EyeTracking/Data"; //Path to the folder containing the input
    private static final String DGM_FOLDER = DATA_PATH + "/ILS Approach Gaze Analysis Results (New AOI)"; //Location of folder containing all the individually run DGMs (can be downloaded from the sharepoint as "ILS Approach DGMs (Single AOI)"
    private static final String OUTPUT_FOLDER = DATA_PATH + "/Output"; //Output folder for all resulting CSVs to be generated in
    // private static final String PILOT_CSV_PATH = DATA_PATH + "/ILS_Pilot_Data_with_all_DGMs.csv"; //Path to the All_Pilot_Data CSV file
    // private static final int PILOT_COLUMNS = 58; //Number of columns to take from the All_Pilot_Data file. 58 columns includes all data prior to the overall approach DGMs.
    public static void main(String[] args) throws Exception {
        System.out.println("Beginning data compilation");
        doneHeaders = false; //Headers are taken from the existing files as the software runs. This flag ensures they are only copied over once.
        headers = new ArrayList<>();
        Files.createDirectories(Paths.get(OUTPUT_FOLDER));
        // allData = CSVHandler.csvToArrayList(PILOT_CSV_PATH);
        ArrayList<List<String>> outputData = new ArrayList<>();
        for (int j = 0; j < DataConfig.aoiNames.length; j++) { //Iterate through all AOI names
            String aoiName = DataConfig.aoiNames[j];
            ArrayList<List<String>> singleAOIData = new ArrayList<>();
            for (int i = 0; i < DataConfig.participantID.length; i++) { //Iterate through all participant IDs
                String pID = DataConfig.participantID[i];
                List<String> results = generateAOILine(pID, aoiName, i); //A single line of data containing the pilot data, AOI DGMs, and transition data of a single AOI.
                outputData.add(results);
                singleAOIData.add(results);
            }

            String aoiNoSpaces = aoiName.replace(" ", "_"); // can't have spaces in var names
            String aoiLower = aoiNoSpaces.toLowerCase();    // snake casing headers
            List<String> aoiHeaders = new LinkedList<>();
            for (String h : headers) {
                aoiHeaders.add(h.replaceFirst("aoi", aoiLower));
            }
            aoiHeaders.addFirst("pid");
            singleAOIData.addAll(0,Arrays.asList(aoiHeaders));
            CSVHandler.writeToCSV(singleAOIData, OUTPUT_FOLDER + "/AOI_"+ aoiNoSpaces +"_Pilot_Data.csv"); //Outputs the file for a single AOI
        }
        headers.addFirst("pid");
        outputData.addAll(0,Arrays.asList(headers));
        CSVHandler.writeToCSV(outputData, OUTPUT_FOLDER + "/AOI_Combined_Pilot_Data.csv"); //Outputs the file for all the combines AOIs.
        System.out.println("Data compilation completed.");
    }

    static public List<String> generateAOILine(String pID, String aoiName, int pIDRow) {
        List<String> result = new LinkedList<>();
        result.add(pID);
        // List<String> dataLine = allData.get(pIDRow + 1);
        // for (int i = 0; i < PILOT_COLUMNS; i++) { //Adds headers from the pilot data.
        //     result.add(dataLine.get(i));
        //     if (!doneHeaders) {
        //         headers.add(processHeader(allData.get(0).get(i))); 
        //     }
        // }
        
        
        String participantFolder = DGM_FOLDER + "/" + pID; //The folder containing the various CSVs for a particular participant
        String pIDPath = participantFolder + "/" + pID; //Locates the folder containing DGMs for the current participant ID
        String dgmPath = pIDPath + "_AOI_DGMs.csv"; //Locates the participants AOI DGM file.
        String transitionPath = pIDPath + "_AOI_Transitions.csv"; //Locates the participants AOI transition file.


        ArrayList<List<String>> dgm = CSVHandler.csvToArrayList(dgmPath);
        int[] aoiLocation = CSVHandler.findValue(dgm, aoiName);
        int aoiRow = aoiLocation[0];

        if (aoiRow == -1) return result; //If the current AOI is not found for a participant, returns early.

        for (int i = 0; i < dgm.get(0).size(); i++) { //Copies all DGM data over
            String val = dgm.get(aoiRow).get(i);
            result.add(val);
        }

        if (!doneHeaders) { //Adds AOI DGM headers if they have not been added already
            for (int i = 0; i < dgm.get(0).size(); i++) {
                headers.add(processHeader("aoi_" + dgm.get(0).get(i).replace(".", "")));
            }
        }

        ArrayList<List<String>> transitionData = CSVHandler.csvToArrayList(transitionPath);

        for (int i = 0; i < DataConfig.aoiNames.length; i++) { //Iterates overall all AOI names
            String toAOI = DataConfig.aoiNames[i];
            String toAOIStyled = toAOI.replace(" ", "_").toLowerCase();
            if (!doneHeaders) { //Adds AOI transition headers if they have not been added already.
                headers.add(processHeader("aoi_to_" + toAOIStyled));
                headers.add(processHeader("aoi_to_" + toAOIStyled + "_transitions_count"));
                headers.add(processHeader("aoi_to_" + toAOIStyled + "_proportion_including_self_transitions"));
                headers.add(processHeader("aoi_to_" + toAOIStyled + "_proportion_excluding_self_transitions"));
            }
            for (int j = 0; j < transitionData.size(); j++) { //Adds transition data to the file if the line matches the current AOI pair (fromAOI to aoiName)
                List<String> transition = transitionData.get(j);
                if (transition.get(0).contains(aoiName + " -> " + toAOI)) { 
                    result.add(transition.get(0));
                    result.add(transition.get(1));
                    result.add(transition.get(2));
                    result.add(transition.get(3));
                }
            }
        }
        doneHeaders = true;
        return result;
    }

    public static String processHeader(String h) { //Replaces whitespace with underscores.
        return h.replace(" ", "_");
    }
}
