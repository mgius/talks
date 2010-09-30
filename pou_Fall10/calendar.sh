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
    for event in $(ls events) 
    do
        EVENTS[$COUNTER]="$event $(cat events/$event)"
        # unfortunately, bash has kind of terrible arithmetic operators
        # COUNTER=$((COUNTER+1))
        # would also work
        let COUNTER=COUNTER+1
    done
}

function show_events {
    # local restricts the scope of this var to this block
    local eventsList=
    for index in $(seq 0 $((${#EVENTS[*]}-1)))
    do
        eventsList="$eventsList ${EVENTS[$index]}"
    done

    zenity --list \
      --text="List of Calendar Items" \
      --column=FileName --column=Title --column=Date --column=Description \
      --hide-column=1 \
      $(echo $eventsList | sed 's/_/ /g') > /dev/null
}

function delete_event {
    local eventsList=
    for index in $(seq 0 $((${#EVENTS[*]}-1)))
    do
        eventsList="$eventsList ${EVENTS[$index]}"
    done

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

# loop around show_menu until quit is selected
show_menu
while [ "0" -eq $? ]
do
    show_menu
done
