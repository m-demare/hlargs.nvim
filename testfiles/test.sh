#!/bin/bash

greeting() {
    echo "Hello $1"
}

function farewell {
    echo "$2 says goodbye, $1"
    return 1
}

function many_arguments () {
    cat << EOF
$1 $2, buckle my shoe!"
${3:-red} ${4:+and $4}, knock at the door!
${5} $6, picking up sticks!
$7 ${8}, don't be late!
${9:+nine} ten, let's say it again!
EOF
}

function special_arguments () {
    echo "you have called the function called '$0'"
    echo "and you have passed $# arguments to it."
    echo "the first argument followed by a zero is $10"
}

greeting "James Bond" $1
farewell "Mr Bond" "Goldfinger"
many_arguments "a" "bee" "three" "4" "e" "eff" "7" "ate" "nueve"

special_arguments martini shaken not stirred
