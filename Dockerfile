# Stage 1: Resource Stage
FROM busybox:latest AS resource
ADD docker-entrypoint.sh /res/entrypoint.sh
RUN dos2unix /res/entrypoint.sh \
    && chmod +x /res/entrypoint.sh

# Stage 2: Runtime Stage
FROM node:lts-bullseye-slim AS runtime

# Set environment variables
ARG BUNDLE_FFMPEG=true
ARG BUNDLE_POETRY=false
ARG USE_APT_MIRROR=true
ARG USE_NPM_MIRROR=true
ARG USE_PYPI_MIRROR=true

ENV BUNDLE_FFMPEG=${BUNDLE_FFMPEG} \
    BUNDLE_POETRY=${BUNDLE_POETRY} \
    USE_APT_MIRROR=${USE_APT_MIRROR} \
    USE_NPM_MIRROR=${USE_NPM_MIRROR} \
    USE_PYPI_MIRROR=${USE_PYPI_MIRROR}

# Update and install dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y wget xz-utils dos2unix curl gnupg git fonts-wqy-microhei xfonts-utils chromium fontconfig libxss1 libgl1 vim jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Conditionally install FFmpeg
RUN if [ "$BUNDLE_FFMPEG" = "true" ]; then \
    wget -q https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-$(dpkg --print-architecture)-static.tar.xz \
    && mkdir -p /res/ffmpeg \
    && tar -xvf ./ffmpeg-git-$(dpkg --print-architecture)-static.tar.xz -C /res/ffmpeg --strip-components 1 \
    && cp /res/ffmpeg/ffmpeg /usr/bin/ffmpeg \
    && cp /res/ffmpeg/ffprobe /usr/bin/ffprobe \
    && rm ./ffmpeg-git-$(dpkg --print-architecture)-static.tar.xz; \
    fi

# Conditionally install Poetry
RUN if [ "$BUNDLE_POETRY" = "true" ]; then \
    apt-get update \
    && apt-get install -y python3-pip python3-venv \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && POETRY_HOME=$HOME/venv-poetry \
    && python -m venv $POETRY_HOME \
    && _PYPI_MIRROR_FLAG="" \
    && if [ "$USE_PYPI_MIRROR" = "true" ]; then _PYPI_MIRROR_FLAG="-i https://pypi.tuna.tsinghua.edu.cn/simple"; fi \
    && $POETRY_HOME/bin/pip install --upgrade pip setuptools $_PYPI_MIRROR_FLAG \
    && $POETRY_HOME/bin/pip install poetry $_PYPI_MIRROR_FLAG \
    && ln -s $POETRY_HOME/bin/poetry /usr/bin \
    && poetry config virtualenvs.in-project true \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Install global npm packages with conditional registry
RUN if [ "$USE_NPM_MIRROR" = "true" ]; then \
    npm install -g pnpm yarn --registry=https://registry.npmmirror.com; \
    else \
    npm install -g pnpm yarn; \
    fi

# Configure git
RUN git config --global --add safe.directory '*' \
    && git config --global pull.rebase false \
    && git config --global user.email "2539939333@qq.com" \
    && git config --global user.name "lori"

# Cleanup
RUN apt-get autoremove -y \
    && rm -rf /tmp/* \
    && fc-cache -f -v

# Stage 3: Production Stage
FROM runtime AS prod

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

RUN mkdir -p /app/Yunzai

COPY --from=resource /res/entrypoint.sh /app/entrypoint.sh

WORKDIR /app/Yunzai

ENTRYPOINT ["/app/entrypoint.sh"]
