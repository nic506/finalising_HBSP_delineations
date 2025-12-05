import argparse
import os


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--which_brain", type=int)
    parser.add_argument("--output_dir")
    args = parser.parse_args()



    ### OUTPUT FILE NEEDS TO BE THE STUDENT ONLY CHAN2 DRIVE ###



    pooled_HBSP_rootDir = r"Z:\HBSP\pooled_delineation_data"
    brain_folder_name = "HBSP_Brain" + str(args.which_brain)

    channelCombinations = ["PSD95_PSD93_GLUN1", "PSD95_GLUA2_GLUN1", "GEPH", "GLUN1_GLUA2", "VGLUT_VGAT"]

    for i in channelCombinations:
        baseDir = os.path.join(pooled_HBSP_rootDir, brain_folder_name, i)
        for j in os.listdir(baseDir):
            if os.path.isdir(j):
                current_core_dir = os.path.join(baseDir, j)

                # if csv file contains ERROR - put in error folder

                # if csv file has either new_regist or old_regist AND text file beginning with Empty - put in fine-to-be-analysed folder
                # will have to grab specific new_regist or old_regist delineation stuff (the stuff needed for running pipeline)

                # if csv file has either new_regist or old_regist AND text file beginning with Instructions - put in folder for students
                # will have to grab specific new_regist or old_regist delineation stuff (the stuff needed for students to make manual adjustments)

                # else print unclassified folder for manual checking




            else:
                print(f"Poo")
                continue


