#!/usr/bin/env bash

set +e

GreenBG="\\033[42;37m"
YellowBG="\\033[43;37m"
BlueBG="\\033[44;37m"
Font="\\033[0m"

Version="${BlueBG}[版本]${Font}"
Info="${GreenBG}[信息]${Font}"
Warn="${YellowBG}[提示]${Font}"

WORK_DIR="/app/Yunzai"
YUNZAI_REPO_URL=${YUNZAI_REPO_URL}
YUNZAI_REPO_BRANCH=${YUNZAI_REPO_BRANCH:-master}
PM2_LOGS_LINES=${PM2_LOGS_LINES:-2000}

if [[ ! -d "$HOME/.ovo" ]]; then
    mkdir ~/.ovo
fi

if [[ -z $YUNZAI_REPO_URL ]]; then
    echo -e "\n ================ \n ${Warn} ${YellowBG} 未设置环境变量 YUNZAI_REPO_URL ${Font} \n ================ \n"
    exit 1
fi

echo -e "\n ================ \n ${Info} ${GreenBG} 拉取 Yunzai 更新 ${Font} \n ================ \n"
cd $WORK_DIR
if [ ! -d $WORK_DIR"/.git" ]; then
    echo -e "\n ${Warn} ${YellowBG} 检测到云崽目前没有安装，开始自动下载 ${Font} \n"
    git clone --depth=1 $YUNZAI_REPO_URL --branch $YUNZAI_REPO_BRANCH $WORK_DIR
fi

if [[ -z $(git status -s) ]]; then
    echo -e " ${Warn} ${YellowBG} 当前工作区有修改，尝试暂存后更新。${Font}"
    git add .
    git stash
    git pull origin $YUNZAI_REPO_BRANCH --allow-unrelated-histories --rebase
    git stash pop
else
    git pull origin $YUNZAI_REPO_BRANCH --allow-unrelated-histories
fi

if [[ ! -f "$HOME/.ovo/yunzai.ok" ]]; then
    set -e
    echo -e "\n ================ \n ${Info} ${GreenBG} 更新 Miao-Yunzai 运行依赖 ${Font} \n ================ \n"
    pnpm install
    touch ~/.ovo/yunzai.ok
    set +e
fi

echo -e "\n ================ \n ${Version} ${BlueBG} Yunzai 版本信息 ${Font} \n ================ \n"
git log -1 --pretty=format:"%h - %an, %ar (%cd) : %s"


set -e

cd $WORK_DIR

echo -e "\n ================ \n ${Info} ${GreenBG} 初始化 Docker 环境 ${Font} \n ================ \n"

if [ -f "./config/config/redis.yaml" ]; then
    sed -i 's/127.0.0.1/redis/g' ./config/config/redis.yaml
    echo -e "\n  修改Redis地址完成~  \n"
fi

echo -e "\n ================ \n ${Info} ${GreenBG} 启动 Yunzai ${Font} \n ================ \n"

set +e
pnpm start
EXIT_CODE=$?

if [[ $EXIT_CODE != 0 ]]; then
	echo -e "\n ================ \n ${Warn} ${YellowBG} 启动 Yunzai 失败 ${Font} \n ================ \n"
	tail -f /dev/null
fi
/app/Yunzai/node_modules/pm2/bin/pm2 logs --lines $PM2_LOGS_LINES
