#/bin/bash -ex

LIST=`/bin/cat /gitlab/gitlabrepo.txt`

for i in $LIST
do
	echo $i

	git clone --mirror git@my.domain.com:$i
	echo " "

done
