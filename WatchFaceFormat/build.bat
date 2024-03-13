@echo off
set JAVA="java"
set INPUT_ROOT=%1
set DEST_AAB="%INPUT_ROOT%/out/mybundle.aab"
set DEST_APK="%INPUT_ROOT%/out/mybundle.apk"

FOR /F "tokens=* USEBACKQ" %%F IN (`xmllint --xpath "string(//manifest/@package)" "%INPUT_ROOT%/AndroidManifest.xml"`) DO (
  SET PACKAGE_NAME=%%F
)

:: check if the environment is well set
IF [%ANDROID_HOME%] == [] (
  echo "Error: ANDROID_HOME not defined, please set and try again"
  exit 1
)

IF [%AAPT2%] == [] (
  echo "Error: AAPT2 not defined, please set and try again"
  echo "e.g. <sdk-path>/build-tools/<version>/aapt2"
  exit 1
)

IF [%ANDROID_JAR%] == [] (
  echo "Error: ANDROID_JAR not defined, please set and try again"
  echo "e.g. <sdk-path>/platforms/android-<version>/android.jar"
  exit 1
)

IF [%BUNDLETOOL%] == [] (
  echo "Error: Bundletool is required to run this script"
  echo "See: https://developer.android.com/tools/bundletool for more details on bundletool"
  echo "or on a Mac, use 'brew install bundletool'"
  exit 1
)

:: cleaning previous build
rm -rf "%INPUT_ROOT%/out"
mkdir "%INPUT_ROOT%/out"
mkdir "%INPUT_ROOT%/out/compiled_resources"

echo COMPILING...
"%AAPT2%" compile --dir "%INPUT_ROOT%/res" -o "%INPUT_ROOT%/out/compiled_resources/"

setlocal enabledelayedexpansion
FOR /f tokens^=* %%i IN ('where /r "%INPUT_ROOT%\out\compiled_resources" "*.flat"') DO (
  set COMPILED_FILES=!COMPILED_FILES! %%~dpi%%~nxi
)

echo LINKING...
"%AAPT2%" link --proto-format -o "%INPUT_ROOT%/out/base.apk" -I "%ANDROID_JAR%" --manifest "%INPUT_ROOT%/AndroidManifest.xml" -R !COMPILED_FILES! --auto-add-overlay --rename-manifest-package "%PACKAGE_NAME%" --rename-resources-package "%PACKAGE_NAME%"

endlocal

echo REPACK...
unzip -q "%INPUT_ROOT%/out/base.apk" -d "%INPUT_ROOT%/out/base-apk/"

mkdir "%INPUT_ROOT%/out/aab-root/base/manifest/"

cp "%INPUT_ROOT%/out/base-apk/AndroidManifest.xml" "%INPUT_ROOT%/out/aab-root/base/manifest/"
cp -r "%INPUT_ROOT%/out/base-apk/res" "%INPUT_ROOT%/out/aab-root/base"
cp "%INPUT_ROOT%/out/base-apk/resources.pb" "%INPUT_ROOT%/out/aab-root/base"

:: keep current working dir because we will cd, ask google eng why
set ROOT_PATH=%cd%
cd "%INPUT_ROOT%/out/aab-root/base" && zip ../base.zip -q -r -X .
cd %ROOT_PATH%

java -jar "%BUNDLETOOL%" build-bundle --modules="%INPUT_ROOT%/out/aab-root/base.zip" --output="%DEST_AAB%"

IF NOT [%DEST_APK%] == [] (
  echo BUILDING APKs...

  IF EXIST "%INPUT_ROOT%/out/result.apks" rm "%INPUT_ROOT%/out/result.apks"

  java -jar "%BUNDLETOOL%" build-apks --bundle="%DEST_AAB%" --output="%INPUT_ROOT%/out/mybundle.apks" --mode=universal

  unzip "%INPUT_ROOT%/out/mybundle.apks" -d "%INPUT_ROOT%/out/result_apks/"

  cp "%INPUT_ROOT%/out/result_apks/universal.apk" "%DEST_APK%"

  echo SUCCEED !
  exit 0
)

echo Not building. End.
