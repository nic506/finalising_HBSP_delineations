// ====== USER SETTINGS ======
baseDir = getDirectory("Choose base directory");
registration_version_folder_names = newArray("old_regist", "new_regist");
zip_searchString = "RoiSet";
png_searchString = "DONT WANT U";
tif_searchString = "PSD95_CY5"; 
saving_prefix = "RoiOverlay_";                    
strokeColor = "red";
flattened_im_downsample = 0.25;
lineWidth = 5;
adjust_BCs = newArray(90, 350); // for PSD95 CY5 in PSD95/PSD93/GluN1 triplex
setBatchMode(true); 
// ============================

folders = getFileList(baseDir);

for (i = 0; i < folders.length; i++) {
    if (File.isDirectory(baseDir + folders[i])) {
        folderPath_1 = baseDir + folders[i];
        files_1 = getFileList(folderPath_1);
        print("Processing folder: " + folderPath_1);
        
        // --- Loop over registration versions ---
		for (k = 0; k < registration_version_folder_names.length; k++) {
			registration_version = registration_version_folder_names[k];

	        // --- Get tif (montage) file paths ---
	        tifFilePath = "";
	        for (j = 0; j < files_1.length; j++) {
	            if (endsWith(files_1[j], ".tif") && indexOf(files_1[j], tif_searchString) >= 0)
	                tifFilePath = folderPath_1 + files_1[j];
	        }
	        
	        // --- Get png (Nissl) and zip (RoiSet) file paths ---
	        pngFilePath = "";
	        zipFilePath = "";
	        folderPath_2 = folderPath_1 + registration_version + File.separator;
	        files_2 = getFileList(folderPath_2);
	        for (j = 0; j < files_2.length; j++) {
	            if (endsWith(files_2[j], ".png") && indexOf(files_2[j], png_searchString) >= 0) 
	            	pngFilePath = folderPath_2 + files_2[j];
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
	        roiManager("Select All");
	        roiManager("Set Color", strokeColor);
	        roiManager("Set Line Width", lineWidth);
	
	        // --- Process both PNG and TIF images ---
	        if (tifFilePath == "") {print("No TIFF file in " + folderPath_1 + " to overlay");}
	        else {processImage(tifFilePath, zipFilePath, saving_prefix);}
	        if (pngFilePath == "") {print("No PNG file in " + folderPath_2 + " to overlay");}
	        else {processImage(pngFilePath, zipFilePath, saving_prefix);}
	        
	        roiManager("reset");
    	}
    }
}

// --- Function to process image ---
function processImage(imgPath, RoiSetPath, prefix) {
    open(imgPath);
    if (endsWith(imgPath, ".tif")) {
		setMinAndMax(adjust_BCs[0], adjust_BCs[1]);
		wait(1000);
		baseName = File.getNameWithoutExtension(imgPath);
		parentFolder = File.getName(File.getParent(RoiSetPath));
		name = baseName + "_" + parentFolder;
    }
    else {name = File.getName(imgPath);}
    roiManager("Show All");
    wait(500);
    run("Flatten");
    wait(500);
    run("Scale...", "x=" + flattened_im_downsample + " y=" + flattened_im_downsample + " interpolation=Bilinear create");
    savePath = File.getParent(RoiSetPath) + File.separator + prefix + name;
    saveAs("PNG", savePath);
    close("*");
    print("✅ Saved: " + savePath);
}

print("🎉 Done processing all folders!");


