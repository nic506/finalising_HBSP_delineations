import os
import shutil
import random


def distribute_files_randomly(source_dir, n):

    # Check source directory exists
    if not os.path.isdir(source_dir):
        raise ValueError(f"Source directory '{source_dir}' does not exist.")

    # List filepaths of files/folders to move (accounting for previous distribution folder)
    reserved_names = {str(i) for i in range(1, n + 1)}
    filepaths_to_move = [os.path.join(source_dir, f) for f in os.listdir(source_dir) if f not in reserved_names]
    print(f"📂 Found {len(filepaths_to_move)} filepaths to move.")

    # Create n output folders named 1...n
    output_folder_paths = []
    for i in range(1, n + 1):
        folder_path = os.path.join(source_dir, str(i))
        os.makedirs(folder_path, exist_ok=True)
        output_folder_paths.append(folder_path)

    # Shuffle filepath list for randomness
    random.shuffle(filepaths_to_move)

    # Distribute cyclically
    for index, filepath in enumerate(filepaths_to_move):
        dest_folder = output_folder_paths[index % n]
        shutil.move(filepath, dest_folder)
        print(f"Moved: {filepath} -> {dest_folder}")

    print("\n✅ Distribution complete!")


if __name__ == "__main__":
    source = input("Enter source directory path: ").strip()
    n = int(input("Enter number of folders to create: "))

    distribute_files_randomly(source, n)