

// --- Main ---
macro "Review Montages" {
	
	// --- Configuration ---
	distinguisher_names = "adjusted"; // options are: "regist" or "adjusted"
	pull_up_prev_instructions = true;
	randomise_blind_images = false;
	dialgoue_wait_for_user = false;
	setBatchMode(false);
	
	// Set imageChoice and instructions prefixes
	if (pull_up_prev_instructions) {
		imageChoice_prefix = "ImageChoice2  ";
		instructions_prefix = "Instructions2  ";
		empty_prefix = "Empty2  ";
		prev_instructions_prefix = "Instructions  ";
	} 
	else {
		imageChoice_prefix = "ImageChoice  ";
		instructions_prefix = "Instructions  ";
		empty_prefix = "Empty  ";
	} 
	
	close("*");
	print("\\Clear");
	print("move me");
	waitForUser("",
	    "\nPrepare Your Screen For Reviewing:"
	    + "\n "
	    + "\n(1) Move the Log window to the bottom-left corner of the screen."
	    + "\n(2) Hide all other application windows except Fiji."
	    + "\n "
	);
	
	while (true) {
		//baseDir = getDirectory("Choose base directory");
		baseDir = getString("Enter base directory:", "");
		if (!endsWith(baseDir, "\\")) {baseDir = baseDir + "\\";}
		
		close("*");
		print("\\Clear");
		print("--- Base Directory: " + File.getName(baseDir) + " ---");
	    processDirectory(baseDir);
	    split_path = split(baseDir, "\\");
	    print("\n🎉 Reviewing Complete: " + baseDir);
	    
	    logContent = getInfo("log");
	    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	    timeStamp = "" + year + "-" + month + "-" + dayOfMonth + "-" + hour + "-" + minute + "-" + second + "-" + msec;
	    logFilePath = baseDir + "Review_Log(" + timeStamp + ").txt";
	    File.saveString(logContent, logFilePath);
	}
}

// --- Process Directory Func ---
function processDirectory(dir) {
	
	// Loop over directories in dir
	folders = getFileList(dir);
	for (i = 0; i < folders.length; i++) {
	    if (File.isDirectory(dir + folders[i])) {
	        folderPath = dir + folders[i];
	        print("\nProcessing folder: " + folderPath);
	        
	        // Skip folder if already reviewed this round 
            filesInFolder = getFileList(folderPath);
            shouldSkip_imageChoice_check = false;
            shouldSkip_instructions_check = false;
            prev_instructions_filepath = newArray(0);
            for (k = 0; k < filesInFolder.length; k++) {
                fileName = filesInFolder[k];
                if (startsWith(fileName, imageChoice_prefix) && endsWith(fileName, ".csv")) {
                    shouldSkip_imageChoice_check = true;
                }
                if ((startsWith(fileName, instructions_prefix) || startsWith(fileName, empty_prefix)) && endsWith(fileName, ".txt")) {
                    shouldSkip_instructions_check = true;
					instructions_filepath = Array.concat(instructions_filepath, folderPath + fileName);
                }
                if (pull_up_prev_instructions) {
	                if (startsWith(fileName, prev_instructions_prefix) && endsWith(fileName, ".txt")) {
						prev_instructions_filepath = Array.concat(prev_instructions_filepath, folderPath + fileName);
	                }
                }
            }
			if (shouldSkip_instructions_check && shouldSkip_imageChoice_check) {
                print("✱ Already reviewed, skipping folder: " + folderPath);
                continue;
            }
            
			// Define distinguisher names 
			if (distinguisher_names == "regist") {
            	distinguisher1 = "old_regist";
				distinguisher2 = "new_regist";
			} 
			else if (distinguisher_names == "adjusted") {
            	distinguisher1 = "adjusted";
			    if (File.exists(folderPath + "new_regist" + File.separator)) {distinguisher2 = "new_regist";} 
			    else if (File.exists(folderPath + "old_regist" + File.separator)) {distinguisher2 = "old_regist";}
			    else {
			    	print("❌ Neither 'old_regist' or 'new_regist' folder exists in " + folderPath);
			    	continue;
			    }
			} 
			else {
			    print("❌ Unrecognized distinguisher_names string, stopping script");
			    break;
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
                		if (endsWith(fileNameSub, ".png") && indexOf(fileNameSub, distinguisher1) >= 0 && startsWith(fileNameSub, "RoiOverlay_Composite")) {
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
						if (endsWith(fileNameSub, ".png") && indexOf(fileNameSub, distinguisher2) >= 0 && startsWith(fileNameSub, "RoiOverlay_Composite")) {
                    		path2 = Array.concat(path2, subfolderPath + fileNameSub);
                		}
                	}
                }
	        }
	        
	        // Check exactly one image for each distinguisher and print instructions from previous review round
	        if (path1.length == 1 && path2.length == 1) {
				print("... Reviewing images: " + File.getName(path1[0]) + " + " + File.getName(path2[0]));
    			if (pull_up_prev_instructions) {
		            if (prev_instructions_filepath.length == 1) {
		            	inst_text = File.openAsString(prev_instructions_filepath[0]);
						trunc_inst_text = substring(inst_text, indexOf(inst_text, "\n") + 1, lastIndexOf(inst_text, "\n"));
						print("------------------------------");
						print(trunc_inst_text);
						print("------------------------------");
		            } 
		            else {
		                print("❌ Exactly one previous-instructions textfile NOT found in: " + folderPath);
		                continue;
		            }
				}
                reviewImages(path1[0], path2[0], folderPath, baseName);
            } 
            else {
                print("❌ Exactly one image NOT found for each distinguisher string in: " + folderPath + "check the correct distinguisher_names is configured");
            }
	    }
	}
}

// --- Dual Image Review Func ---
function reviewImages(path1, path2, imageDir, baseName) {
	
	// Open images and randomise (or not) their titles
	if (randomise_blind_images) {
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
	    
        question = "  Which image is better?";
	    choices = newArray("", "Image 1", "Image 2", "ERROR");
	} 
	else {
        open(path1);
        selectWindow(getTitle()); run("Rename...", "title=" + distinguisher1);
    	open(path2);
        selectWindow(getTitle()); run("Rename...", "title=" + distinguisher2);
        
        question = "  Is student adjusted ok?";
        choices = newArray("", "", "yes", "no");
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
		Dialog.addRadioButtonGroup(question, choices, 1, 4, "");
		
		// Section 2: Quality checks
	  	Dialog.addMessage("\n");
	  	Dialog.addMessage("Quality checks:");
		Dialog.addCheckboxGroup(
		    2, 3,
		    newArray(
		    	"Needs rotating", "Needs shifting", "Needs scaling",
		    	"Rip artefact", "Vessel artefact", "Edge artefact"
		    ),
		    newArray(false, false, false, false, false, false)
		);
	    Dialog.addString("Other notes:", "", 30);
	    
	    // Use self-defined function to set the size and position of images and dialogue
	    set_TabsSizeAndPosition();
	    
		// Show the dialogue (if "Cancel" is selected it stops the script)
	    Dialog.show();
	    
	    // Retrieve values from dialogue - order MUST match order they were added
	    imageChoice = Dialog.getRadioButton();
	    needsRotation = Dialog.getCheckbox();
	    needsShifting = Dialog.getCheckbox();
	    needsScaling = Dialog.getCheckbox();
	    ripArtefact = Dialog.getCheckbox();
	    vesselArtefact = Dialog.getCheckbox();
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
	if (randomise_blind_images) {
		if (imageChoice == "Image 1") {print(f, trueNameForImage1);}
		else if (imageChoice == "Image 2") {print(f, trueNameForImage2);}
		else {print(f, "ERROR");}
	}
	else {
		if (imageChoice == "yes") {print(f, "OK");}
		else {print(f, "ERROR");}
	}
	
	// Close the file
    File.close(f);
    print("✅ Image choice saved to: " + choiceOutputPath);
//////
	
////// INSTRUCTIONS TEXTFILE
	// If any box ticked or notes written ...
	if (needsRotation || needsShifting || needsScaling || ripArtefact || vesselArtefact || edgeArtefact || notes != "") {
		
		// Create the output filename
        instructionsOutputName = instructions_prefix + baseName + ".txt";
        instructionsOutputPath = imageDir + instructionsOutputName;
        
		// Create and open text file for writing
        f = File.open(instructionsOutputPath);
        
        // Write instructions in the text file
        if (needsRotation || needsShifting || needsScaling || ripArtefact || vesselArtefact || edgeArtefact) {
        	print(f, "");
        	print(f, "Adjust ROIs as follows:");
        }
        if (needsRotation) print(f, "\t- Rotate (CW or CCW)");
        if (needsShifting) print(f, "\t- Shift in x,y");
        if (needsScaling) print(f, "\t- Scale (enlarge or minimise)");
        if (ripArtefact)  print(f, "\t- Exclude tissue rips");
        if (vesselArtefact) print(f, "\t- Exclude large blood vessels");
        if (edgeArtefact)  print(f, "\t- Exclude bright edges");
        if (notes != "") {
            print(f, "");
            print(f, "Notes:");
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
	if (newHeight > screenHeight * 0.68) {
	    scaleFactor = (screenHeight * 0.68) / newHeight;
	    newWidth = newWidth * scaleFactor;
	    newHeight = newHeight * scaleFactor;
	}
	
	// IMAGE POSITIONING LOGIC //
	// Common y position
	PositionY = screenHeight * 0.005;
	
	// Calculate the total empty gap space on the screen's width
	totalWidthGapSpace = screenWidth - (newWidth * 2);
	
	// Calculate the single gap space for 3 gaps: 2 between screen edges + 1 between images
	singleWidthGap = totalWidthGapSpace / 3;
	
	// First image position - left
	if (randomise_blind_images) {selectWindow("Image 1");}
	else {selectWindow(distinguisher1);}
	Image1_PositionX = singleWidthGap;
	
	// Set image 1 size and position
	setLocation(Image1_PositionX, PositionY, newWidth, newHeight);
	
	// Second 2 position - right
	if (randomise_blind_images) {selectWindow("Image 2");}
	else {selectWindow(distinguisher2);}
	Image2_PositionX = singleWidthGap + newWidth + singleWidthGap;
	
	// Set image 2 size and position
	setLocation(Image2_PositionX, PositionY, newWidth, newHeight);
	
	// DIALOGUE POSITIONING LOGIC //
	// Calculate dialogue y position
	DIALOGUE_PositionY = PositionY + newHeight + (screenHeight * 0.00001);
	
	// Set dialogue position
	Dialog.setLocation((screenWidth / 2), DIALOGUE_PositionY);
}

