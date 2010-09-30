#! /bin/bash
## Simple calendaring app.  Not resilient or resistant to anything really
## But is a good way to introduce a bunch of concepts to people 

# initialize events list to empty
EVENTS=()

function load_events {
    EVENTS=()
    COUNTER=0
    # $( FOO ) is a shell expansion.  It runs the internal command
    # and returns it.  ` FOO ` would also work, but $() offers some
    # advantages
    # bash for loops tokenize on spaces.  So a loop on the string
    # "1 2 3 4" will have 4 iterations
    for event in $(ls events) 
    do
        # Shell expansion even works inside of strings
        EVENTS[$COUNTER]="$event $(cat events/$event)"
        # unfortunately, bash has kind of terrible arithmetic operators
        # COUNTER=$((COUNTER+1))
        # would also work
        let COUNTER=COUNTER+1
    done
}

function show_events {
    # local restricts the scope of this var to this block
    # you don't technically have to declare eventsList, but I like being 
    # explicit
    local eventsList=
    for index in $(seq 0 $((${#EVENTS[*]}-1)))
    do
        # not really a string contatenation operator in bash
        eventsList="$eventsList ${EVENTS[$index]}"
    done

    # zenity will display a list of events to the user.
    # the > /dev/null is to ignore zenity's return value, which we don't 
    # really care about at this point.  /dev/null is a bit bucket.  Bits check
    # in, but they don't check out.
    zenity --list \
      --text="List of Calendar Items" \
      --column=FileName --column=Title --column=Date --column=Description \
      --hide-column=1 \
      $(echo $eventsList | sed 's/_/ /g') > /dev/null
}

function delete_event {
    local eventsList=
    # ${#EVENTS[*]} is bash's awful way of getting the length of an array
    for index in $(seq 0 $((${#EVENTS[*]}-1)))
    do
        eventsList="$eventsList ${EVENTS[$index]}"
    done

    # now, instead of looping on the shell expansion, we're capturing it in a 
    # variable
    # notice the nested shell expansions, and the pipe in the inner expansion
    # also, I'm using sed, which is a stream editor that can do some pretty
    # nifty things, such as search and replace.
    toDelete=$(zenity --list \
      --text="Select an event to delete" \
      --column=FileName --column=Title --column=Date --column=Description \
      --hide-column=1 \
      $(echo $eventsList | sed 's/_/ /g'))
    
    # this is a quick test to see if $toDelete is a non-empty string
    if [ $toDelete ]
    then
        # bash can't actually delete array elements, so remove the event and
        # reload the events
        rm -f events/$toDelete
        load_events
    fi
}

function add_event {
    local title=$(zenity --entry --text="Enter a One-Word Title")
    local date=$(zenity --calendar --text="Select a date")
    local description=$(zenity --entry --text="Enter a One-Word Description")

    if [ $title -a $date -a $description ] 
    then
        # this under variable is necessary.  If I did
        # echo "$title_$date..."
        # then bash will look for a variable of the name title_, which isn't
        # what I want
        under="_"
        echo "$title$under$date$under$description" > events/$title
        load_events
    else 
        zenity --warning --text="Invalid Field"
    fi
}

function show_menu {
    # case operates on strings.  You can actually do some basic
    # regex operations in the casing.  See delete_*
    case $(zenity --list \
        --text="Select a menu option" \
        --column="token" --column="Menu Option" \
        --hide-column=1 \
        add_event "Add A New Event" \
        show_events "Show Existing Events" \
        delete_event "Delete an Existing Event" \
        quit "Quit this Program" ) in 
    add_event)
        add_event
        return 0
        ;;
    show_events)
        show_events
        return 0
        ;;
    delete_*)
        delete_event
        return 0
        ;;
    quit)
        return 1
        ;;
    esac
         
}

# initial load of the events
load_events

# loop around show_menu until quit is selected
show_menu
while [ "0" -eq $? ]
do
    show_menu
done
