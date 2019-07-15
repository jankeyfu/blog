#/bin/bash

echo "starting sync..."

time=`date '+%Y-%m-%d %H:%M:%S'`
read -p "pls type commit msg:" msg
echo $msg

function syncGit(){
    cd $1
    time=`date '+%Y-%m-%d %H:%M:%S'`
    cnt=`git status |grep "nothing to commit" |wc -l`
    if [ $cnt -eq 0 ];then
        echo "\033[32mstart sync:$1\033[0m"
        git add .
        git commit -m "$2"
        git push
        echo "\033[32msync over:$1\033[0m"
    else
        echo "\033[31mnothing to commit:$1"
    fi
}

syncGit ~/blog "$msg"
syncGit ~/blog/public "$msg"