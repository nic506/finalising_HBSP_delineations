import os
import shutil


SOURCE_ROOT = r"Y:\student_modifications"
TARGET_ROOT = r"Z:\HBSP\pooled_delineation_data\pooled_reviewing_output\modified"
MATCH_SUBSTRINGS = ["adjusted", ".zip"]

target_index = {}
for target_entry in os.scandir(TARGET_ROOT):
    if target_entry.is_dir():
        target_index[target_entry.name] = os.path.join(target_entry.path, "adjusted")
print(f"📋 {len(target_index)} target folders")

source_count = 0
for subdir in os.scandir(SOURCE_ROOT):
    if not subdir.is_dir():
        continue

    for source_entry in os.scandir(subdir.path):
        if not source_entry.is_dir():
            continue
        source_count += 1

        source_entry_name = source_entry.name
        source_entry_path = source_entry.path

        if source_entry_name in target_index:
            target_path = target_index[source_entry_name]

            adjusted_roiset_matches = []
            for file in os.scandir(source_entry_path):
                if all(sub in file.name.lower() for sub in MATCH_SUBSTRINGS):
                    adjusted_roiset_matches.append(file)

            if len(adjusted_roiset_matches) == 1:
                os.makedirs(target_path, exist_ok=True)
                shutil.copy2(adjusted_roiset_matches[0].path, target_path)
            else:
                print(f"{len(adjusted_roiset_matches)} file matches found for {source_entry_path}, expected 1")

        elif "error" in source_entry_name.lower():
            print(f"🚩 ERROR ASSIGNED FOLDER: {source_entry_path}")

        else:
            print(f"Unmatched {source_entry_path}")

print(f"📋 {source_count} source folders")