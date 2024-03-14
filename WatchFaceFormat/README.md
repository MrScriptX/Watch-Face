# Watch Faces Format

## Build scripts

The given build script are for windows only for now. Maybe more will come soon.

There are currently 2 ways of building a watch face. Either using the batch file which should work without additional tools or using Xmake (recommanded).

### Dependencies (xmake & batch)

You will need a bunch of tools to create a Watch Face using this format.

1. First you will need to install Android SDK 33 (min version). It can be easily found in the SDK Manager of Android Studio.
2. Download AAPT2 (a jar file) and extract it in a folder where you store android tools.
3. Download Bundletool, put it in the same folder. You don't need to extract it (yeah, Google consistency)
4. Download DWF Validator, and you guessed it, in the same folder.
5. (optional) You can install xmake if you want to make your life easier.

Now, there are a bunch of environments variables to setup. 

- **AAPT2** : Path to aapt2 (not the folder, the path of the tool itself).
- **ANDROID_JAR** : Path to android.jar. Can be found in the SDK folder.
- **BUNDLETOOL** : Path to bundletool. Same as AAPT2.
- **ANDROID_HOME** : Path to Android SDK.
- **DWF_VALIDATOR** : Path to dwf validator.

There you go, you have a fully setup environment isn't that nice ! Not so hard is it.

### Xmake (recommended)
 
Using this tool is pretty straight foward. Copy the [xmake.lua](xmake.lua) file next to your watch face directory (not inside).
Open it with your favorite code editor. There are some changes to make.

Remplace all instance of `SimpleDigital` with your watch face directory name.

Now you can compile and run your watch face.

- To check for errors : **I haven't found a way to do this yet**. The error checking is done during the build.
- To build : `$ xmake build`
- To run : `$ xmake run`

### Batch

Now the bothersome way. You don't want to make your life easier, do you ? Anyways, here is how it works.

Copy the following scripts next to your watch face folder :  [build.bat](build.bat), [run.bat](run.bat), [validate.bat](validate.bat).

- Error checking : `$ validate.bat .\your_watchface_folder`
- Building : `$ build.bat .\your_watchface_folder`
- Run : `$ run.bat .\your_watchface_folder`

Simple enough.

### Contributions

Feel free to open an issue or to submit changes to this README or to the scripts. They are NOT cleaned or optimized in anyway. I just copied the one provided by Google (but that didn't work on Windows), and rewrote them in batch and in Xmake lang (if that makes any sens).

