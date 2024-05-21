#! /bin/bash

width_in=$(grep -E 'wire.*hwif_in' $1 | cut -d '[' -f2 | cut -d ']' -f1)
width_out=$(grep -E 'wire.*hwif_out' $1 | cut -d '[' -f2 | cut -d ']' -f1)
sed -i "s/TO_CHANGE_HWIF_IN/$width_in/" $2
sed -i "s/TO_CHANGE_HWIF_OUT/$width_out/" $2
