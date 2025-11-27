

// Configuration
channelCombination = "PSD95_PSD93_GLUN1";
//channelCombination = "PSD95_GLUA2_GLUN1";
//channelCombination = "GEPH";
//channelCombination = "GLUN1_GLUA2";
//channelCombination = "VGLUT_VGAT";
var selectedFilePaths, tif_searchStrings;

baseDir = "Z:\\HBSP\\pooled_delineation_data\\";
pooledBrainDirNames = newArray("Brain1", "Brain2", "Brain3", "Brain4", "Brain5", "Brain6");
nToSample = 5;

if (channelCombination == "PSD95_PSD93_GLUN1") {tif_searchStrings = newArray("_cy5", "_af546");}
else if (channelCombination == "PSD95_GLUA2_GLUN1") {tif_searchStrings = newArray("_cy5", "_af555");}
else if (channelCombination == "GEPH") {tif_searchStrings = newArray("_cy5");}
else if (channelCombination == "GLUN1_GLUA2") {tif_searchStrings = newArray("_cy5", "_af546");}
else if (channelCombination == "VGLUT_VGAT") {tif_searchStrings = newArray("_568", "_cy5");}
else {print("❌ Unidentified channel combination " + name);}







/////// SAVING CSV IS INCORRECT FILEPATHS + NEED TO LOOP OVER TIF SEARCHSTRINGS IN IMAGE PROCESSING ///////







// --- Randomly Sample File Paths ---
selectedFilePaths = newArray(nToSample * pooledBrainDirNames.length);
for (i = 0; i < pooledBrainDirNames.length; i++) {
	currentBrain = pooledBrainDirNames[i];
	currentBrainChannelPath = baseDir + currentBrain + channelCombination;
	fileList = getFileList(currentBrainChannelPath);
	
	// Keep only directories 
	fileListDirs = newArray();
	for (j = 0; j < fileList.length; j++) {
		path = currentBrainChannelPath + fileList[j];
    	if (File.isDirectory(path)) {fileListDirs = Array.concat(fileListDirs, fileList[j]);}
	}
	
	// Check enough directories
	if (fileListDirs.length < nToSample) {
        print("❌ Brain " + currentBrain + " only has " + fileListDirs.length + " folders, cannot sample " + nToSample);
		continue;
    }
	
	// Randomly sample directories
	used = newArray();  
	j = 0;
	while (j < nToSample) {
	    randomIdx = floor(random() * fileListDirs.length); 

	    idxIsUsed = false;
	    for (k = 0; k < used.length; k++) {
	        if (used[k] == randomIdx) {
	            idxIsUsed = true;
	            break;
	        }
	    }
	
	    if (!idxIsUsed) {
	        used = Array.concat(used, randomIdx);
	        masterIndex = (nToSample * i) + count;
	        selectedFilePaths[masterIndex] = currentBrainChannelPath + fileListDirs[randomIdx];
	        j++;
	    }
	}
}

// --- Process Images  ---
// Output CSV file
parts = split(baseDir, "\\");
n = parts.length;
last1 = parts[n-2];
last2 = parts[n-1];
outputFileName = tif_searchString + "_in_" + last1 + "_" + last2 + "_BC_values.csv";
outputFile = baseDir + outputFileName;
File.delete(outputFile);
File.append("ID,min,max", outputFile);

for (i = 0; i < selectedFilePaths.length; i++) {
	selectedFileList = getFileList(selectedFilePaths[i]);
	
	tifFilePath = newArray(0);
	for j = 0; j < selectedFileList.length; i++) {
        if (indexOf(selectedFileList[j], tif_searchStrings) >= 0 && endsWith(selectedFileList[j], ".tif")) {
            tifFilePath = Array.concat(tifFilePath, selectedFilePaths[i] + selectedFileList[j]);
        }
	}
	if (tifFilePath.length != 1) {print("❌ Incorrect number of TIFF files in " + selectedFilePaths[i]);}
	
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

