#!/bin/bash

# Save current terminal settings
stty_orig=$(stty -g)
# Set terminal to raw mode, disable echo
stty raw -echo
# Ensure terminal is restored on exit
trap 'stty "$stty_orig"' EXIT INT TERM

exec </dev/tty

echo "Press a key:"
read -rsn1 key
echo "You pressed: $key"
