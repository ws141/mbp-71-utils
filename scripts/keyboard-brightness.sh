#!/bin/bash
VALUE=$(/usr/bin/cat /sys/class/leds/smc::kbd_backlight/brightness)
INCREMENT=32
TOTAL=unset

case $1 in
up)
    TOTAL=`expr $VALUE + $INCREMENT`
    ;;
down)
    TOTAL=`expr $VALUE - $INCREMENT`
    ;;
on)
    TOTAL=$(/usr/bin/cat /sys/class/leds/smc\:\:kbd_backlight/max_brightness)
    ;;
off)
    TOTAL=0
    ;;
esac

if [ $TOTAL == unset ]; then
    echo "Please specify up, down, full, or off"
    exit 1
fi

if [ $TOTAL -gt 255 ]; then TOTAL=255; fi
if [ $TOTAL -lt 0 ]; then TOTAL=0; fi 
/usr/bin/echo $TOTAL > /sys/class/leds/smc::kbd_backlight/brightness
