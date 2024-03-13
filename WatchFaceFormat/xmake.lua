rule("apk")
    set_extensions(".xml")

    on_build_file(function (target, source, opt)
        import("utils.progress")
        import("lib.detect.find_program")

        progress.show(0, "${cyan}checking for requirements...")

        local ANDROID_HOME = os.getenv("ANDROID_HOME")
        if not ANDROID_HOME then
            cprint("${red}Error: ANDROID_HOME not defined, please set and try again")
           os. exit(-1)
        end

        local AAPT2 = os.getenv("AAPT2")
        if not AAPT2 then
            cprint("${red}Error: AAPT2 not defined, please set and try again")
            os.exit(-1)
        end

        local ANDROID_JAR = os.getenv("ANDROID_JAR")
        if not ANDROID_JAR then
            cprint("${red}Error: ANDROID_JAR not defined, please set and try again")
            os.exit(-1)
        end

        local BUNDLETOOL = os.getenv("BUNDLETOOL")
        if not BUNDLETOOL then
            cprint("${red}Error: BUNDLETOOL not defined, please set and try again")
            os.exit(-1)
        end

        local DWF_VALIDATOR = os.getenv("DWF_VALIDATOR")
        if not DWF_VALIDATOR then
            cprint("${red}Error: DWF_VALIDATOR not defined, please set and try again")
            os.exit(-1)
        end

        local input_dir = path.directory(source)
        local out_dir = path.join(input_dir, "out")
        local compiled_res_dir = path.join(out_dir, "compiled_resources")

        progress.show(10, "${cyan}validating watchface.xml...")

        local watchface = path.join(input_dir, "res/raw/watchface.xml")
        os.exec("java -jar %s 1 %s", DWF_VALIDATOR, watchface)

        -- creating build directory
        os.rm(target:targetdir())

        os.mkdir(out_dir)
        os.mkdir(compiled_res_dir)

        -- compiling resource files
        progress.show(15, "${cyan}compiling resources...")

        os.exec("%s compile --dir %s -o %s", AAPT2, path.join(input_dir, "res"), compiled_res_dir)

        -- linking
        progress.show(20, "${cyan}linking...")

        local compiled_files = ""
        for _, filepath in ipairs(os.files(path.join(compiled_res_dir, "*.flat"))) do
            compiled_files = format("%s %s", compiled_files, filepath)
        end

        local PACKAGE_NAME, _ = os.iorun("xmllint --xpath string(//manifest/@package) %s", source)
        printf("INFO: package name %s", PACKAGE_NAME)

        os.exec("%s link --proto-format -o %s -I %s --manifest %s -R %s --auto-add-overlay --rename-manifest-package %s --rename-resources-package %s",
            AAPT2, path.join(out_dir, "base.apk"), ANDROID_JAR, source, compiled_files, PACKAGE_NAME, PACKAGE_NAME)
        
        -- repack
        progress.show(30, "${cyan}repacking resources...")

        os.exec("unzip -q %s -d %s", path.join(out_dir, "base.apk"), path.join(out_dir, "base-apk"))

        local MANIFEST_DIR = path.join(out_dir, "aab-root/base/manifest/")
        os.mkdir(MANIFEST_DIR)
        os.cp(path.join(out_dir, "base-apk/AndroidManifest.xml"), MANIFEST_DIR)
        os.cp(path.join(out_dir, "base-apk/res"), path.join(out_dir, "aab-root/base"))
        os.cp(path.join(out_dir, "base-apk/resources.pb"), path.join(out_dir, "aab-root/base"))

        local save_dir = vformat("$(curdir)")
        os.cd(path.join(out_dir, "aab-root/base"))
        os.exec("zip ../base.zip -q -r -X .")
        os.cd(save_dir)

        local DEST_AAB = path.join(out_dir, "mybundle.aab")
        os.exec("java -jar %s build-bundle --modules=%s/aab-root/base.zip --output=%s", BUNDLETOOL, out_dir, DEST_AAB)

        -- generating apk
        progress.show(80, "${cyan}generating apks...")

        local DEST_APK = path.join(out_dir, "mybundle.apk")

        local result_apk = path.join(out_dir, "result.apks")
        if os.exists(result_apk) then
            os.rm(result_apk)
        end

        os.exec("java -jar %s build-apks --bundle=%s --output=%s/mybundle.apks --mode=universal", BUNDLETOOL, DEST_AAB, out_dir)
        os.exec("unzip %s/mybundle.apks -d %s/result_apks/", out_dir, out_dir)
        os.cp(path.join(out_dir, "result_apks/universal.apk"), DEST_APK)
    end)

    on_run(function (target)
        print(target:filename())
        print(target:targetfile())
        local target_file_path = path.join(target:targetdir(), "result_apks", target:filename())
        os.exec("adb install %s", target_file_path)
    end)
    
    on_clean(function (target)
        os.rm(target:targetdir())
    end)

target("SimpleDigital")
    set_kind("object")
    set_targetdir("SimpleDigital/out")
    set_filename("universal.apk")

    add_rules("apk")

    add_files("SimpleDigital/AndroidManifest.xml")

    on_run(function (target)
        local target_file_path = path.join(target:targetdir(), "result_apks", "universal.apk")
        os.exec("adb install %s", target_file_path)
    end)
