namespace export valid-number valid
# check if a number is valid JSON; does not try to normalize it, just validate it
# returns "valid" or an error string
#
# removed check for number conversion - any valid JSON number should be a valid Tcl number
#	[catch {expr {($value + 0) == $value ? "valid" : "value"} valid}]
#
#	however it may be out of range, e.g. 1e9999 converts to Inf, 1e-9999 converts to 0
#	we can't control how the numbers will be used, so leave them in the original format
#
proc valid-number {value} {
	variable ValidNum

	if {[regexp ${ValidNum} $value] ==  1} {
		return valid
	}

	return "$value: invalid number"
}

#
# validate a JSON value
#
# recurse directly rather than throught the ensemble
#
# json-strings are not validated
#
proc valid {value} {
	if {[string is list $value] && [set len [llength $value]] == 0} {return "invalid JSON value"}

	lassign $value type value
	switch $type {
	0	-
	t	-
	f	{
			if {$len != 1} {return "invalid [dict get {0 null t boolean f boolean} $type]"}
		}

	n	{
			if {$len != 2} {return "invalid number"}
			return [valid-number $value]
		}

	s	{if {$len != 2} {return "invalid string"}}

	a	{
			if {$len != 2} {return "invalid array"}
			if {![string is list $value]} {return "invalid array structure"}
			set index 0
			foreach value $value {
				set valid [valid $value]
				if {$valid ne "valid"} {return "array $index: $valid\n$value"}
				incr index
			}
		}

	o	{
			if {$len != 2} {return "invalid object"}
			if {![string is dict $value]} {return "invalid object structure"}
			dict for {name value} $value {
				set valid [valid $value]
				if {$valid ne "valid"} {return "object \"$name\": $valid\n$value"}
			}
		}

	j	{
			if {$len != 2} {return "invalid json-string"}
		}

	default	{return "invalid type $value"}
	}	

	return valid
}
