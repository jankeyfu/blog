#/bin/bash

echo "starting sync..."
read -p "pls type commit msg:" msg
echo $msg

# 修改更新时间
function changeUpdateTime(){
    git add .
    files=`git diff --cached --name-only`
    for file in ${files[@]}
    do 
        if [[ $file == content/posts/* ]];
        then
            # echo $file
            changeFileLastmod $file
        fi
    done
}

# 修改某个文件的lastmod数值
function changeFileLastmod(){
    file="$1"
    time=`date '+%Y-%m-%dT%H:%M:%S+08:00'`
    reg="s/lastmod.*/lastmod: $time/"
    # echo "sed -i '' $reg $file"
    sed -i '' "$reg" "$file"
}

function syncGit(){
    cd $1
    time=`date '+%Y-%m-%d %H:%M:%S'`
    cnt=`git status |grep "nothing to commit" |wc -l`
    if [ $cnt -eq 0 ];then
        echo "\033[32mstart sync:$1\033[0m"
        git add .
        git commit -m "$2"
        git push --no-verify
        echo "\033[32msync over:$1\033[0m"
    else
        echo "\033[31mnothing to commit:$1"
    fi
}
# 先修改更新时间
changeUpdateTime
# 再编译
hugo -D
# 最后sync submodule
syncGit ~/blog/public "$msg"
syncGit ~/blog "$msg"