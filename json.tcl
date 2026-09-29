# a JSON value is stored as a list with one or two items
#
# the first item is the value type: 0 - null, t - true, f - false,
# n - number, s - string, a - array, o - object
#
# the second item is the value for number, string, array, and object
#
# for number, the original representation of the number from the encoded JSON, or a
# normal Tcl string representation value
#
# for string, the unescaped string, with no surrounding quotes.
#
# for array, a Tcl list of JSON values
#
# for object, a Tcl dict with the key an unescaped string value and a JSON value
# 
package require Tcl 9.0

namespace eval ::json::json {
#
# some RE values
#
set String	{(?:(?:\\(?:[btnfr/\\"]|u[[:xdigit:]]{4}))*[^\\"[:cntrl:]]*)*}
set Number	{(?:-?(?:0|[1-9][[:digit:]]*)(?:\.[[:digit:]]+)?(?:[Ee][-+]?[[:digit:]]+)?)}
set LBracket	{\[}
set LBrace	{\{}
set JSON	"${LBracket}|${LBrace}|\"${String}\"|null|true|false|${Number}"
set Blanks	{[ \t\n\r]*}
set Start	{\A}
set End		{\Z}

const Next	"${Start}${Blanks}(${JSON})${Blanks}(.?)"
const KeyVal	"${Start}${Blanks}\"(${String})\"${Blanks}:"
const Skip	"${Start}${Blanks}(.?)"
const ValidNum	"${Start}${Number}${End}"

unset String Number LBracket LBrace JSON Blanks Start End

apply {{args} {
	foreach part $args {
		source [file join [file dirname [info script]] $part.tcl]
	}
} {::json::json}} util valid encode parse decode pretty

	namespace ensemble create -subcommand [namespace export] -map {
		string string-json
		array array-json
	}

	namespace export -clear
}

namespace eval ::json {
	namespace export json
}

package provide json-lib 1.0
