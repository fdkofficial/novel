@echo off
"C:\Users\Fardeen Khan\AppData\Local\Programs\Python\Python311\python.exe" manage.py makemigrations accounts novels reading recommendations surveys > out.txt 2>&1
"C:\Users\Fardeen Khan\AppData\Local\Programs\Python\Python311\python.exe" manage.py migrate >> out.txt 2>&1
echo Done.
