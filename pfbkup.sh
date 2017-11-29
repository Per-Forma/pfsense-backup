if [ ! -d 'cookies/' ]; then
	echo 'Making Cookies Directory'
	mkdir cookies
fi
while read hostline
do
	iscomment=$(echo $hostline | grep -Po '^.')
	if [ "$iscomment" == '#' ]; then #This Skips Lines that begin with the # charachater
		continue
	fi

	hostlinenowhitespace="$(echo -e "${hostline}" | tr -d '[:space:]')"
	linesize=$(echo $hostlinenowhitespace | wc -m)
	if [ ! $linesize -ge 5 ]; then #This skips lines that are empty or too small to contain connection information
		continue
	fi

	position=0
	for word in $hostline
	do 
		declare param${position}=$word
		position=$((position+1))
		#echo $word
	done

	param2=${param2::-1}
	./cURLpfbkup.sh $param0 $param1 $param2
done < pfhosts