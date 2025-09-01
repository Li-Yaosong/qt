# 步骤一 下载Qt
FROM liyaosong/aqtinstall AS qt-builder

ARG QT_VERSION=6.8.3
ARG QT_ARCH=linux_gcc_64
ARG QT_HOST=linux

SHELL ["/bin/bash", "-c"]

RUN echo '#!/bin/bash' >> /install-qt.sh && \
    echo 'if [ `uname -m` == "aarch64" ]; then' >> /install-qt.sh && \
    echo '    export QT_ARCH=linux_gcc_arm64' >> /install-qt.sh && \
    echo '    export QT_HOST=linux_arm64' >> /install-qt.sh && \
    echo 'fi' >> /install-qt.sh && \
    echo 'echo Installing Qt ${QT_VERSION} for ${QT_ARCH} on ${QT_HOST}' >> /install-qt.sh && \
    echo 'aqt install-qt ${QT_HOST} desktop ${QT_VERSION} ${QT_ARCH} \' >> /install-qt.sh && \
    echo '-m $(for mod in $(aqt list-qt ${QT_HOST} desktop --modules ${QT_VERSION} ${QT_ARCH}); \' >> /install-qt.sh && \
    echo 'do [[ "$mod" != *debug_info* ]] && echo -n "$mod "; done) --outputdir /Qt' >> /install-qt.sh

RUN chmod +x /install-qt.sh && /install-qt.sh

FROM liyaosong/ubuntu:noble AS final

COPY --from=qt-builder /Qt /home/Qt
# 安装Qt的先决条件

RUN apt-get update && apt-get install -y git \
    cmake \
    build-essential \
    libglib2.0-0 \
    libgl1-mesa-dev \
    libfontconfig1 \
    libxrender1 \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    libdbus-1-3

# 清理其他不再需要的包

RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /root/.cache \
    /var/cache/apt/archives/*.deb \
    /var/cache/apt/*.bin \
    /var/lib/apt/lists/* \
    /usr/share/*/*/*/*.gz \
    /usr/share/*/*/*.gz \
    /usr/share/*/*.gz \
    /usr/share/doc/*/README* \
    /usr/share/doc/*/*.txt \
    /usr/share/locale/*/LC_MESSAGES/*.mo 

FROM scratch

COPY --from=final / /

ARG QT_VERSION=6.8.3

LABEL maintainer="liyaosong <liyaosong1@qq.com>"
LABEL version="${QT_VERSION}"
LABEL description="Qt version ${QT_VERSION}."
# 创建用户并指定 home 目录
RUN useradd -m -d /home/Qt -s /bin/bash Qt && \
    chown -R Qt:Qt /home/Qt

USER Qt

WORKDIR /home/Qt

# 设置Qt环境变量

ENV QT_DIR=/home/Qt/${QT_VERSION}/gcc_64
ENV PATH=$QT_DIR/bin:$PATH
ENV LD_LIBRARY_PATH=$QT_DIR/lib
ENV DISPLAY=host.docker.internal:0

CMD ["qmake"]
