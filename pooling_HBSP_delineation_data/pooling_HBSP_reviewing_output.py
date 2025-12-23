import argparse
import os
import shutil


def check_string_csv(directory, file_list):
    for f in file_list:
        if f.endswith(".csv") and f.startswith("ImageChoice  "):
            csv_path = os.path.join(directory, f)
            with open(csv_path, "r", encoding="utf-8") as file:
                for line in file:
                    if "ERROR" in line:
                        return "ERROR"
                    if "old_regist" in line:
                        return "old_regist"
                    if "new_regist" in line:
                        return "new_regist"
            print(f"'ERROR', 'old_regist', or 'new_regist' not found in {csv_path}, skipping")
            return None
    print(f"No csvfile in {directory}, skipping")
    return None

def check_instructions_txt(directory, file_list):
    txt_file_found = False
    for f in file_list:
        if f.endswith(".txt"):
            if f.startswith("Instructions  "):
                txt_file_found = True
                return "instructions"
            elif f.startswith("Empty  "):
                txt_file_found = True
                return "empty"
    if not txt_file_found:
        print(f"No textfile in {directory}, skipping")
        return None

def get_montages_delineations_instructions_filepaths(file_list, directory, curr_core_id, number_of_channels, regist_version, empty_txt, target_dir_name):
    filepaths_to_copy = []

    # get montages - only if for modification
    if target_dir_name == "for_modification":
        montage_name_matches = [f for f in file_list if f.endswith(".tif") and "Montage" in f]
        if len(montage_name_matches) == number_of_channels:
            montage_filepaths = [os.path.join(directory, f) for f in montage_name_matches]
            filepaths_to_copy.extend(montage_filepaths)
        else:
            print(f"{len(montage_name_matches)} montage matches found for {curr_core_id} in {directory} for {target_dir_name}, expected {number_of_channels}")

    # get folder with delineations in (named old regist or new regist)
    for version in regist_version:
        delineationFolder_name_matches = [f for f in file_list if os.path.isdir(os.path.join(directory, f)) and version == f]
        if len(delineationFolder_name_matches) == 1:
            delineationFolder_filepath = os.path.join(directory, delineationFolder_name_matches[0])
            filepaths_to_copy.append(delineationFolder_filepath)
        else:
            print(f"{len(delineationFolder_name_matches)} delineation folder matches found for {curr_core_id}, {regist_version} in {directory} for {target_dir_name}, expected 1")

    # get instructions
    if not empty_txt:
        instructions_name_matches = [f for f in file_list if f.endswith(".txt") and f.startswith("Instructions  ")]
        if len(instructions_name_matches) == 1:
            instructions_filepath = os.path.join(directory, instructions_name_matches[0])
            filepaths_to_copy.append(instructions_filepath)
        else:
            print(f"{len(instructions_name_matches)} instructions matches found for {curr_core_id} in {directory} for {target_dir_name}, expected 1")

    return filepaths_to_copy

def make_ignore_func(keep_substrings):
    def ignore_func(dirpath, names):
        ignored = []
        for name in names:
            if not any(sub in name for sub in keep_substrings):
                ignored.append(name)
        return ignored
    return ignore_func

def copy_func(curr_brain, curr_channel, curr_core_id, filepaths_to_copy, outputRootDir):
    output_folder_name = curr_brain + "_" + curr_channel + curr_core_id
    outputDir = os.path.join(outputRootDir, output_folder_name)
    os.makedirs(outputDir, exist_ok=True)
    for filepath in filepaths_to_copy:
        dst = os.path.join(outputDir, os.path.basename(filepath))
        if not os.path.exists(dst):
            if os.path.isdir(filepath):
                shutil.copytree(filepath, dst, ignore=ignore_func, dirs_exist_ok=True)
            else:
                shutil.copy2(filepath, dst)
        else:
            print(f"{dst} already exists, skipping")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--rootDir")
    parser.add_argument("--outputDir")
    args = parser.parse_args()

    rootDir = args.rootDir    #Z:\HBSP\pooled_delineation_data

    brains = ["Brain1", "Brain2", "Brain3", "Brain4", "Brain5", "Brain6"]
    channelCombinations = ["PSD95_PSD93_GLUN1", "PSD95_GLUA2_GLUN1", "GEPH", "GLUN1_GLUA2", "VGLUT_VGAT"]

    error_core_filepaths = []
    modification_core_filepaths = []
    good_core_filepaths = []

    error_outputDir = os.path.join(args.outputDir, "error")
    modification_outputDir = os.path.join(args.outputDir, "for_modification")
    good_outputDir = os.path.join(args.outputDir, "good")

    ignore_func = make_ignore_func(["_Composite_", "_RoiSet_"])

    for brain in brains:
        brainDir = os.path.join(rootDir, brain)
        for channel in channelCombinations:
            channelDir = os.path.join(brainDir, channel)
            num_channels = len(channel.split("_"))
            for i in os.listdir(channelDir):
                current_iDir = os.path.join(channelDir, i)
                if os.path.isdir(current_iDir):
                    core_id = i
                    file_list = os.listdir(current_iDir)
                    OUTPUT_check_string_csv = check_string_csv(current_iDir, file_list)
                    OUTPUT_check_instructions_txt = check_instructions_txt(current_iDir, file_list)

                    target_dir = None
                    regist_versions = []
                    empty_txt = False

                    # error in csv
                    if OUTPUT_check_string_csv == "ERROR":
                        target_dir = error_outputDir
                        regist_versions = ["old_regist", "new_regist"]
                        error_core_filepaths.append(current_iDir)

                    # old or new regist in csv
                    elif OUTPUT_check_string_csv in ["old_regist", "new_regist"]:
                        regist_versions = [OUTPUT_check_string_csv]

                        # instructions txt
                        if OUTPUT_check_instructions_txt == "instructions":
                            target_dir = modification_outputDir
                            modification_core_filepaths.append(current_iDir)

                        # empty txt
                        elif OUTPUT_check_instructions_txt == "empty":
                            target_dir = good_outputDir
                            good_core_filepaths.append(current_iDir)
                            empty_txt = True

                        # else txt
                        else:
                            continue

                    # else csv
                    else:
                        continue

                    filepaths_to_copy = get_montages_delineations_instructions_filepaths(file_list, current_iDir, core_id, num_channels, regist_versions, empty_txt, os.path.basename(target_dir))
                    copy_func(brain, channel, core_id, filepaths_to_copy, target_dir)

    print(f"\nError cores: {len(error_core_filepaths)}")
    print(f"Modification cores: {len(modification_core_filepaths)}")
    print(f"Good cores: {len(good_core_filepaths)}")