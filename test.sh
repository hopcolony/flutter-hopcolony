project=${1:-}

root=$PWD

if [ -z "$project" ]
then
    cd $root/packages/hop_init && flutter test
    cd $root/packages/hop_drive && flutter test 
    cd $root/packages/hop_doc && flutter test
    cd $root/packages/hop_auth && flutter test
    cd $root/packages/hop_topic && flutter test
else
    cd $root/packages/$project && flutter test
fi