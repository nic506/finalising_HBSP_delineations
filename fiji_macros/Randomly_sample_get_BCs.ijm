

// Configuration
channelCombination = "PSD95_PSD93_GLUN1";
//channelCombination = "PSD95_GLUA2_GLUN1";
//channelCombination = "GEPH";
//channelCombination = "GLUN1_GLUA2";
//channelCombination = "VGLUT_VGAT";
var selectedDirPaths, tif_searchStrings;

baseDir = "Z:\\HBSP\\pooled_delineation_data\\";
pooledBrainDirNames = newArray("Brain1", "Brain2", "Brain3", "Brain4", "Brain5", "Brain6");
nToSample = 5;

if (channelCombination == "PSD95_PSD93_GLUN1") {tif_searchStrings = newArray("_cy5", "_af546");}
else if (channelCombination == "PSD95_GLUA2_GLUN1") {tif_searchStrings = newArray("_cy5", "_af555");}
else if (channelCombination == "GEPH") {tif_searchStrings = newArray("_cy5");}
else if (channelCombination == "GLUN1_GLUA2") {tif_searchStrings = newArray("_cy5", "_af546");}
else if (channelCombination == "VGLUT_VGAT") {tif_searchStrings = newArray("_568", "_cy5");}
else {print("❌ Unidentified channel combination " + name);}



// --- Randomly Sample Directory Paths ---			
close("*");
print("\\Clear");
selectedDirPaths = newArray(nToSample * pooledBrainDirNames.length);
for (i = 0; i < pooledBrainDirNames.length; i++) {
	currentBrain = pooledBrainDirNames[i];
	currentBrainChannelPath = baseDir + currentBrain + File.separator + channelCombination + File.separator;
	fileList = getFileList(currentBrainChannelPath);
	
	// Keep only directories 
	fileListDirs = newArray(0);
	for (j = 0; j < fileList.length; j++) {
		path = currentBrainChannelPath + fileList[j];
    	if (File.isDirectory(path)) {fileListDirs = Array.concat(fileListDirs, fileList[j]);}
	}
	
	// Check enough directories
	if (fileListDirs.length < nToSample) {
		exit("MACRO STOPPED: Brain " + currentBrain + " only has " + fileListDirs.length + " folders, cannot sample " + nToSample);
		//print("❌ Brain " + currentBrain + " only has " + fileListDirs.length + " folders, cannot sample " + nToSample);
        //continue;
    }
	
	// Randomly sample directories
	used = newArray(0);  
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
	        masterIndex = (nToSample * i) + j;
	        selectedDirPaths[masterIndex] = currentBrainChannelPath + fileListDirs[randomIdx];
	        j++;
	    }
	}
}

// --- Count number of filled positions (with directory path) in selectedDirPaths ---
filledCount = 0;
for (i = 0; i < selectedDirPaths.length; i++) {
    if (selectedDirPaths[i] != 0 && selectedDirPaths[i] != "") {filledCount++;}
}
print("Expected number of directory filepaths = " + selectedDirPaths.length + ", actual = " + filledCount);

// --- Prepare CSV Files ---
csvFilePaths = newArray(tif_searchStrings.length);
for (i = 0; i < tif_searchStrings.length; i++) {
	formatted_channelCombination = replace(channelCombination, "_", "-");
    csvName = "BCs" + tif_searchStrings[i] + "_" + formatted_channelCombination + ".csv";
    csvPath = baseDir + "\\randomly_sampled_BCs\\" + csvName;
    
    csvFilePaths[i] = csvPath;
    
    if (File.exists(csvPath)) {_ = File.delete(csvPath);}
    File.append("ID,Min,Max", csvPath);
	print("Created CSV file for: " + tif_searchStrings[i]);
}

// --- Process Images  ---
for (i = 0; i < tif_searchStrings.length; i++) {
	currentSearchString = tif_searchStrings[i];
	print("... Processing images: " + currentSearchString);
	currentCsvPath = csvFilePaths[i];
	
	for (j = 0; j < selectedDirPaths.length; j++) {
		currentDirPath = selectedDirPaths[j];
		currentDirFileList = getFileList(currentDirPath);
		
		tifFilePath = newArray(0);
		for (k = 0; k < currentDirFileList.length; k++) {
	        if (indexOf(toLowerCase(currentDirFileList[k]), currentSearchString) >= 0 && endsWith(currentDirFileList[k], ".tif")) {
	            tifFilePath = Array.concat(tifFilePath, currentDirPath + currentDirFileList[k]);
	        }
		}
		if (tifFilePath.length != 1) {
			print("❌ Found " + tifFilePath.length + " TIFF files, expected one in " + currentDirPath);
			continue;
		}
		
		open(tifFilePath[0]);
	    id = getTitle();
	    
		// Wait for user to auto set brightness and contrast settings 
		waitForUser("", "Adjust BC settings: click 'Auto' once");
	    
		// Get min and max pixel values 
		getMinAndMax(min, max);
	
	    // Append row to CSV
	    File.append(id + "," + min + "," + max, currentCsvPath);
	
	    close();
	}
	
	print("✅ BCs saved to: " + currentCsvPath);
}

print("\n🎉 Randomly Sampling to Get BCs Complete: " + channelCombination);

