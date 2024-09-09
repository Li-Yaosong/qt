# 步骤一 下载Qt

FROM liyaosong/kylin:v10.1-sp1-amd64 as builder

# 设置非交互式前端（避免构建过程中的交互式提示）

ENV DEBIAN_FRONTEND=noninteractive

#接受一个传参

ARG QT_VERSION=6.6.3
ARG QT_ARCH=wasm_singlethread
ARG PIP_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple

# 安装aqtinstall和Qt的先决条件

RUN apt-get update -y
RUN apt-get install -y python3-pip 
RUN pip3 install -i ${PIP_MIRROR} --upgrade pip
RUN pip3 install -i ${PIP_MIRROR} aqtinstall


# 使用aqtinstall安装Qt gcc_64 和 wasm_singlethread

RUN aqt install-qt linux desktop ${QT_VERSION} gcc_64  --modules $(aqt list-qt linux desktop --modules ${QT_VERSION} ${QT_ARCH}) --outputdir /home/Qt

RUN aqt install-qt linux desktop ${QT_VERSION} ${QT_ARCH}  --modules $(aqt list-qt linux desktop --modules ${QT_VERSION} ${QT_ARCH}) --outputdir /home/Qt

# 步骤二 构建Qt镜像
FROM liyaosong/kylin:v10.1-sp1-amd64 AS Qt

WORKDIR /home

# 设置非交互式前端（避免构建过程中的交互式提示）

ENV DEBIAN_FRONTEND=noninteractive

# 从上一个步骤中拷贝Qt

COPY --from=builder /home/Qt /home/Qt

# 安装Qt的先决条件

RUN apt-get update && apt-get install -y git curl jq python-is-python3 \
    build-essential \
    libglib2.0-0 \
    libgl1-mesa-dev \
    libfontconfig1 \
    libxrender1 \
    libxkbcommon-dev \
    libxkbcommon-x11-0 \
    libdbus-1-3 \
    libssl-dev \
    libcurlpp-dev \
    libinih-dev \
    nlohmann-json3-dev \
    libpugixml-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libpcap-dev


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

# 安装emsdk
ARG EM_VERSION=3.1.37
RUN git clone https://github.com/emscripten-core/emsdk.git

RUN cd emsdk && ./emsdk install ${EM_VERSION} && ./emsdk activate ${EM_VERSION}

# 步骤三 构建最终镜像
FROM scratch

ARG QT_VERSION=6.6.3

LABEL maintainer="liyaosong <yslids@isoftstone.com>"

LABEL version="${QT_VERSION}"

LABEL description="Qt version ${QT_VERSION}."

COPY --from=Qt / /

# 设置Qt环境变量,emsdk环境变量

ENV QT_DIR=/home/Qt/${QT_VERSION}/gcc_64

ENV EMSDK=/home/emsdk

ENV EMSDK_NODE=/home/emsdk/node/16.20.0_64bit/bin/node

ENV PATH=$EMSDK:$EMSDK/upstream/emscripten:$QT_DIR/bin:$PATH

ENV LD_LIBRARY_PATH=$QT_DIR/lib:$LD_LIBRARY_PATH

ENV DISPLAY=host.docker.internal:0

CMD ["bash"]

