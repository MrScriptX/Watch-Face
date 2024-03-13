@echo off
set INPUT_ROOT=%1

IF [%DWF_VALIDATOR%] == [] (
    echo Error: DWF_VALIDATOR not defined, please set and try again
    echo e.g. C:\tools\android\dwf-format-1-validator-1.0.jar
    exit 1
)

java -jar %DWF_VALIDATOR% 1 %INPUT_ROOT%\res\raw\watchface.xml
