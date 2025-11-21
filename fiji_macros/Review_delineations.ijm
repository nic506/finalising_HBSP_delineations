

// --- Configuration ---
distinguisher1 = "old_regist";
distinguisher2 = "new_regist";
imageChoice_prefix = "ImageChoice  ";
instructions_prefix = "Instructions  ";
empty_prefix = "Empty  ";
dialgoue_wait_for_user = false;



// --- Main ---
macro "Review Montages" {
	setBatchMode(false);
	//base_dir = getDirectory("Choose base directory");
	base_dir = getString("Enter base directory:", "");
	
	//print("\\Clear");
	//print("move me");
	//waitForUser(
	    //"Prepare your screen for reviewing",
	    //"(1) Hide all application windows except Fiji.\n"
	    //+ "(2) Hide the Macro Script Runner window.\n"
	    //+ "(3) Move the Log window to the bottom-left corner of the screen."
	//);

	print("\\Clear");
    processDirectory(base_dir);
    print("--- Reviewing Of " + base_dir + " Complete ---");
}

// --- Process Directory Func ---
function processDirectory(dir) {
	
	// Loop over directories in dir
	folders = getFileList(dir);
	for (i = 0; i < folders.length; i++) {
	    if (File.isDirectory(dir + folders[i])) {
	        folderPath = dir + folders[i];
	        print("Processing folder: " + folderPath);
	        
	        // Skip if already reviewed 
            filesInFolder = getFileList(folderPath);
            shouldSkip_check1 = false;
            shouldSkip_check2 = false;
            for (k = 0; k < filesInFolder.length; k++) {
                fileName = filesInFolder[k];
                if ((startsWith(fileName, instructions_prefix) || startsWith(fileName, empty_prefix)) && endsWith(fileName, ".txt")) {
                    shouldSkip_check1 = true;
                }
                if (startsWith(fileName, imageChoice_prefix) && endsWith(fileName, ".csv")) {
                    shouldSkip_check2 = true;
                }
            }
            if (shouldSkip_check1 && shouldSkip_check2) {
                print("✱ Already reviewed, skipping folder: " + folderPath);
                continue;
            }
	        
	        // Find filepaths to Roi Overlay Montage files
			path1 = newArray(0);
            path2 = newArray(0);
            baseName = "";
	        for (j = 0; j < filesInFolder.length; j++) {
                fileName = filesInFolder[j];
                
                // Check for distinguisher 1 image and create basename to save output file
                if (File.isDirectory(folderPath + fileName) && fileName == distinguisher1 + "/") {
                	subfolderPath = folderPath + fileName;
                	filesInSubfolder = getFileList(subfolderPath);
                	for (w = 0; w < filesInSubfolder.length; w++) {
                		fileNameSub = filesInSubfolder[w];
                		if (endsWith(fileNameSub, ".png") && indexOf(fileNameSub, distinguisher1) >= 0 && startsWith(fileNameSub, "RoiOverlay_") && indexOf(fileNameSub, "Montage") >= 0) {
							path1 = Array.concat(path1, subfolderPath + fileNameSub);
                    		baseName = replace(fileNameSub, ".png", "");
                    		baseName = replace(baseName, distinguisher1, "");
                		}
                	}
                }
                
                // Check for distinguisher 2 image
                else if (File.isDirectory(folderPath + fileName) && fileName == distinguisher2 + "/") {
                	subfolderPath = folderPath + fileName;
                	filesInSubfolder = getFileList(subfolderPath);
                	for (w = 0; w < filesInSubfolder.length; w++) {
                		fileNameSub = filesInSubfolder[w];
						if (endsWith(fileNameSub, ".png") && indexOf(fileNameSub, distinguisher2) >= 0 && startsWith(fileNameSub, "RoiOverlay_") && indexOf(fileNameSub, "Montage") >= 0) {
                    		path2 = Array.concat(path2, subfolderPath + fileNameSub);
                		}
                	}
                }
	        }
	        
	        // Check exactly one image for each distinguisher
	        if (path1.length == 1 && path2.length == 1) {
				print("... Reviewing images: " + File.getName(path1[0]) + " + " + File.getName(path2[0]));
                reviewImages(path1[0], path2[0], folderPath, baseName);
            } 
            else {
                print("❌ Exactly one image NOT found for each distinguisher string in: " + folderPath);
            }
	    }
	}
}

// --- Dual Image Review Func ---
function reviewImages(path1, path2, imageDir, baseName) {
	
	// Open images and randomise their titles
	trueNameForImage1 = "";
    trueNameForImage2 = "";
    
    if (random() < 0.5) {
        // Case A: Image 1 = distinguisher1, Image 2 = distinguisher2
        open(path1);
        selectWindow(getTitle()); run("Rename...", "title='Image 1'");
        trueNameForImage1 = distinguisher1;
        open(path2);
        selectWindow(getTitle()); run("Rename...", "title='Image 2'");
        trueNameForImage2 = distinguisher2;
    } 
    else {
        // Case B: Image 1 = distinguisher2, Image 2 = distinguisher1
        open(path2);
        selectWindow(getTitle()); run("Rename...", "title='Image 1'");
        trueNameForImage1 = distinguisher2;
        open(path1);
        selectWindow(getTitle()); run("Rename...", "title='Image 2'");
        trueNameForImage2 = distinguisher1;
    }
    
    // Conditional wait for user to enable them to interact with Fiji before dialogue shown
    if (dialgoue_wait_for_user) {
    	waitForUser(
    		"Image Inspection",
		    "If you want to zoom, pan, or interact with the images to inspect them, do so now.\n\n" +
		    "When you are ready, press OK. After that, the review dialog will appear and image interaction will be disabled."
		);
    }
    
	repeatReview = true;
	while (repeatReview) {
		
	    // Create checklist and notes dialogue
	    Dialog.create("REVIEW:");
	    
	    // Section 1: Image comparison
	    choices = newArray("", "Image 1", "Image 2");
		Dialog.addRadioButtonGroup("  Which image is better?", choices, 1, 3, "");
		
		// Section 2: Quality checks
	  	Dialog.addMessage("\n");
	  	Dialog.addMessage("Quality checks:");
		Dialog.addCheckboxGroup(
		    2, 2,
		    newArray("Needs to be rotated", "Tissue rip", "Blood vessel", "Edge artefact"),
		    newArray(false, false, false, false)
		);
	  	Dialog.addMessage("\n");
	    Dialog.addString("Other notes:", "", 30);
	    
	    // Use self-defined function to set the size and position of images and dialogue
	    set_TabsSizeAndPosition();
	    
		// Show the dialogue (if "Cancel" is selected it stops the script)
	    Dialog.show();
	    
	    // Retrieve values from dialogue - order MUST match order they were added
	    imageChoice = Dialog.getRadioButton();
	    needsRotation = Dialog.getCheckbox();
	    tissueRip = Dialog.getCheckbox();
	    bloodVessel = Dialog.getCheckbox();
	    edgeArtefact = Dialog.getCheckbox();
		notes = Dialog.getString();
		
		// If no image was chosen, repeat the review
		if (imageChoice == "") {
			repeatReview = true;
			print("✱ Best image wasn't chosen, repeating the review ...");
		} else {repeatReview = false;}
	}
	
////// IMAGE CHOICE CSV FILE
	// Create the output filename
	choiceOutputName = imageChoice_prefix + baseName + ".csv";
	choiceOutputPath = imageDir + choiceOutputName;
	
	// Create and open CSV file for writing
	f = File.open(choiceOutputPath);
	
	// Write the true name distinguisher string
	if (imageChoice == "Image 1") {print(f, trueNameForImage1);}
	else {print(f, trueNameForImage2);}
	
	// Close the file
    File.close(f);
    print("✅ Image choice saved to: " + choiceOutputPath);
//////
	
////// INSTRUCTIONS TEXTFILE
	// If any box ticked or notes written ...
	if (needsRotation || tissueRip || bloodVessel || edgeArtefact || notes != "") {
		
		// Create the output filename
        instructionsOutputName = instructions_prefix + baseName + ".txt";
        instructionsOutputPath = imageDir + instructionsOutputName;
        
		// Create and open text file for writing
        f = File.open(instructionsOutputPath);
        
        // Write instructions in the text file
        print(f, "Reviewer's instructions:");
        print(f, "---------------------------------");
        if (needsRotation) print(f, "- Needs to be rotated");
        if (tissueRip)  print(f, "- Exclude tissue rips");
        if (bloodVessel) print(f, "- Exclude large blood vessels");
        if (edgeArtefact)  print(f, "- Exclude edge artefacts");
        if (notes != "") {
            print(f, "");
            print(f, "Additional Notes:");
            print(f, notes);
        }
        
        // Close the file
        File.close(f);
        print("✅ Instructions saved to: " + instructionsOutputPath);
	}
	
	// Else no box ticked or notes written ...
	else {
		
		// Create the output filename
        instructionsOutputName = empty_prefix + baseName + ".txt";
        instructionsOutputPath = imageDir + instructionsOutputName;
        
        // Create and open text file 
        f = File.open(instructionsOutputPath);
        
        // Close the file (this creates an empty file)
        File.close(f);
        print("✅ Empty file saved to: " + instructionsOutputPath);
	}
//////
	
	// Close all image windows to move on to the next one
	close("*");
}

// --- Set Tabs Sizes And Positions Func (consistent across samples + computer screens) ---
function set_TabsSizeAndPosition() {
	
	// IMAGE SIZE LOGIC //
	// Image actual (not screen) height-to-width ratio (doesn't matter which image active as dimensions identical)
	height_to_width = getHeight() / getWidth();
	
	// Calculate the screen height for the maximum screen width that allows for three gaps, each 1% of screen width
	newWidth = screenWidth * 0.485;
	newHeight = newWidth * height_to_width;
	
	// If resulting height exceeds 65% of screen height, set height to that threshold and scale width proportionally
	if (newHeight > screenHeight * 0.7) {
	    scaleFactor = (screenHeight * 0.7) / newHeight;
	    newWidth = newWidth * scaleFactor;
	    newHeight = newHeight * scaleFactor;
	}
	
	// IMAGE POSITIONING LOGIC //
	// Common y position
	PositionY = screenHeight * 0.02;
	
	// Calculate the total empty gap space on the screen's width
	totalWidthGapSpace = screenWidth - (newWidth * 2);
	
	// Calculate the single gap space for 3 gaps: 2 between screen edges + 1 between images
	singleWidthGap = totalWidthGapSpace / 3;
	
	// Image 1 position - left
	selectWindow("Image 1");
	Image1_PositionX = singleWidthGap;
	
	// Set image 1 size and position
	setLocation(Image1_PositionX, PositionY, newWidth, newHeight);
	
	// Image 2 position - right
	selectWindow("Image 2");
	Image2_PositionX = singleWidthGap + newWidth + singleWidthGap;
	
	// Set image 2 size and position
	setLocation(Image2_PositionX, PositionY, newWidth, newHeight);
	
	// DIALOGUE POSITIONING LOGIC //
	// Calculate dialogue y position
	DIALOGUE_PositionY = PositionY + newHeight + (screenHeight * 0.015);
	
	// Set dialogue position
	Dialog.setLocation((screenWidth / 2), DIALOGUE_PositionY);
}

