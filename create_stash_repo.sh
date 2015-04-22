#/bin/bash -ex

LIST=`/bin/cat /gitlab/gitlabrepo.txt`

for i in $LIST
do
    echo $i

curl -X POST -H "Authorization: Basic skfjslflsfksdlfslfskjxxxx" -H "Content-Type: application/json" http://stash.mydomain.net/rest/api/1.0/projects/GITLAB/repos --data "{\"name\":\"$i\", \"forkable\":true }"

    echo " "
done
