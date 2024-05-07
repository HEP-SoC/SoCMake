#! /bin/bash

awk -i inplace -F'[][]' 'NR==FNR && /wire.*hwif_in/{width_in=$2} NR==FNR && /wire.*hwif_out/{width_out=$2;next} {gsub ( /TO_CHANGE_HWIF_IN/, width_in ) gsub ( /TO_CHANGE_HWIF_OUT/, width_out ) ;print}' $1 $2
