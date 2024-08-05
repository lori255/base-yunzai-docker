FROM busybox:latest AS resource
ADD docker-entrypoint.sh /res/entrypoint.sh

RUN dos2unix /res/entrypoint.sh \
    && chmod +x /res/entrypoint.sh


FROM node:lts-bullseye-slim AS runtime

ARG BUNDLE_FFMPEG=true
ARG BUNDLE_POETRY=false
ARG USE_APT_MIRROR=true
ARG USE_NPM_MIRROR=true
ARG USE_PYPI_MIRROR=true

RUN export BUNDLE_FFMPEG=${BUNDLE_FFMPEG:-true} \
    && export BUNDLE_POETRY=${BUNDLE_POETRY:-true} \
    && export USE_APT_MIRROR=${USE_APT_MIRROR:-true} \
    && export USE_NPM_MIRROR=${USE_NPM_MIRROR:-true} \
    && export USE_PYPI_MIRROR=${USE_PYPI_MIRROR:-true} \
    \
    && ((test "$USE_APT_MIRROR"x = "true"x \
    && sed -i "s/deb.debian.org/mirrors.ustc.edu.cn/g" /etc/apt/sources.list) || true) \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y wget xz-utils dos2unix \
    && ((test "$BUNDLE_FFMPEG"x = "true"x \
    && wget https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-$(dpkg --print-architecture)-static.tar.xz \
    && mkdir -p /res/ffmpeg \
    && tar -xvf ./ffmpeg-git-$(dpkg --print-architecture)-static.tar.xz -C /res/ffmpeg --strip-components 1 \
    && cp /res/ffmpeg/ffmpeg /usr/bin/ffmpeg \
    && cp /res/ffmpeg/ffprobe /usr/bin/ffprobe) || true) \
    \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl wget gnupg git fonts-wqy-microhei xfonts-utils chromium fontconfig libxss1 libgl1 vim jq \
    && apt-get autoremove \
    && apt-get clean \
    \
    && fc-cache -f -v \
    \
    && git config --global --add safe.directory '*' \
    && git config --global pull.rebase false \
    && git config --global user.email "2539939333@qq.com" \
    && git config --global user.name "lori" \
    \
    && _NPM_MIRROR_FLAG="" \
    && if [ "$USE_NPM_MIRROR"x = "true"x ]; then _NPM_MIRROR_FLAG="--registry=https://registry.npmmirror.com"; fi \
    && npm install pnpm -g $_NPM_MIRROR_FLAG \
    \
    && ((test "$BUNDLE_POETRY"x = "true"x \
    && apt-get update \
    && apt-get install -y python3-pip python3-venv \
    && apt-get autoremove \
    && apt-get clean \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && POETRY_HOME=$HOME/venv-poetry \
    && python -m venv $POETRY_HOME \
    && _PYPI_MIRROR_FLAG="" \
    && if [ "$USE_PYPI_MIRROR"x = "true"x ]; then _PYPI_MIRROR_FLAG="-i https://pypi.tuna.tsinghua.edu.cn/simple"; fi \
    && $POETRY_HOME/bin/pip install --upgrade pip setuptools $_PYPI_MIRROR_FLAG \
    && $POETRY_HOME/bin/pip install poetry $_PYPI_MIRROR_FLAG \
    && ln -s $POETRY_HOME/bin/poetry /usr/bin \
    && poetry config virtualenvs.in-project true) || true) \
    \
    && rm -rf /var/cache/* \
    && rm -rf /tmp/*


FROM runtime AS prod

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

RUN mkdir -p /app/Yunzai

COPY --from=resource /res/entrypoint.sh /app/entrypoint.sh

WORKDIR /app/Yunzai

ENTRYPOINT ["/app/entrypoint.sh"]
