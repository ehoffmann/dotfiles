#!/bin/bash

# Set the duration of each pomodoro in seconds
duration=1500

# Set the duration of each break in seconds
break_duration=300

notify() {
  notify-send -u critical --wait "$1"
}

echo "Pomodoro timer started for $((duration / 60)) minutes..."
while [ "$duration" -gt 0 ]; do
  echo -ne "$duration\033[0K\r"
  sleep 1
  duration=$((duration - 1))
done

notify 'Pomodoro Complete!'

# Take a break
echo "Now take a break for $((break_duration / 60)) minutes..."
while [ "$break_duration" -gt 0 ]; do
  echo -ne "$break_duration\033[0K\r"
  sleep 1
  break_duration=$((break_duration - 1))
done

notify 'Break is over'
