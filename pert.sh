#!/bin/bash

# help text
if [ -z "$1" ] || [[ "$1" =~ [-]*(help|h) ]]; then
    echo -e "\nA command line PERT calculator for quick estimates."
    echo -e "\nComma separated task list in the form \"1,2,12 4,5,9 2,3,6\", where whitespace separates tasks."
    echo -e "\nUsage:\n\tpert [optimistic,realistic,pessimistic]\n"
    echo -e "Example:"
    echo -e "\tpert 1,3,4"
    echo -e "\tpert 10,15,20 5,7,10"
    echo -e "\tpert \"1,2,3\" \"15,17,20\"\n"
    exit 1
fi

# helper
function _calc 
{
    scale=2
    echo "scale=$scale; $@" | bc -l | sed 's/^\./0./'
}

function _divider
{
    divider=------------------------------
    divider=" "$divider$divider$divider
    width=85
    
    printf "%$width.${width}s\n" "$divider"
}

header="\n %-12s |%11s |%10s |%12s |%9s |%9s |%9s\n"
format=" %-12s |%11s |%10s |%12s |%9s |%9s |%9s\n"

counter=0
total_estimate=0
total_standard_deviation=0
total_variance=0
for var in "$@"; do
    
    # counter iterator
    counter=$[$counter +1]
 
    # split values
    IFS=',' read -ra ADDR <<< "$var"
    
    # optimistic value
    o=${ADDR[0]}
    
    # realistic value
    r=${ADDR[1]}
    
    # pessimistic value
    p=${ADDR[2]}
    
    # header
    if [[ $counter = 1 ]]; then
        printf "$header" "#" "optimistic" "realistic" "pessimistic" "duration" "risk" "variance"
        _divider
    fi
    
    # check values
    if [ -z "$o" ] || [ -z "$r" ] || [ -z "$p" ]; then
        printf "$format" "$counter. bad input" $o $r $p
    else
    
        # pert estimate
        pert_estimate=$(_calc "($o+4*$r+$p)/6")
        total_estimate=$(_calc "$total_estimate + $pert_estimate") 
        
        # standard deviation
        standard_deviation=$(_calc "($p-$o)/6")
        total_standard_deviation=$(_calc "$total_standard_deviation + $standard_deviation")

        # variance
        variance=$(_calc "$standard_deviation * $standard_deviation")
        total_variance=$(_calc "$total_variance + $variance")
    
        # row        
        printf "$format" "$counter. task" $o $r $p $pert_estimate $standard_deviation $variance
    fi

done

if [[ $total_estimate > 0 ]]; then

    # footer        
    _divider
    printf "$format" "summary" "-" "-" "-" $total_estimate $total_standard_deviation $total_variance
    
    #echo -e "\nThree point estimate:"
    
fi

echo -e "\n"