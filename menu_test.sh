#!/bin/bash

select_drive() {
  # Ensure stdin is bound to the terminal
  exec </dev/tty

  # Initialize empty variable to store drive paths
  DRIVE_PATHS=""
  # Get list of all block devices using lsblk, exclude header and loop devices
  DRIVES=$(lsblk -d -o PATH | grep -v '^PATH' | grep -v loop)

  # Check if any drives were found
  if [ -z "$DRIVES" ]; then
    echo "No drives found. Exiting."
    exit 1
  fi

  # Loop through each drive and append to DRIVE_PATHS
  while IFS= read -r drive; do
    DRIVE_PATHS="$DRIVE_PATHS $drive"
  done <<< "$DRIVES"

  # Remove leading/trailing whitespace
  DRIVE_PATHS=$(echo "$DRIVE_PATHS" | xargs)

  # Array of menu options
  options=($DRIVE_PATHS)
  # Current selected index
  selected=0
  # Total number of options
  total_options=${#options[@]}

  # Function to draw the menu
  draw_menu() {
    clear
    echo "###########################################"
    echo "#        Select installation drive        #"
    echo "###########################################"
    echo "#"
    for ((i=0; i<total_options; i++)); do
      if [ $i -eq $selected ]; then
        # Highlight selected option with > and background color
        echo -e "# > \033[7m${options[$i]}\033[0m "
      else
        echo "#   ${options[$i]}   "
      fi
    done
    echo "#"
    echo "###########################################"
    echo "#   Use ↑↓ to navigate, Enter to select   #"
    echo "###########################################"
  }

  # Function to handle key input
  read_arrow() {
    local key
    read -rsn1 key # Read one character silently from /dev/tty (already set by exec)
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 -t 0.1 key 2>/dev/null # Read two more characters with timeout
      case $key in
        '[A') # Up arrow
          ((selected--))
          if [ $selected -lt 0 ]; then
            selected=$((total_options-1))
          fi
          return 1
          ;;
        '[B') # Down arrow
          ((selected++))
          if [ $selected -ge $total_options ]; then
            selected=0
          fi
          return 1
          ;;
        *) # Escape key alone or other sequences
          return 1
          ;;
      esac
    elif [[ $key == "" ]]; then
      # Enter key
      return 0
    fi
    return 1 # Other keys return to menu
  }

  # Drive selection loop
  while true; do
    draw_menu
    read_arrow
    key_status=$?

    if [ $key_status -eq 0 ]; then
      # Enter was pressed, handle selection
      echo "Are you sure you want to use drive ${options[$selected]} to install Arch? ALL DATA WILL BE LOST!"
      echo "Press Enter to continue, Esc or any other key to cancel..."
      read -rsn1 confirm
      if [ -z "$confirm" ]; then
        # Enter was pressed, set DRIVE and proceed
        DRIVE="${options[$selected]}"
        # Validate drive
        if [ ! -b "$DRIVE" ]; then
          echo "Error: $DRIVE is not a valid block device."
          exit 1
        fi
        echo "Selected drive: $DRIVE"
        return 0 # Proceed with installation
      elif [ "$confirm" == $'\x1b' ]; then
        # Escape was pressed, return to menu
        continue
      else
        # Any other key, return to menu
        continue
      fi
    fi
    # Escape or other keys (key_status -eq 1) redraw the menu
  done
}

setup() {
  # Select drive
  select_drive
  local installation_drive="$DRIVE"

  echo '##### Creating partitions #####'
  partition_drive "$installation_drive"
}

partition_drive() {
  local installation_drive="$1"

  echo "Partitioning drive $installation_drive"
}

setup
