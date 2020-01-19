#! /usr/bin/env bash
for ((counter=1; counter<=$#; counter++))
do
    if [ "${!counter}" = "--help" ]
    then
        echo "===================================================================================="
        echo "Turing Machine Emulator V 3.0"
        echo "Script allows to visualize Turing Machine working proccess"
        echo "===================================================================================="
        echo "Usage: MachineEmulator.sh [file] [tape_data] <options>"
        echo "Available options:"
        echo "--help print this page"
        echo "-s <speed_value_ms> set screen refresh rate"
        echo "If speed_value is not supplied, default value will be set (0.1 ms)"
        echo "------------------------------------------------------------------------------------"
        echo "Specified file should include commands in this format: q,a,v,q\`"
        echo "q-current_state (numbers or letters)"
        echo "a-symbol currently seen on a tape (any symbol or command)"
        echo "v-command or symbol to write (any symbol or command)"
        echo "q\`-next state (numbers or letters)"
        echo "------------------------------------------------------------------------------------"
        echo "Available commands:"
        echo "> - move right"
        echo "< - move left"
        echo "= - don't move at this turn;"
        echo "# - stop the machine"
        echo "------------------------------------------------------------------------------------"
        echo "Machine tape is left limited"
        echo "Each command should be written in newline"
        echo "Script detects infinite loops and transitions indetermination"
        exit 0
    fi
done

counter=1
for ((counter; $counter <= $# ; counter++))
do
    if [ "${!counter}" != "-s" ]
    then
        path=${!counter}
        counter=$(($counter + 1))
        break
    else
        counter=$(($counter+1))
    fi
done

if [ -z "$path" ]
then
    echo "File is not signified"
    echo "Usage: MachineEmulator.sh [file] [tape_data] -s <speed_value_ms>"
    echo "Use --help for more detailed information"
    exit 1
fi

if ! [ -e "$path" ]
then
    echo "Read error occured. File $1: no such file"
    exit 1
fi

if ! [ -r "$path" ]
then
    echo "Read error occured. File $1: permission denied"
    exit 1
fi
for ((counter; $counter <= $# ; counter++))
do
    if [ "${!counter}" != "-s" ]
    then
        data=${!counter}
        counter=$(($counter+1))
        break
    else
        counter=$(($counter+1))
    fi
done
if [ -z "$data" ]
then
    echo "Tape data is not signified"
    echo "Usage: MachineEmulator.sh [file] [tape_data] -s <speed_value_ms>"
    echo "Use --help for more detailed information"
    exit 1
fi

if [ "$#" -eq 4 ] || [ "$#" -eq 2 ]
then
    if [ "$#" -eq 4 ]
    then
        for ((counter=1; $counter <= $# ; counter++))
        do
            if [ "${!counter}" = "-s" ]
            then
                counter=$(($counter + 1))
                speed=${!counter}
                break
            fi
        done
        if [ $(echo "$speed" | grep -E  "(^[0-9]+$|^[0-9]+\\.[0-9]+$)" | wc -w) -eq 0 ] 
        then
            echo "Specified incorrect time"
            exit 1
        fi
    fi
    
    if [ "$#" -eq 2 ]
    then
        speed=0.1
    fi
else
    echo "Usage: MachineEmulator.sh [file] [tape_data] -s <speed_value_ms>"
    echo "Use --help for more detailed information"
    exit 1
fi

length=$( echo -n "$data" | wc -m )

for (( counter=1; counter<=$length; counter++ ))
do
    tape[$counter]=$( echo "$data" | cut -c $counter )
done


ltape=1
rtape=$length
head=$(( $length+1 ))
tape[$rtape + 1]=" "
commands=$(grep -Eo "^[[:alnum:]]+,[^,]+,[^,]+,[[:alnum:]]+" $1 |  grep -Eo "[[:alnum:]]+,[^,]+,[^,]+,[[:alnum:]]+([[:space:]]|$){1}")
string=$(echo "$commands"| grep -Eo "^[0]+,.*,.*,.*")

if [ $(echo  "$string" | wc -m) -eq 0 ]
then
    echo "Initializing failed. Initial state not found"
    exit 1
fi

if [ $(echo "$string" | wc -l) -gt 1 ]
then
    echo -e "Initializing failed. Several initial states: \n$string"
    exit 1
fi

transitions=$(echo -n "$commands" | wc -l)
performed=0

state=$(echo "$string"|cut -d , -f 1)
charset=$(echo "$string"|cut -d , -f 2)
action=$(echo "$string"|cut -d , -f 3)
switch=$(echo "$string"|cut -d , -f 4)

clear

while [ "$action" != '#' ]
do
    if [ "$charset" = "${tape[$head]}" ]
    then
        if [ "$action" != '=' ] && [ "$action" != '>' ] && [ "$action" != '<' ]
        then
            if [ "$state" = "$switch" ] && [ "$charset" = "$action" ]
            then
                echo "Infinite loop detected: \"$state,$charset,$action,$switch\" Exiting..."
                exit 1
            fi
            tape[$head]=$action
        else
            if [ "$action" = '<' ]
            then
                 head=$(($head-1))
            fi

            if [ "$action" = '>' ]
            then
                head=$(($head+1))
            fi
            
            if [ "$action" = '=' ] && [ "$state" = "$switch" ]
            then
                echo "Infinite loop detected: \"$state,$charset,$action,$switch\" Exiting..."
                exit 1
            fi
        fi
        
        if [ $head -gt $rtape ] || [ $head -lt $ltape ]
        then
            tape[$head]=" "
            if [ $head -gt $rtape ]
            then
                rtape=$head
            else
                ltape=$head
            fi
        fi
        
        if [ $ltape -lt 0 ]
        then
        echo "Head is out of tape"
        exit 1
        fi

        string=$(echo "$commands" | grep -E "^$switch,${tape[$head]},")
        if [ $(echo "$string" | wc -l) -gt 1 ]
        then
            echo -e "Several states: \n$string"
            exit 1
        fi

        state=$switch
        charset=$(echo "$string"|cut -d , -f 2)
        action=$(echo "$string"|cut -d , -f 3)
        switch=$(echo  "$string"|cut -d , -f 4)
        performed=$(( $performed + 1 ))
 
        echo Transitions: $transitions
        echo Cells used: $(( $rtape -$ltape + 1))
        echo Message length: $length
        echo Performed actions: $performed
        

        for (( counter=$ltape; counter<=rtape; counter++))
        do
            if [ $counter -eq $head ]
            then
                echo -en "\033[37;1;41m${tape[$counter]}\033[0m"
            else
                echo -en "${tape[$counter]}"
            fi
        done
        echo
        sleep $speed
        
        if [ "$action" != '#' ]
        then
            clear
        fi

    else
        if [ $(echo "$commands" | grep -Ec "^$state,") -eq 0 ]
        then
            echo "State \"$state\" not found in specified file"
        else
            echo "Transition is undefined for state \"$state\" and symbol \"${tape[$head]}\""
        fi
        exit 1
    fi
done
exit 0