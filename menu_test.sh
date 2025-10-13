select_drive() {
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
  total_options=${#options[@]}

  # Function to draw the menu
  draw_menu() {
    clear
    echo "###########################################"
    echo "#        Select installation drive        #"
    echo "###########################################"
    echo "#"
    for ((i=0; i<total_options; i++)); do
      echo "# $((i+1)). ${options[$i]}"
    done
    echo "#"
    echo "###########################################"
    echo "# Enter the number of the drive to select #"
    echo "###########################################"
  }

  # Drive selection loop
  while true; do
    draw_menu
    echo -n "Selection (1-$total_options): "
    read choice

    # Validate input
    if [[ "$choice" =~ ^[0-9]+$ && $choice -ge 1 && $choice -le $total_options ]]; then
      DRIVE="${options[$((choice-1))]}"
      echo "Are you sure you want to use drive $DRIVE to install Arch? ALL DATA WILL BE LOST!"
      echo "Press Enter to continue, any other key to cancel..."
      read -rsn1 confirm
      if [ -z "$confirm" ]; then
        # Enter was pressed, validate drive
        if [ ! -b "$DRIVE" ]; then
          echo "Error: $DRIVE is not a valid block device."
          exit 1
        fi
        echo "Selected drive: $DRIVE"
        return 0 # Proceed with installation
      else
        # Any other key, return to menu
        continue
      fi
    else
      echo "Invalid selection. Please enter a number between 1 and $total_options."
      sleep 2
    fi
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
