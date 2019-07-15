#!/bin/bash

# This script was originally created by 'qgj' from askubuntu.  It has been modified
# to work using the BacklightBrighness setting available for some displays on the currrent nvidia driver
# It has also been modified to remove display specific configuration, instead applying the setting to all 
# active displays which support the BacklightBrightness setting.
# Tested only with nvidia-settings-319.12 and nvidia-drivers-331.20 on Linux Mint 17 Mate
#
# Requirements:
# - NVIDIA Drivers (e.g. nvidia-current in Ubuntu)
# - NVIDIA Settings (nvidia-settings in Ubuntu)
#
# This script can be used to change the brightness on systems with an NVIDIA graphics card
# that lack the support for changing the brightness (probably needing acpi backlight).
# It uses "nvidia-settings -a" to assign new gamma or brightness values to the display.
# 
# If this script fails, your display likely does not support the 'BacklightBrightness' option.
# In that event, execute 'nvidia-settings -n -q all' to see which options are available for the displays
#
# "nvidia-brightness.sh" may be run from the command line or can be assigned to the brightness keys on your Keyboard
# Type "nvidia-brightness.sh --help" for valid options.

if [ -z "${BASH}" ] ; then
    echo "please run this script with the BASH shell" 
    exit 1
fi

usage ()
{
cat << ENDMSG
Usage: 
   nvidia-brightness.sh [ options ]

Options:
   [ -bu ] or [ --brightness-up ]    increase brightness by 10
   [ -bu <no> ] or                   
   [ --brightness-up <no> ]          increase brightness by specified <no>

   [ -bd ] or [ --brightness-down ]  decrease brightness by 10
   [ -bd <no> ] or                   
   [ --brightness-down <no> ]        decrease brightness by specified <no>

   [ -i ]  or [ --initialize ]       Must be run once to create the settings file
                                     (~/.nvidia-brightness.cfg).
                                     Brightness settings from ~/.nvidia-settings-rc
                                     will be used if file exists, otherwise 
                                     brightness will be set to 100.
   [ -l ]  or [ --load-config ]      Load current settings from ~/.nvidia-brightness.cfg
                                     (e.g. as X11 autostart script)

Examples:
   nvidia-brightness -bd       this will decrease gamma by 10
   nvidia-brightness -bu 15    this will increase brightness by 15
ENDMSG
}

case $1 in 
    -h|--help)
        usage
        exit 0
esac

if [ "$1" != "-i" -a "$1" != "--initialize" ] ; then
    if [[ ! -f ~/.nvidia-brightness.cfg ]]; then 
        echo 'You must run this script with the --initialize option once to create the settings file.'
        echo 'Type "nvidia-brightness.sh --help" for more information.';
        exit 1
    fi
fi

#### INITIALIZE ####
initialize_cfg ()
{
    BRIGHTNESS_TEMP=100
    echo "BRIGHTNESS=$BRIGHTNESS_TEMP" > ~/.nvidia-brightness.cfg

    source ~/.nvidia-brightness.cfg
    echo "BRIGHTNESS: $BRIGHTNESS"

    # Valid BacklightBrightness values are between 0 and 100
    # Example:  nvidia-settings -n -a BacklightBrightness=80
    nvidia-settings -n -a BacklightBrightness=$BRIGHTNESS 1>/dev/null
    exit $?
}

#### LOAD CONFIGURATION ####
load_cfg ()
{
    source ~/.nvidia-brightness.cfg
    echo "BRIGHTNESS: $BRIGHTNESS"

    nvidia-settings -n -a BacklightBrightness=$BRIGHTNESS 1>/dev/null
}

#### BRIGHTNESS CHANGE ####
brightness_up ()
{
    source ~/.nvidia-brightness.cfg

    [[ -z $1 ]] && BRIGHTNESS_INC=10 || BRIGHTNESS_INC=$1
    BRIGHTNESSNEW=$(( $BRIGHTNESS + $BRIGHTNESS_INC ))
    [[ $BRIGHTNESSNEW -gt 100 ]] && BRIGHTNESSNEW=100

    sed -i  s/.*BRIGHTNESS=.*/BRIGHTNESS=$BRIGHTNESSNEW/g ~/.nvidia-brightness.cfg

    source ~/.nvidia-brightness.cfg
    echo "BRIGHTNESS: $BRIGHTNESS"

    nvidia-settings -n -a BacklightBrightness=$BRIGHTNESS 1>/dev/null
}

brightness_down ()
{
    source ~/.nvidia-brightness.cfg

    [[ -z $1 ]] && BRIGHTNESS_INC=10 || BRIGHTNESS_INC=$1
    BRIGHTNESSNEW=$(( $BRIGHTNESS - $BRIGHTNESS_INC ))
    [[ $BRIGHTNESSNEW -lt 0 ]] && BRIGHTNESSNEW=0

    sed -i  s/.*BRIGHTNESS=.*/BRIGHTNESS=$BRIGHTNESSNEW/g ~/.nvidia-brightness.cfg

    source ~/.nvidia-brightness.cfg
    echo "BRIGHTNESS: $BRIGHTNESS"

    nvidia-settings -n -a BacklightBrightness=$BRIGHTNESS 1>/dev/null
}

if [[ "$3" != "" ]]; then
    usage
    exit 1
fi

error_mixed_brightness ()
{
    echo "Error: [ --brightness-up ] and [ --brightness-down ] can't be used together."
}

if [[ "$2" != "" ]]; then
    [[ ! "$2" == ?(-)+([0-9]) ]] && usage && exit 1
fi

case $1 in
    -bu|--brightness-up) 
        [ "$2" == "-bd" ] && error_mixed_brightness && exit 1
        [ "$2" == "--brightness-down" ] && error_mixed_brightness && exit 1
        brightness_up $2
        ;;
    -bd|--brightness-down) 
        [ "$2" == "-bu" ] && error_mixed_brightness && exit 1
        [ "$2" == "--brightness-up" ] && error_mixed_brightness && exit 1
        brightness_down $2
        ;;
    -h|--help) 
        usage
        exit 0
        ;;
    -i|--initialize)
        if [ "$2" != "" ]; then usage; exit 1; fi   
        initialize_cfg
        exit $?
        ;;
    -l|--load-config)
        if [ "$2" != "" ]; then usage; exit 1; fi   
        load_cfg
        exit 0
        ;;
    *) 
        usage
        exit 1
esac
