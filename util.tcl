namespace export\
	get getdef type value extract\
	null true false boolean\
	number string\
	array array-list array-add array-size\
	object object-dict object-add object-names\
	json-array json-string json-embed

# string-json and array-json are mapped to string and array to avoid
# the global commands

#
# accessor routines - pass a JSON value variable with a set of
# values (key for an object/dict, index for an array/list)
#
# get : returns a JSON value item; if item is not an array
# or object, just return it unchanged if no key/index,
# otherwise loop until all key/index values are consumed
#
#
# returns the type of a JSON value (null, boolean, number, string, array, object)
#
proc get {value args} {
	foreach key $args {
		lassign $value type value

		switch $type {
		a	{set value [lindex $value $key]}
		o	{set value [dict get $value $key]}
		default	{return -code error "$type:$key scalar"}
		}
	}
	set value
}

#
# retrieve an item from the given path
#
# return default if ANY error (invalid JSON value,
# wrong type, invalid dict, missing key, invalid index)
# 
# this routine should never throw an error, but it can
# return a non-JSON value (either the default or the final
# value retrieved
#
proc getdef {default value args} {
	foreach key $args {
		if {![string is list $value] ||
				[lassign $value type value] ne {}} {
			return $default
		}

		switch $type {
		a	{
				if {!([string is integer $key] &&
						[string is list $value] &&
						($key >= 0) &&
						($key < [llength $value]))} {

					return $default
				}

				set value [lindex $value $key]
			}
		o	{
				if {![dict exists $value $key]} {
					return $default
				}

				set value [dict get $value $key]
			}
		default	{
				return $default
			}
		}
	}
	set value
}

proc type {value args} {
	dict getdef {
		0	null
		t	boolean
		f	boolean
		n	number
		s	string
		a	array
		o	object
		j	json
	} [lindex [get $value {*}$args] 0] "invalid"
}

#
# returns the Tcl item from a JSON value
#
proc value {value args} {
	lassign [get $value {*}$args] type value

	switch $type {
	0	{return {}}
	t	{return true}
	f	{return false}
	n	-
	s	-
	a	-
	o	-
	j	{return $value}
	default	{return -code error "invalid type $type"}
	}
}
#
# extract a uniform array or object into a pure Tcl list or dict
# returns list or dict and the type (array or object)
#
proc extract {value type args} {
	lassign [get $value {*}$args] stype value
	switch $stype {
	a	{
			lmap item $value {
				set itype [type $item]
				if {$itype ne $type} {
					return -code error "extracting from array: $itype should be $type"
				}
				value $item
			}
		}

	o	{
			dict map {key item} $value {
				set itype [type $item]
				if {$itype ne $type} {
					return -code error "extracting from object: $itype should be $type"
				}
				value $item
			}
		}

	default	{return -code error "extracting from scalar"}
	}
}
#
# get the names from an object JSON value
#
proc object-names {value args} {
	lassign [get $value {*}$args] type value

	if {$type ne "o"} {return -code error "$type: not object"}
	dict keys $value
}

# get the length of an array JSON value
#
proc array-size {value args} {
	lassign [get $value {*}$args] type value

	if {$type ne "a"} {return -code error "$type: not array"}
	llength $value
}

# constructors for JSON values
# create a 1 or 2 element list with the type identifier as the first item
# and the value (null/true/false/number, unescaped JSON string, list of
# JSON values, or dict with JSON values
#
proc null {} {
	list 0
}


proc true {} {
	list t
}

proc false {} {
	list f
}

# create a JSON boolean value from a Tcl boolean
#
proc boolean {value} {

	expr {$value ? t : f}
}

#
# concatenate arguments together and create a JSON string value
# renamed to string-json to make sure no conflict with ::string
# remapped in the ensemble
#
proc string-json {args} {
	list s [concat {*}$args]
}

#
# create a JSON number; stores the exact representation
# does not try to normalize it; however, Tcl expr values
# should generally be compatible
#
proc number {value} {
	set valid [valid-number $value]
	if {$valid ne "valid"} {return -code error $valid}

	list n $value
}

#
# create a JSON array value from zero or more JSON values
# renamed to array-json to make sure no conflict with ::array
# remapped in the ensemble
#
proc array-json {args} {
	list a [list {*}$args]
}

#
# create a JSON array from a Tcl list of JSON values
#
proc array-list {list} {
	list a $list
}

#
# add additional items on to an existing JSON array value
#
proc array-add {value args} {
	upvar $value array

	if {[lindex $array 0] ne "a"} {return -code error "$array: not an array"}
	foreach item $args {
		lset array 1 end+1 $item
	}
}

#
# create a JSON object value from one or more pairs of names
# and JSON values
#
proc object {args} {
	list o [dict create {*}$args]
}

# create a JSON object value from a Tcl dict
# the values in the dict must be JSON values,
# while the name/key is just a normal Tcl string
#
proc  object-dict {dict} {
	list o $dict
}

# add pairs of names and JSON values to an existing
# JSON object value
# note: treating the 2-element list as a dict with one
# entry with a key of "o" in the `dict set` below
#
proc  object-add {value args} {
	upvar $value object

	if {[lindex $object 0] ne "o"} {return -code error "$object: not an object"}
	foreach {name value} $args {
		dict set object o $name $value
	}
}

# represent a JSON item string
#
proc json-string {value} {
	list j $value
}

# convert an array of JSON strings into a JSON array
#
# note the difference between
#
# 	json-array $val
# and
# 	array-list $val
#
# both will encode to the same result
# the first is faster, the second is more flexible
#
proc json-array {value} {
	list j \[[join $value ,]\]
}

#
# create a json-string value from a JSON value
#
proc json-embed {value} {
	list j [encode $value]
}
