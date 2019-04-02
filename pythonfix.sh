#!/bin/bash
x=`python -V 2>&1 | awk -F " " '{print $2}' | cut -d "." -f1`
python_check()
{
   if [ $x == 2 ];then
      echo "good bye"
      exit
   else
      python3_check
      python_version
    fi
}

python3_check()
{
        if [ -f /usr/bin/python ];then
          mv /usr/bin/python /usr/bin/python3
        else
           echo "你的python呢？"
           exit
        fi

        if [ -f /usr/bin/python2.7  ];then
           mv /usr/bin/python2.7 /usr/bin/python
        else
           echo "你的python2呢？兄弟??"
           echo "没用python2 可以上天了！！！！"
           echo "不过没事，去论坛发个帖子也行的"
           mv /usr/bin/python3 /usr/bin/python
           exit
        fi
}

python_version()
{
        cc=`python -V 2>&1 |cut -b 8`
        if [ $cc==2 ];then
            echo "哟西！修复完成"
        else
            echo "还需要努力！！没用修复成功.；；联系作者小强1249648969"
        fi
}

python_check
