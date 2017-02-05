#!/bin/sh

ls -lAR | sort -rnk 5,5 | grep ^[-d] |
 awk '{
        if($1 ~ /^d/) dir ++ ;
        if($1 ~ /^-/){file ++ ;total += $5}
        if(NR<6) print NR ": " $5 " " $9
        }
        END{print "Dir num: " dir "\n" "FIle num: " file "\n" "Total: " total}'
