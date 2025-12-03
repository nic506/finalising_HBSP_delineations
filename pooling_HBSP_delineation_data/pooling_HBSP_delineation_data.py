import argparse
import os
import shutil
import subprocess


def get_filepaths(HBSP_root_dirs, which_brain, which_nas):

    brain_folder_name = "HBSP_Brain" + str(which_brain)

    if which_nas == 2:
        root_dir = os.path.join(HBSP_root_dirs, "HBSP_Brains_1-6", brain_folder_name)
        channels_dirs = ({
            "PSD95_PSD93_GLUN1": os.path.join(root_dir, "PSD95_PSD93_GluN1"),
            "PSD95_GLUA2_GLUN1": os.path.join(root_dir, "PSD95_GLUA2_GLUN1"),
            "GEPH": os.path.join(root_dir, "GEPH_CY5"),
        })
    elif which_nas == 3:
        root_dir = os.path.join(HBSP_root_dirs, "HBSP_Brain1-6", brain_folder_name)
        channels_dirs = ({
            "GLUN1_GLUA2": os.path.join(root_dir, "GLUN1_GLUA2"),
            "VGLUT_VGAT": os.path.join(root_dir, "VGLUT_VGAT_AF568"),
        })
    else:
        print("Unidentified NAS drive")

    print(f"\n\n----- PROCESSING NAS DRIVE {which_nas} -----\n")

    filepath_dict = {channel: {} for channel in channels_dirs}

    for channel, channel_dir in channels_dirs.items():
        core_id_list = []

        print(f"\nFinding filepaths for channel {channel} ...")

        # go into 'Nissl' folder
        nissl_dir_filepath = os.path.join(channel_dir, "Nissl")
        if not os.path.exists(nissl_dir_filepath):
            print(f"Delineation output 'Nissl' folder not found for {channel}")
            continue
        for dir_1_entry in os.listdir(nissl_dir_filepath):
            dir_1_filepath = os.path.join(nissl_dir_filepath, dir_1_entry)
            if os.path.isdir(dir_1_filepath):
                split_dir_1_name = dir_1_entry.split("_")

                # get core IDs
                core_id = "_" + "_".join(split_dir_1_name[2:4]) + "_"
                if core_id in core_id_list:
                    print(f"Core ID {core_id} is duplicated in {channel}, the final duplicate will overwrite all other data")
                core_id_list.append(core_id)
                filepath_dict[channel][core_id] = {}

                # loop over old and new registration versions
                for registration_version in ["old", "new"]:
                    dir_2_base_name = "_".join(split_dir_1_name[2:])

                    # get registered nissl
                    dir_2_nissl_name_matches = [f for f in os.listdir(dir_1_filepath) if f == dir_2_base_name]
                    if len(dir_2_nissl_name_matches) == 1:
                        dir_2_nissl_filepath = os.path.join(dir_1_filepath, dir_2_nissl_name_matches[0])
                        regist_dir_filepath = os.path.join(dir_2_nissl_filepath, "regist")
                        regist_nissl_name_matches = [f for f in os.listdir(regist_dir_filepath) if f == f"{dir_2_base_name}_regist_{registration_version}.png"]
                        if len(regist_nissl_name_matches) == 1:
                            regist_nissl_filepath = os.path.join(regist_dir_filepath, regist_nissl_name_matches[0])
                            if "regist_nissl_filepath" not in filepath_dict[channel][core_id]:
                                filepath_dict[channel][core_id]["regist_nissl_filepath"] = {}
                            filepath_dict[channel][core_id]["regist_nissl_filepath"][registration_version] = regist_nissl_filepath
                        else:
                            print(f"{len(regist_nissl_name_matches)} regist_nissl_name_matches found for {channel} in {os.path.normpath(dir_2_nissl_filepath).split(os.sep)[-2:]} for {registration_version} registration version")
                            continue
                    else:
                        print(f"{len(dir_2_nissl_name_matches)} dir_2_nissl_name_matches found for {channel} in {dir_1_filepath}")

                    # get RoiSets
                    dir_2_roiset_name_matches = [f for f in os.listdir(dir_1_filepath) if f == f"{dir_2_base_name}_regist_{registration_version}"]
                    if len(dir_2_roiset_name_matches) == 1:
                        dir_2_roiset_filepath = os.path.join(dir_1_filepath, dir_2_roiset_name_matches[0])
                        rois_name_matches = [f for f in os.listdir(dir_2_roiset_filepath) if f"RoiSet{core_id}" in f and f.endswith(".zip")]
                        if len(rois_name_matches) == 1:
                            rois_filepath = os.path.join(dir_2_roiset_filepath, rois_name_matches[0])
                            if "rois_filepath" not in filepath_dict[channel][core_id]:
                                filepath_dict[channel][core_id]["rois_filepath"] = {}
                            filepath_dict[channel][core_id]["rois_filepath"][registration_version] = rois_filepath
                        else:
                            print(f"{len(rois_name_matches)} rois_name_matches found for {channel} in {os.path.normpath(dir_2_roiset_filepath).split(os.sep)[-2:]} for {registration_version} registration version")
                            continue
                    else:
                        print(f"{len(dir_2_roiset_name_matches)} dir_2_roiset_name_matches found for {channel} in {dir_1_filepath}")

        # go into 'Montages' folder, get montages
        montage_a = os.path.join(channel_dir, "Montages")
        montage_b = os.path.join(channel_dir, "Montage_exports")
        exists_a = os.path.exists(montage_a)
        exists_b = os.path.exists(montage_b)
        if exists_a and not exists_b:
            montage_dir_filepath = montage_a
        elif exists_b and not exists_a:
            montage_dir_filepath = montage_b
        else:
            print(f"For {channel}, expected exactly one of 'Montages' or 'Montage_exports', but found {'both' if exists_a and exists_b else 'neither'}")
            continue
        num_channels = len(channel.split("_"))
        dirs_to_look_in = set()
        dirs_excluded = set()
        for dirPath, dirNames, fileNames in os.walk(montage_dir_filepath):
            dirs_to_look_in.add(dirPath)
            for d in list(dirNames):
                if any(keyword in d.lower() for keyword in ["focus", "control", "tilenum", "oof"]):
                    dirNames.remove(d)
                    dirs_excluded.add(d)
        print(f"Montage directories to look in: {[os.path.basename(p) for p in dirs_to_look_in]}")
        if dirs_excluded:
            print(f"Montage directories excluded: {dirs_excluded}")
        else:
            print(f"No montage directories excluded")
        for core_id in core_id_list:
            montages_filepaths = []
            for dirPath in dirs_to_look_in:
                for f in os.listdir(dirPath):
                    if core_id in f:
                        montages_filepaths.append(os.path.join(dirPath, f))
            if len(montages_filepaths) == num_channels:
                filepath_dict[channel][core_id]["montage_filepaths"] = {}
                filepath_dict[channel][core_id]["montage_filepaths"] = montages_filepaths
            else:
                print(f"{len(montages_filepaths)} matches found for {core_id} in {os.path.normpath(montage_dir_filepath).split(os.sep)[-2:]}, expected {num_channels} matches")
                continue

    return filepath_dict


def make_pooled_folders(output_dir, which_brain, filepath_dict, vpn_connection):

    brain_dir = os.path.join(output_dir, "Brain" + str(which_brain))
    os.makedirs(brain_dir, exist_ok=True)

    for channel, cores_info in filepath_dict.items():
        print(f"\nCopying files for channel {channel} ...")

        channel_dir = os.path.join(brain_dir, channel)
        os.makedirs(channel_dir, exist_ok=True)

        for core_id, file_type_info in cores_info.items():
            core_id_dir = os.path.join(channel_dir, core_id)
            os.makedirs(core_id_dir, exist_ok=True)

            # create subdirectory for registration versions to store nissls and RoiSets
            for registration_version in ["old", "new"]:
                registration_version_dir = os.path.join(core_id_dir, registration_version + "_regist")
                os.makedirs(registration_version_dir, exist_ok=True)

                # copy RoiSets
                if "rois_filepath" in file_type_info:
                    rois_src = file_type_info["rois_filepath"][registration_version]
                    rois_dst = os.path.join(registration_version_dir, "COPY_" + os.path.basename(rois_src))
                    if not os.path.exists(rois_dst):
                        if vpn_connection == False:
                            shutil.copy2(rois_src, rois_dst)
                        else:
                            robust_copy_for_vpn_nas_connection(rois_src, rois_dst)
                    else:
                        print(f"{channel} {os.path.normpath(rois_dst).split(os.sep)[-3:]} already exists, skipping.")

                # copy registered nissl
                if "regist_nissl_filepath" in file_type_info:
                    regist_nissl_src = file_type_info["regist_nissl_filepath"][registration_version]
                    regist_nissl_dst = os.path.join(registration_version_dir, "COPY_" + os.path.basename(regist_nissl_src))
                    if not os.path.exists(regist_nissl_dst):
                        if vpn_connection == False:
                            shutil.copy2(regist_nissl_src, regist_nissl_dst)
                        else:
                            robust_copy_for_vpn_nas_connection(regist_nissl_src, regist_nissl_dst)
                    else:
                        print(f"{channel} {os.path.normpath(regist_nissl_dst).split(os.sep)[-3:]} already exists, skipping.")

            # copy montages
            if "montage_filepaths" in file_type_info:
                for montage_src in file_type_info["montage_filepaths"]:
                    montage_dst = os.path.join(core_id_dir, "COPY_" + os.path.basename(montage_src))
                    if not os.path.exists(montage_dst):
                        if vpn_connection == False:
                            shutil.copy2(montage_src, montage_dst)
                        else:
                            robust_copy_for_vpn_nas_connection(montage_src, montage_dst)
                    else:
                        print(f"{channel} {os.path.normpath(montage_dst).split(os.sep)[-2:]} already exists, skipping.")


def robust_copy_for_vpn_nas_connection(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    try:
        subprocess.run(
            ["rsync", "-a", "--partial", src, dst], # add --progress before 'src' to show progress
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"❌ rsync failed for {src} → {dst}: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--which_brain", type=int)
    parser.add_argument("--output_dir")
    parser.add_argument("--vpn_connection", action='store_true')
    args = parser.parse_args()

    Chanc2 = r"Z:\HBSP"
    Chanc3 = r"Y:\HBSP"
    HBSP_root_dirs = [Chanc2, Chanc3]

    for i in range(len(HBSP_root_dirs)):
        filepath_dict = get_filepaths(HBSP_root_dirs[i], args.which_brain, i + 2)
        montage_filepaths_dict = make_pooled_folders(args.output_dir, args.which_brain, filepath_dict, args.vpn_connection)

    # print("\n\n\n\n\n\n\n")
    #
    # print(filepath_dict["PSD95_PSD93_GluN1"])
    # print(len(filepath_dict["PSD95_PSD93_GluN1"]))
    #
    # print("\n\n\n\n\n\n\n")
    #
    # print(filepath_dict["PSD95_GLUA2_GLUN1"])
    # print(len(filepath_dict["PSD95_GLUA2_GLUN1"]["SD03216_AD"]))
    #
    # print("\n\n\n\n\n\n\n")
    #
    # print(filepath_dict["GEPH"])
    # print(len(filepath_dict["GEPH"]["SD03216_AD"]))

    print(f"\n\n----- COMPLETED SUCCESSFULLY -----\n\n")
