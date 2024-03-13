@echo off
set INPUT_ROOT=%1

adb install %INPUT_ROOT%/out/result_apks/universal.apk
