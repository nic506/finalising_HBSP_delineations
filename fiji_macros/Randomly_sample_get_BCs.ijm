

// Configuration
tif_searchString = "PSD95_CY5";



baseDir = getDirectory("Choose base directory");
folders = getFileList(baseDir);

// Output CSV file
parts = split(baseDir, "\\");
n = parts.length;
last1 = parts[n-2];
last2 = parts[n-1];
outputFileName = tif_searchString + "_in_" + last1 + "_" + last2 + "_BC_values.csv";
outputFile = baseDir + outputFileName;
File.delete(outputFile);
File.append("ID,min,max", outputFile);

print("\\Clear");

for (i = 0; i < folders.length; i++) {
    if (File.isDirectory(baseDir + folders[i])) {
        
        folderPath_1 = baseDir + folders[i];
        files_1 = getFileList(folderPath_1);
        print("Processing folder: " + folderPath_1);
        
        // Find the TIFF file
        tifFilePath = "";
        for (j = 0; j < files_1.length; j++) {
            if (endsWith(files_1[j], ".tif") && indexOf(files_1[j], tif_searchString) >= 0) {
                tifFilePath = folderPath_1 + files_1[j];
            }
        }
        
        if (tifFilePath == "") {continue;}

        open(tifFilePath);
        id = getTitle();
        
		// Wait for user to auto set brightness and contrast settings 
		waitForUser("", "Auto set BC settings");
        
		// Get min and max pixel values 
		getMinAndMax(min, max);

        // Append row to CSV
        File.append(id + "," + min + "," + max, outputFile);

        close();
    }
}

print("🎉 Done processing all folders!");
