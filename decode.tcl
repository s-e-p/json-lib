namespace export decode decode-multi
# 
# decode: alternate interface to parse routine
# if the result argument is passed, the JSON value is stored in that variable and the remainder of
# the string is returned as the result (with leading whitespace removed)
# if the result name is not supplied, the JSON value is returned as the result and an error is
# thrown if there are any non-whitespace characters remaining in the string
#
proc decode {string {result {}}} {
	if {$result ne ""} {
		upvar $result item
	}

	lassign [parse $string] item index
	set string [string range $string $index end]

	if {$result eq ""} {
		if {$string ne ""} {
			return -code error "characters after end: [string range $string 0 20]"
		}
		set item
	} {
		set string
	}
}

#
# decode multiple JSON strings
# stops when no more data or next characters
# aren't valid JSON (left bracket, left brace,
# null, true, false, string or valid number)
#
# returns a Tcl list of JSON values
#
proc decode-multi {string} {
	set index 0
	set length [string length $string]

	while {$index < $length} {
		lassign [parse $string $index] item index
		if {[llength $item] == 0} break
		lappend list $item
	}
	if {![info exists list]} {
		return -code error "no valid JSON found: -->[string range $string 0 20]<--"
	} elseif {$index < $length} {
		return -code error "extra characters: $index: [string range $string $index $index+20]"
	}

	set list
}
