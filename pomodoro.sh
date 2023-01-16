#!/bin/bash

# Set the number of pomodoros
pomodoros=4

# Set the duration of each pomodoro in seconds
duration=1500

# Set the duration of each break in seconds
break_duration=300

# Set the command to display a gnome window at the end of each pomodoro
notify_command="notify-send -u critical --wait 'Pomodoro Complete!'"

for i in $(seq 1 $pomodoros); do

  counter=$duration
  echo "Pomodoro #$i timer started for $((counter / 60)) minutes..."
  while [ "$counter" -gt 0 ]; do
    echo -ne "$counter\033[0K\r"
    sleep 1
    counter=$((counter - 1))
  done

  eval $notify_command

  # Take a break
  counter=$break_duration
  echo "Now take a break for $((counter / 60)) minutes..."
  while [ "$counter" -gt 0 ]; do
    echo -ne "$counter\033[0K\r"
    sleep 1
    counter=$((counter - 1))
  done
done
