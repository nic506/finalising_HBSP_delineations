

# Safely check that there are ROIs in zip path

import zipfile
import os

zip_path = getArgument()
count = 0
couldNotReadZip = False

try:
    with zipfile.ZipFile(zip_path, 'r') as z:
        roi_files = [f for f in z.namelist() if f.endswith('.roi')]
        count = len(roi_files)
except Exception:
    couldNotReadZip = True

tmp_file = os.path.join(os.path.dirname(zip_path), "roi_count.txt")
with open(tmp_file, "w") as f:
    if couldNotReadZip:
        f.write(str("ERROR"))
    else:
        f.write(str(count))
        
        