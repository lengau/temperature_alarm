#!/bin/bash

# Alerts whenever a temperature gets above a certain threshold

txtred='\e[0;31m'
txtrst='\e[0m'
THRESHOLD=90000  # Milli-degrees Celsius
PERIOD=2  # seconds

temp_files=$(find /sys/ -type f -iname '*temp*_input' -readable 2>/dev/null)

last_warning_file=$(mktemp)
touch -d 1970-01-01 $last_warning_file

function over_threshold_warning() {
    last_warning=$(stat -c %Y $last_warning_file)
    current_time=$(date +%s)
    if [[ $(($last_warning + 10)) -le $current_time ]]; then
        touch $last_warning_file
        paplay /usr/share/sounds/KDE-Sys-Special.ogg &
        sleep 0.5
        echo "Temperature is $1 degrees." | flite
    fi
}

while true; do
    date
    temps=$(echo $temp_files | tr ' ' '\n' | parallel --no-notice grep -h -v [[:alpha:]])
    over_threshold=0
    for temp in $temps; do
        if [[ $temp -ge $THRESHOLD ]]; then
            if [[ $temp -ge $over_threshold ]]; then
                over_threshold=$temp
            fi
            echo -e "${txtred}ERROR:${txtrst} TEMPERATURE TOO HIGH: $temp"
        else
            echo "Temperature is fine: $temp"
        fi
    done
    if [[ "$over_threshold" != 0 ]]; then
        over_threshold_warning $(echo $over_threshold/1000|bc) &
    fi
    sleep $PERIOD
done

rm $last_warning_file
