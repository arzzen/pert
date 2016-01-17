#!/bin/bash

# help text
if [ -z "$1" ] || [[ "$1" =~ [-]*(help|h) ]]; then
    echo -e "\n\033[1mA command line PERT calculator for quick estimates.\033[0m"
    echo -e "\nComma separated task list in the form \"1,2,12 4,5,9 2,3,6\", where whitespace separates tasks."
    echo -e "\n\033[1mUsage:\033[0m\n\tpert.sh [optimistic,realistic,pessimistic]\n"
    echo -e "\033[1mExample:\033[0m"
    echo -e "\tpert.sh 1,3,4"
    echo -e "\tpert.sh 10,15,20 5,7,10"
    echo -e "\tpert.sh \"1,2,3\" \"15,17,20\"\n"
    exit 1
fi

function _calc 
{
    scale=2
    echo "scale=$scale; $@" | bc -l | sed 's/^\./0./'
}

width=88
function _divider
{
    divider=------------------------------
    divider=" +"$divider$divider$divider"+"
    
    printf "%$width.${width}s+\n" "$divider"
}

format=" | %-12s |%11s |%10s |%12s |%9s |%9s |%9s |\n"

# header
echo -e "\n\033[1mTasks\033[0m\n"
_divider
printf "$format" "#" "optimistic" "realistic" "pessimistic" "duration" "risk" "variance"
_divider

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

_divider

if [[ $total_estimate > 0 ]]; then
    
    # footer        
    printf "$format" "summary" "-" "-" "-" $total_estimate $total_standard_deviation $total_variance
    _divider
    
    echo -e "\n\033[1mThree point estimates\033[0m\n"
    
    width=42 
    tpeformat=" | %-13s |%11s |%10s |\n"
    
    _divider
    printf "$tpeformat" "confidence"
    _divider
    printf "$tpeformat" "1 Sigma - 68%" $(_calc "$total_estimate - $total_standard_deviation") $(_calc "$total_estimate + $total_standard_deviation")
    printf "$tpeformat" "2 Sigma - 95%" $(_calc "$total_estimate - 2 * $total_standard_deviation") $(_calc "$total_estimate + 2 * $total_standard_deviation")
    printf "$tpeformat" "3 Sigma - 99%" $(_calc "$total_estimate - 3 * $total_standard_deviation") $(_calc "$total_estimate + 3 * $total_standard_deviation")
    _divider

fi

echo -e "\n"
