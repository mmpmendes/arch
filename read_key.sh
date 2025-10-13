#!/bin/bash

exec </dev/tty  # Force input from the controlling terminal


echo "Press a key:"
read -rsn1 key  # Read one character silently
echo "You pressed: $key"
