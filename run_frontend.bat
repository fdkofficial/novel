@echo off
echo Downloading and installing Flutter SDK if not present...
set "PATH=%PATH%;C:\flutter_sdk\flutter\bin"

IF NOT EXIST "C:\flutter_sdk\flutter\bin\flutter.bat" (
    echo Expanding flutter... Please wait up to 5 minutes...
    "C:\Users\Fardeen Khan\AppData\Local\Programs\Python\Python311\python.exe" ..\download_flutter.py
)

cd frontend
echo Running flutter pub get...
call flutter pub get

echo Starting Flutter App on available device...
call flutter run
