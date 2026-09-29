namespace export encode encode-multi
# 
# encode: build a JSON string - if it is an object or array, recursively generate each item
# outputs as compactly as possible with no extra whitespace
#
# since it's recursive avoid going through the ensemble
#
proc encode {value} {
	lassign $value type value
	switch $type {
	0	{return null}
	t	{return true}
	f	{return false}
	n	{return $value}
	s	{return \"[escape $value]\"}

	a	{
			return \[[join [lmap value $value {
				encode $value
			}] ,]\]
		}

	o	{
			set result {}
			dict for {name value} $value {
				lappend result \"[escape $name]\":[encode $value]
			}
			return \{[join $result ,]\}
		}

	j	{
				return $value
		}

	default	{return -code error "invalid type $type"}
	}
}

proc encode-multi {list} {
	join [lmap item $list {
		encode $item
	}] \n
}

#
# escape a string
# only characters within the range \x00-\x1f are
# escaped, plus \\ and \", and optionally \/
#
proc escape {value} {
	string map {
		\x00		\\u0000
		\x01		\\u0001
		\x02		\\u0002
		\x03		\\u0003
		\x04		\\u0004
		\x05		\\u0005
		\x06		\\u0006
		\x07		\\u0007
		\x08		\\b
		\x09		\\t
		\x0a		\\n
		\x0b		\\u000b
		\x0c		\\f
		\x0d		\\r
		\x0e		\\u000e
		\x0f		\\u000f
		\x10		\\u0010
		\x11		\\u0011
		\x12		\\u0012
		\x13		\\u0013
		\x14		\\u0014
		\x15		\\u0015
		\x16		\\u0016
		\x17		\\u0017
		\x18		\\u0018
		\x19		\\u0019
		\x1a		\\u001a
		\x1b		\\u001b
		\x1c		\\u001c
		\x1d		\\u001d
		\x1e		\\u001e
		\x1f		\\u001f
		/		\\/
		\"		\\\"
		\\		\\\\
	} $value
}
