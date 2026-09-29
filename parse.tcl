namespace export parse
# parse : parse a json string
# returns a list with the JSON value and the index to the next non-blank character in the string
# 
proc parse {string {index 0}} {
	variable Next
	variable KeyVal
	variable Skip

	set stack	{}
	set item	{}
	set state	""

	while {[regexp -start $index -indices $Next $string match what skip] == 1} {
		lassign $what start end
		lassign $skip index

		set what [string range $string $start $end]

		switch [string index $what 0] {
		\[	{
				if {$state ne ""} {lappend stack [list $state $list]}
				set list [list a]
				set state \]
				set item {}
			}

		\{	{
				if {$state ne ""} {lappend stack [list $state $list]}
				set list [list o]
				set state \}
				set item {}
			}

		\"	{
				set item [list s [unescape [string range $what 1 end-1]]]
			}

		n	{set item [list 0]}
		t	{set item [list t]}
		f	{set item [list f]}
		default	{set item [list n $what]}
		}

		if {$state eq ""} break

		if {[llength $item] != 0} {
			lappend list $item
		}

		# loop until next item or end of structure
		while {true} {
			# find comma or structure end
			set skip [string index $string $index]

			if {$skip ne $state} break

			# end of array or object, close it out
			regexp -start [incr index] -indices $Skip $string match skip
			lassign $skip index

			set item [list [lindex $list 0] [lrange $list 1 end]]

			# exit if outer structure complete
			if {[llength $stack] == 0} {
				set state ""
				break
			}

			# pop and continue at previous level
			lassign [lpop stack] state list
			lappend list $item
		}

		# check if outer structure finished
		if {$state eq ""} break

		# verify comma if this isn't the first item in a structure
		if {[llength $item] != 0} {
			if {$skip ne ","} {return -code error "expected comma, got \"$skip\""}
			incr index
		}

		# process key for an object
		if {$state eq "\}"} {
			if {[regexp -start $index -indices $KeyVal $string match what] != 1} {
				return -code error "invalid object key"
			}

			lassign $match start index
			lassign $what start end

			incr index

			lappend list [unescape [string range $string $start $end]]
		}
	}

	if {$state ne ""} {return -code error "incomplete structure"}

	# skip whitespace following an empty structure
	# already skipped from comma check earlier if not empty
	if {[llength $item] == 0} {
		regexp -start $index -indices $Skip $string match skip
		lassign $skip index
	}

	list $item $index
}

# unescape a string:  change it back to it's original value
# this map changes a unicode escape sequence into a unicode character as
# well as replacing escape sequences with their correct character
#
# change a \\ sequence in the string into \x5c (a \ character) for
# subst to turn back, otherwise \\u0041 would be turned into an A by subst.
#
# Tcl will convert \u with 1-4 hex digits, JSON only allows exactly 4
# the RE that extracts the string checks for that, so we can ignore it
#
# following regsub would change invalid \u JSON sequence to not be converted
# regsub -all {\\(u[[:xdigit:]]{0,3}(?![[:xdigit:]]))} $string {\x5c\1}
#
# Instead, we use the String RE to reject the invalid \u sequence entirely, thus
# we don't need to handle it in the unescape procedure, as unescape is only used
# on strings that have been accepted by the RE
#
proc unescape string {
subst -nocommands -novariables [ \
	string map {
		\\b		\x08
		\\t		\x09
		\\n		\x0a
		\\f		\x0c
		\\r		\x0d
		\\/		/
		\\\"		\"
		\\\\		\\x5c
	} $string]
}
