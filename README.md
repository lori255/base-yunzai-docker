# 云崽通用基础镜像
DockerHub镜像地址：https://hub.docker.com/r/lori255/base-yunzai

1. **端口映射**，例如锅巴50831，或者设置为host。
2. **环境变量（必填）**：`YUNZAI_REPO_URL`=云崽仓库地址（喵版云崽或者TRSS版本）
   - TRSS版云崽仓库地址：https://gitee.com/TimeRainStarSky/Yunzai.git
   - 喵版云崽仓库地址：https://gitee.com/yoimiya-kokomi/Miao-Yunzai.git
3. **目录映射**：云崽目录在 `/app/Yunzai` ，推荐映射，否则删除容器将会导致**数据丢失**！！！

镜像启动脚本会自动下载：锅巴插件（**[Guoba-Plugin](https://gitee.com/guoba-yunzai/guoba-plugin)**）、喵喵插件（**[miao-plugin](https://gitee.com/yoimiya-kokomi/miao-plugin)**）
从喵版`Dockerfile`文件和`docker-entrypoint.sh`修改而来（**修改了一丢丢**）
启动容器：
```bash
docker run \
    --name Yunzai \
    --network bridge \
    -p 2536:2536 \
    -p 50831:50831 \
    -e YUNZAI_REPO_URL=https://gitee.com/TimeRainStarSky/Yunzai.git \
    -v /disk/ssddata/NodeProjects/Yunzai:/app/Yunzai \
    lori255/base-yunzai:latest
```

