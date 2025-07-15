# 步骤一 下载Qt

FROM liyaosong/aqtinstall AS qt-builder

# 设置非交互式前端（避免构建过程中的交互式提示）

ENV DEBIAN_FRONTEND=noninteractive

#接受一个传参

ARG QT_VERSION=5.15.2
ARG QT_ARCH=gcc_64

RUN aqt install-qt linux desktop ${QT_VERSION} ${QT_ARCH}  \
    -m $(for mod in $(aqt list-qt linux desktop --modules ${QT_VERSION} ${QT_ARCH}); \
    do [[ "$mod" != *debug_info* ]] && echo -n "$mod "; done) --outputdir /Qt

# 步骤二 构建Qt镜像
FROM liyaosong/ubuntu:20.04 AS final

WORKDIR /home

# 设置非交互式前端（避免构建过程中的交互式提示）

ENV DEBIAN_FRONTEND=noninteractive

# 从上一个步骤中拷贝Qt

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

ARG QT_VERSION=5.15.2

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

