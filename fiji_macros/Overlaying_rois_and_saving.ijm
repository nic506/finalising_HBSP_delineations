

// --- Configuration ---
registration_version_folder_names = newArray("old_regist", "new_regist");
zip_searchString = "RoiSet";
png_searchString = "HELL NO";
overlayTIFFs = true;
saving_prefix = "RoiOverlay_";                    
strokeColor = "cyan";
flattened_im_downsample = 0.2;
lineWidth = 5;
setBatchMode(true); 
var channelCombination, tif_searchStrings, min_BC, max_BC;

function findChannelCombination(name) {
	if (name == "PSD95_PSD93_GLUN1") { 
		channelCombination = "PSD95-PSD93";
	    tif_searchStrings = newArray("_cy5", "_af546");
		min_BC = newArray(, ); 
	    max_BC = newArray(, );
	}
	else if (name == "PSD95_GLUA2_GLUN1") { 
		channelCombination = "PSD95-GLUA2";
	    tif_searchStrings = newArray("_cy5", "_af555");
		min_BC = newArray(, ); 
	    max_BC = newArray(, );
	}
	else if (name == "GEPH") { 
		channelCombination = "GEPH";
	    tif_searchStrings = newArray("_cy5");
		min_BC = newArray(, ); 
	    max_BC = newArray(, );
	}
	else if (name == "GLUN1_GLUA2") { 
		channelCombination = "GLUN1-GLUA2";
	    tif_searchStrings = newArray("_cy5", "_af546");
		min_BC = newArray(, ); 
	    max_BC = newArray(, );
	}
	else if (name == "VGLUT_VGAT") { 
		channelCombination = "VGLUT-VGAT";
	    tif_searchStrings = newArray("_568", "_cy5");
		min_BC = newArray(, ); 
	    max_BC = newArray(, );
	}
	else {print("❌ Unidentified channel combination " + name);}
}



// --- Main ---
macro "Overlay ROIs" {
	pooledBrainDir = getString("Enter pooled brain directory:", "");
	if (!endsWith(pooledBrainDir, "\\")) {pooledBrainDir = pooledBrainDir + "\\";}
	pooledBrainDirFiles = getFileList(pooledBrainDir);
	for (i = 0; i < pooledBrainDirFiles.length; i++) {
		baseDir = pooledBrainDir + pooledBrainDirFiles[i];
	    if (File.isDirectory(baseDir)) {
			close("*");
			print("\\Clear");
	    	
	    	baseDirFiles = getFileList(baseDir);
    		if (baseDirFiles.length == 0) {
    			print("❌ Base directory is empty " + baseDir);
    			continue;
    		}
	    	
	    	if (overlayTIFFs) {findChannelCombination(replace(pooledBrainDirFiles[i], "/", ""));}
			else { // Dummy values to prevent overlaying ROIs on TIFFs
			    tif_searchStrings = newArray("HELL NO");
			    min_BC = newArray(0);
			    max_BC = newArray(0);
			}
			
			print("--- Base Directory: " + File.getName(baseDir) + " ---");
	    	processDirectory(baseDir);
	    	print("\n🎉 Overlaying and Saving Complete: " + baseDir);
	    	
		    logContent = getInfo("log");
		    logFilePath = baseDir + "Overlay_Log(most-recent).txt";
		    File.saveString(logContent, logFilePath);
	    }
	}
}

// --- Process Directory Func ---
function processDirectory(dir) { 
	folders = getFileList(dir);
	for (i = 0; i < folders.length; i++) {
	    if (File.isDirectory(dir + folders[i])) {
	        folderPath_1 = dir + folders[i];
	        files_1 = getFileList(folderPath_1);
	        print("\nProcessing folder: " + folderPath_1);
	        
	        // --- Get tif (montage) file paths ---
	        tifFilePathList = newArray(tif_searchStrings.length);
	        for (k = 0; k < tif_searchStrings.length; k++) {
	        	current_tif_searchString = tif_searchStrings[k];
		        for (j = 0; j < files_1.length; j++) {
		            if (endsWith(files_1[j], ".tif") && indexOf(toLowerCase(files_1[j]), current_tif_searchString) >= 0)
		                tifFilePathList[k] = folderPath_1 + files_1[j];
		        }
	        }
	        
	        // --- Loop over registration versions ---
			for (k = 0; k < registration_version_folder_names.length; k++) {
				registration_version = registration_version_folder_names[k];
		        
		        // --- Get png (Nissl) and zip (RoiSet) file paths ---
		        pngFilePath = newArray(0);
		        zipFilePath = "";
		        folderPath_2 = folderPath_1 + registration_version + File.separator;
		        files_2 = getFileList(folderPath_2);
		        for (j = 0; j < files_2.length; j++) {
		            if (endsWith(files_2[j], ".png") && indexOf(files_2[j], png_searchString) >= 0) 
		            	pngFilePath = Array.concat(pngFilePath, folderPath_2 + files_2[j]);
		            if (endsWith(files_2[j], ".zip") && indexOf(files_2[j], zip_searchString) >= 0) 
		            	zipFilePath = folderPath_2 + files_2[j];
		        }
		        
		        if (zipFilePath == "") {
		            print("❌ Missing ROI zip file in " + folderPath_2);
		            continue;
		        }
		
		        // --- Load ROIs and set properties ---
		        roiManager("reset");
		        roiManager("Open", zipFilePath);
		        if (roiManager("count") > 0) {
	                roiManager("Select All");
	                roiManager("Set Color", strokeColor);
	                roiManager("Set Line Width", lineWidth);
	            }
	            else {print("❌ No ROIs in zip " + zipFilePath);}
		
		        // --- Process both PNG and TIF images ---
		        if (tif_searchStrings[0] == "HELL NO") {print("✱ Not wanting to overlay TIFF file in " + folderPath_1);}
		        else if (tifFilePathList.length != tif_searchStrings.length) {print("❌ Incorrect number of TIFF files in " + folderPath_1);}
		        else {processImage(tifFilePathList, zipFilePath, saving_prefix);}
		        
		        if (png_searchString == "HELL NO") {print("✱ Not wanting to overlay PNG file in " + folderPath_2);}
		        else if (pngFilePath.length == 0) {print("❌ Missing PNG file in " + folderPath_2);}
		        else {processImage(pngFilePath, zipFilePath, saving_prefix);}
		        
		        roiManager("reset");
	    	}
	    }
	}
}

// --- Process Image Func (dynamically creates composite for number of channels) ---
function processImage(imgPathList, RoiSetPath, prefix) {
	mergeCommand = "";
	for (k = 0; k < imgPathList.length; k++) {
		open(imgPathList[k]);
		if (endsWith(imgPathList[k], ".tif")) {
			setMinAndMax(min_BC[k], max_BC[k]);
			wait(1000);
			mergeCommand += " c" + (k + 1) + "=[" + getTitle() + "]";
		}
	}
	if (endsWith(imgPathList[0], ".png")) {name = File.getName(imgPathList[0]);} 
	else {
		mergeCommand += " create ignore";
    	run("Merge Channels...", mergeCommand);
    	close("\\Others");
		parentFolder = File.getName(File.getParent(RoiSetPath));
		grandParentFolder = File.getName(File.getParent(File.getParent(RoiSetPath)));
		name = "Composite_" + channelCombination + grandParentFolder + parentFolder;
	}
    roiManager("Show All");
    wait(500);
    run("Flatten");
    wait(500);
    run("Scale...", "x=" + flattened_im_downsample + " y=" + flattened_im_downsample + " interpolation=Bilinear create");
    savePath = File.getParent(RoiSetPath) + File.separator + prefix + name;
    saveAs("PNG", savePath);
    close("*");
    print("✅ Overlay saved to: " + savePath);
}

