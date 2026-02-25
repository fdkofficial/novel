import urllib.request
import zipfile
import os
import sys

flutter_url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip"
zip_path = "flutter.zip"
extract_dir = "C:\\flutter_sdk"

if not os.path.exists(extract_dir):
    os.makedirs(extract_dir)

print("Downloading Flutter...")
urllib.request.urlretrieve(flutter_url, zip_path)

print("Extracting Flutter (this will take a while)...")
with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall(extract_dir)

print("Done installing Flutter. It is located at C:\\flutter_sdk\\flutter")
