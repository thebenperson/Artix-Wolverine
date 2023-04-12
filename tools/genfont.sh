#/usr/bin/env sh

font="$1"
total=0

function extract() {

	((total += $2 - $1 + 1))
	
	psf2raw --first=$1 --last=$2 "$font"             |\
	hexdump --format '4/4 "%08X " "\n"'              |\
	sed -r 's/(.{8}) (.{8}) (.{8}) (.{8})/\4\3\2\1/' ;

}

{

	# music notes
	extract 13 14

	# space
	extract 32 32

	# open and closed parentheses
	extract 40 41

	# 0 - 9 and colon
	extract 48 58

	# equals sign
	extract 61 61

	# A - Z
	extract 65 90

	# a - z
	extract 97 122

	# vertical bar and vertical left bar
	extract 179 180

	# top right corner, bottom left corner, bottom up bar, top down bar, left right bar, horizontal bar, and all bar
	extract 191 197

	# bottom right corner, top left corner, and full block
	extract 217 219

}

echo Total Characters: $total 1>&2
