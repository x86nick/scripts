#/bin/bash -ex

LIST=`/bin/cat /gitlab/gitlabrepo.txt`

for i in $LIST
do
        echo $i
        cd $i.git
        git push --all stash && git push --tags stash
        cd ..
        echo " "

done
