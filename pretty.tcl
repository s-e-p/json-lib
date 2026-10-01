namespace export pretty
# pretty:  parse JSON string and produce new JSON string with
# added whitespace for clarity, continues until all characters
# in the string have been used.
#
# parse-json: private routine that does the work
#
proc pretty {string {tab "  "} {indent ""}} {
	set index 0
	set list {}

	while {[string index $string $index] ne ""} {
		lassign [parse-json $string $index $tab $indent $indent] item index
		if {$item eq ""} break
		lappend list $item
	}

	if {[string range $string $index end] ne ""} {
		lappend list [string cat ">>> " [string trimright [string range $string $index $index+20]] " <<<"]
	}

	join $list \n
}

proc parse-json {string index tab level first} {
	variable Next

	if {[regexp -start $index -indices $Next $string match what skip] != 1} {
		return [list "" [parse-skip $string $index]]
	}

	set start [lindex $what 0]
	set end [lindex $what 1]
	set index [lindex $skip 0]

	set what [string range $string $start $end]
	set skip [string index $string $index]

	set indent $level$tab

	switch $what {
	\[	{
			if {$skip eq "\]"} {
				incr index
				set item "\[ \]"
			} {
				set nest $indent
				while {true} {
					lassign [parse-json $string $index $tab $indent $nest] item index
					lappend list $item

					set skip [string index $string $index]
					incr index

					if {$skip ne ","} break
					set nest $indent
				}

				if {$skip ne "\]"} {
					return -code error "[string range $string $start $index]: missing \]"
				}

				set item \[\n[join $list ,\n]\n$level\]
			}
			set index [parse-skip $string $index]
		}

	\{	{
			if {$skip eq "\}"} {
				incr index
				set item "\{ \}"
			} {
				while {true} {
					lassign [parse-key $string $index] name index
					lassign [parse-json $string $index $tab $indent " "] item index
					lappend list $indent\"$name\":$item

					set skip [string index $string $index]
					incr index

					if {$skip ne ","} break
				}

				if {$skip ne "\}"} {
					return -code error "[string range $string $start $index]: missing \}"
				}

				set item \{\n[join $list ,\n]\n$level\}
			}
			set index [parse-skip $string $index]
		}

	default	{set item $what}
	}

	list $first$item $index
}

proc parse-key {string index} {
	variable KeyVal

	if {[regexp -start $index -indices $KeyVal $string match what] != 1} {
		return -code error "[string range $string $index end]: invalid object key"
	}

	set index [lindex $match 1]
	set start [lindex $what 0]
	set end [lindex $what 1]

	list [string range $string $start $end] [incr index]
}

proc parse-skip {string index} {
	if {[string is space -failindex skip [string range $string $index end]]} {
		string length $string
	} {
		expr {$index + $skip}
	}
}
