# Stage 1: Build Stage — download FFmpeg and prepare entrypoint.
# Build-only tools (wget, xz-utils, dos2unix) are discarded with this stage.
FROM node:lts-bullseye-slim AS builder

ARG BUNDLE_FFMPEG=true

RUN mkdir -p /opt/ffmpeg-bin \
    && apt-get update \
    && apt-get install -y --no-install-recommends wget xz-utils dos2unix ca-certificates \
    && if [ "$BUNDLE_FFMPEG" = "true" ]; then \
       ARCH=$(dpkg --print-architecture) \
       && wget -q "https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-${ARCH}-static.tar.xz" \
       && mkdir -p /tmp/ffmpeg \
       && tar -xf "./ffmpeg-git-${ARCH}-static.tar.xz" -C /tmp/ffmpeg --strip-components 1 \
       && mv /tmp/ffmpeg/ffmpeg  /opt/ffmpeg-bin/ffmpeg \
       && mv /tmp/ffmpeg/ffprobe /opt/ffmpeg-bin/ffprobe \
       && chmod +x /opt/ffmpeg-bin/* \
       && rm -rf /tmp/ffmpeg "./ffmpeg-git-${ARCH}-static.tar.xz"; \
    fi \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /opt/entrypoint.sh
RUN dos2unix /opt/entrypoint.sh && chmod +x /opt/entrypoint.sh

# Stage 2: Production Stage — lean runtime image
FROM node:lts-bullseye-slim AS prod

ARG BUNDLE_POETRY=false
ARG USE_NPM_MIRROR=true
ARG USE_PYPI_MIRROR=true

# Runtime packages only — no build tools.
# Single layer: install + font-cache + cleanup.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl gnupg git jq \
       fonts-wqy-microhei xfonts-utils fontconfig \
       chromium libxss1 libgl1 \
    && fc-cache -f -v \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Copy FFmpeg binaries from builder (no-op if BUNDLE_FFMPEG was false)
COPY --from=builder /opt/ffmpeg-bin/ /usr/local/bin/

# Conditionally install Poetry (needs python3 at runtime, so stays in prod)
RUN if [ "$BUNDLE_POETRY" = "true" ]; then \
       apt-get update \
       && apt-get install -y --no-install-recommends python3-pip python3-venv \
       && ln -sf /usr/bin/python3 /usr/bin/python \
       && POETRY_HOME=$HOME/venv-poetry \
       && python -m venv "$POETRY_HOME" \
       && _PYPI_MIRROR_FLAG="" \
       && if [ "$USE_PYPI_MIRROR" = "true" ]; then \
              _PYPI_MIRROR_FLAG="-i https://pypi.tuna.tsinghua.edu.cn/simple"; \
          fi \
       && "$POETRY_HOME/bin/pip" install --upgrade pip setuptools $_PYPI_MIRROR_FLAG \
       && "$POETRY_HOME/bin/pip" install poetry $_PYPI_MIRROR_FLAG \
       && ln -s "$POETRY_HOME/bin/poetry" /usr/local/bin/poetry \
       && poetry config virtualenvs.in-project true \
       && apt-get clean \
       && rm -rf /var/lib/apt/lists/*; \
    fi

# Install global npm packages and clean cache
RUN if [ "$USE_NPM_MIRROR" = "true" ]; then \
       npm install -g pnpm yarn --registry=https://registry.npmmirror.com --force; \
    else \
       npm install -g pnpm yarn --force; \
    fi \
    && npm cache clean --force

# Configure git
RUN git config --global --add safe.directory '*' \
    && git config --global pull.rebase false \
    && git config --global user.email "2539939333@qq.com" \
    && git config --global user.name "lori"

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

RUN mkdir -p /app/Yunzai

COPY --from=builder /opt/entrypoint.sh /app/entrypoint.sh

WORKDIR /app/Yunzai

ENTRYPOINT ["/app/entrypoint.sh"]
