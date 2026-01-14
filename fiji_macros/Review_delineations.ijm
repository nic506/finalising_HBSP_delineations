

// --- Main ---
macro "Review Montages" {
	
	// --- Configuration (MUST LEAVE CONFIG INSIDE MAIN TO BE ABLE TO INSTALL MACRO) ---
	distinguisher_names = "adjusted"; // options are: "regist" or "adjusted" or "neuropath"
	pull_up_prev_instructions = true;
	randomise_blind_images = false;
	dialgoue_wait_for_user = false;
	var PositionY, newHeight;
	
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
	    + "\n(1) Move the Log window to the bottom-left (or bottom-right if neuropath) corner of the screen."
	    + "\n(2) Hide all other application windows except Fiji."
	    + "\n "
	);
	
	while (true) {
		//baseDir = getDirectory("Choose base directory");
		baseDir_path = getString("Enter base directory:", "");
		if (!endsWith(baseDir_path, "\\")) {baseDir_path = baseDir_path + "\\";}
		
		close("*");
		print("\\Clear");
		print("--- Base Directory: " + File.getName(baseDir_path) + " ---");
	    processDirectory(baseDir_path);
	    split_path = split(baseDir_path, "\\");
	    print("\n🎉 Reviewing Complete: " + baseDir_path);
	    
	    logContent = getInfo("log");
	    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	    timeStamp = "" + year + "-" + month + "-" + dayOfMonth + "-" + hour + "-" + minute + "-" + second + "-" + msec;
	    logFilePath = baseDir_path + "Review_Log(" + timeStamp + ").txt";
	    File.saveString(logContent, logFilePath);
	}
}

// --- Process Directory Func ---
function processDirectory(baseDir_path) {
	
	// Loop over sub directories in base dir
	baseDir_fileList = getFileList(baseDir_path);
	for (i = 0; i < baseDir_fileList.length; i++) {
		subDir_path = baseDir_path + baseDir_fileList[i];
	    if (File.isDirectory(subDir_path)) {
	        print("\nProcessing folder: " + subDir_path);
	        
	        // Skip sub directory if already reviewed this round 
            subDir_fileList = getFileList(subDir_path);
            shouldSkip_imageChoice_check = false;
            shouldSkip_instructions_check = false;
            prev_instructions_filepath = newArray(0);
            for (k = 0; k < subDir_fileList.length; k++) {
                fileName = subDir_fileList[k];
                if (startsWith(fileName, imageChoice_prefix) && endsWith(fileName, ".csv")) {
                    shouldSkip_imageChoice_check = true;
                }
                if ((startsWith(fileName, instructions_prefix) || startsWith(fileName, empty_prefix)) && endsWith(fileName, ".txt")) {
                    shouldSkip_instructions_check = true;
					instructions_filepath = Array.concat(instructions_filepath, subDir_path + fileName);
                }
                if (pull_up_prev_instructions) {
	                if (startsWith(fileName, prev_instructions_prefix) && endsWith(fileName, ".txt")) {
						prev_instructions_filepath = Array.concat(prev_instructions_filepath, subDir_path + fileName);
	                }
                }
            }
			if (shouldSkip_instructions_check && shouldSkip_imageChoice_check) {
                print("✱ Already reviewed, skipping folder: " + subDir_path);
                continue;
            }
            
			// Define distinguisher names 
			if (distinguisher_names == "regist") {
            	distinguisher1 = "old_regist";
				distinguisher2 = "new_regist";
			} 
			else if (distinguisher_names == "adjusted") {
            	distinguisher1 = "adjusted";
			    if (File.exists(subDir_path + "new_regist" + File.separator)) {distinguisher2 = "new_regist";} 
			    else if (File.exists(subDir_path + "old_regist" + File.separator)) {distinguisher2 = "old_regist";}
			    else {
			    	print("❌ Neither 'old_regist' or 'new_regist' folder exists in " + subDir_path);
			    	continue;
			    }
			} 
			else if (distinguisher_names == "neuropath") {
                distinguisher1 = "";
                distinguisher2 = "*****"; 
            }
			else {
			    print("❌ Unrecognized distinguisher_names string, stopping script");
			    break;
			}
	        
	        // Find filepaths to Roi Overlay Montage files
			path1 = newArray(0);
            path2 = newArray(0);
            baseName = "";
            for (k = 0; k < subDir_fileList.length; k++) {
                fileName = subDir_fileList[k];
                
                // Check for single neuropath image and create basename to save output file
                if (distinguisher_names == "neuropath") {
            		if (endsWith(fileName, ".png") && indexOf(fileName, distinguisher1) >= 0 && startsWith(fileName, "RoiOverlay_")) {
						path1 = Array.concat(path1, subDir_path + fileName);
                		baseName = replace(fileName, ".png", "");
						path2 = Array.concat(path2, "");                		
            		}
                }
                else {
                	// Check for distinguisher 1 image and create basename to save output file
	                if (File.isDirectory(subDir_path + fileName) && fileName == distinguisher1 + "/") {
	                	subsubDir_path = subDir_path + fileName;
	                	subsubDir_fileList = getFileList(subsubDir_path);
	                	for (j = 0; j < subsubDir_fileList.length; j++) {
	                		subFileName = subsubDir_fileList[j];
	                		if (endsWith(subFileName, ".png") && indexOf(subFileName, distinguisher1) >= 0 && startsWith(subFileName, "RoiOverlay_")) {
								path1 = Array.concat(path1, subsubDir_path + subFileName);
	                    		baseName = replace(subFileName, ".png", "");
	                    		baseName = replace(baseName, distinguisher1, "");
	                		}
	                	}
	                }
	                
	                // Check for distinguisher 2 image
	                else if (File.isDirectory(subDir_path + fileName) && fileName == distinguisher2 + "/") {
	                	subsubDir_path = subDir_path + fileName;
	                	filesInSubfolder = getFileList(subsubDir_path);
	                	for (w = 0; w < filesInSubfolder.length; w++) {
	                		subFileName = filesInSubfolder[w];
							if (endsWith(subFileName, ".png") && indexOf(subFileName, distinguisher2) >= 0 && startsWith(subFileName, "RoiOverlay_")) {
	                    		path2 = Array.concat(path2, subsubDir_path + subFileName);
	                		}
	                	}
	                }
                }
	        }
	        
	        // Check exactly one image for each distinguisher (allow single image if neuropath mode) and print instructions from previous review round
	        validPair = (path1.length == 1 && path2.length == 1);
	        validSingle = (distinguisher_names == "neuropath" && path1.length == 1);
	        if (validPair || validSingle) {
	        	msg = "... Reviewing image(s): " + File.getName(path1[0]);
				if (validPair) {msg += " + " + File.getName(path2[0]);}
				print(msg);
    			if (pull_up_prev_instructions) {
		            if (prev_instructions_filepath.length == 1) {
		            	inst_text = File.openAsString(prev_instructions_filepath[0]);
						trunc_inst_text = substring(inst_text, indexOf(inst_text, "\n") + 1, lastIndexOf(inst_text, "\n"));
						print("------------------------------");
						print(trunc_inst_text);
						print("------------------------------");
		            } 
		            else {
		                print("❌ Exactly one previous-instructions textfile NOT found in: " + subDir_path);
		                continue;
		            }
				}
                reviewImages(path1[0], path2[0], subDir_path, baseName);
            } 
            else {
                print("❌ Exactly one image NOT found for each distinguisher string in: " + subDir_path + "check the correct distinguisher_names is configured");
            }
	    }
	}
}

// --- Dual Image Review Func ---
function reviewImages(path1, path2, imageDir, baseName) {
	
	// Open images and randomise (or not) their titles, also handle single image case
    if (distinguisher_names == "neuropath") {
        open(path1);
        
        question = "  Are annotations ok?";
        choices = newArray("", "", "yes", "no");
    }
	else if (randomise_blind_images) {
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
        
        question = "  Are student adjustments ok?";
        choices = newArray("", "", "yes", "no");
	} 
	
    // Use self-defined function to set the size and position of images 
    set_imageSizeAndPosition();
    
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
	    
	    // Use self-defined function to set the size and position of dialogue
	    set_dialogueSizeAndPosition();
	    
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

// --- Set Images Sizes And Positions Func For Image Pair And Single ---
function set_imageSizeAndPosition() {
	
	// SET IMAGE SIZE AND POSITION PROPORTIONS //
	if (distinguisher_names == "neuropath") {
		max_width_proportion = 0.7;
		max_height_proportion = 0.95;
	}
	else {
		max_width_proportion = 0.485;
		max_height_proportion = 0.68;
	}
	
	// IMAGE SIZE LOGIC //
	// Image actual (not screen) height-to-width ratio (doesn't matter which image active as dimensions identical)
	height_to_width = getHeight() / getWidth();
	
	// Calculate the screen height for the maximum screen width
	newWidth = screenWidth * max_width_proportion;
	newHeight = newWidth * height_to_width;
	
	// If resulting height exceeds max_height_proportion of screen height, set height to that threshold and scale width proportionally
	if (newHeight > screenHeight * max_height_proportion) {
	    scaleFactor = (screenHeight * max_height_proportion) / newHeight;
	    newWidth = newWidth * scaleFactor;
	    newHeight = newHeight * scaleFactor;
	}
	
	// IMAGE POSITIONING LOGIC //
	// Common y position
	PositionY = screenHeight * 0.005;
	
	if (distinguisher_names == "neuropath") {
		// Set single image size and position
		PositionX = screenWidth * 0.005;
		setLocation(PositionX, PositionY, newWidth, newHeight);
	}
	else {
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
		
		// Second 2 position - right (only if not neuropath mode)
		if (randomise_blind_images) {selectWindow("Image 2");}
		else {selectWindow(distinguisher2);}
		Image2_PositionX = singleWidthGap + newWidth + singleWidthGap;
		
		// Set image 2 size and position
		setLocation(Image2_PositionX, PositionY, newWidth, newHeight);
	}
}

// --- Set Dialogue Size And Position Func ---
function set_dialogueSizeAndPosition() {
	
	// DIALOGUE POSITIONING LOGIC //
	// Calculate dialogue y position
	if (distinguisher_names == "neuropath") {DIALOGUE_PositionY = screenHeight * 0.05;}
	else {DIALOGUE_PositionY = PositionY + newHeight + (screenHeight * 0.00001);}
	
	// Set dialogue position
	Dialog.setLocation((screenWidth / 1.5), DIALOGUE_PositionY);
}

