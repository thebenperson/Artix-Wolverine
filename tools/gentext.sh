#/usr/bin/env bash

function checkRange() {

	a=$(printf "%d" "'$1")
	b=$(printf "%d" "'$2")

	if [ $in -lt $a ] || [ $in -gt $b ]; then

		((idx += b - a + 1))
		return 1

	fi

	printf "%02X " $((idx + in - a))
	return 0

}

{

	declare -A map=(

		[' ']="02"
		['=']="10"
		['│']="45"
		['┤']="46"
		['┐']="47"
		['└']="48"
		['┴']="49"
		['┬']="4A"
		['├']="4B"
		['─']="4C"
		['┼']="4D"
		['┘']="4E"
		['┌']="4F"
		['█']="50"

	)

	while true; do

		read -rN 1 in
		if [ "$in" == $'\n' ]; then

			echo
			continue;

		fi

		[ -z "$in" ] && break

		result=${map["$in"]}
		if [ -n "$result" ]; then

			echo -n "$result "
			continue

		fi

		in=$(printf "%d" "'$in")
		idx=0

		checkRange '♪' '♫' && continue

		((idx++))

		checkRange '(' ')' && continue
		checkRange '0' ':' && continue

		((idx++))
		
		checkRange 'A' 'Z' && continue
		checkRange 'a' 'z' && continue

		echo "Invalid character: $in" > /dev/stderr
		break;

	done

}
