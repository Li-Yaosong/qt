# 步骤一 下载Qt
FROM liyaosong/aqtinstall AS qt-builder

ARG QT_VERSION=5.12.12
RUN aqt install-qt linux desktop ${QT_VERSION} gcc_64  --modules all --outputdir /Qt
RUN aqt install-tool linux desktop tools_cmake --outputdir /


FROM liyaosong/ubuntu:20.04 AS final

COPY --from=qt-builder /Qt /home/Qt
COPY --from=qt-builder /Tools/CMake /usr/local/cmake
# 安装Qt的先决条件

RUN apt-get update && apt-get install -y git \
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

ARG QT_VERSION=5.12.12

LABEL maintainer="liyaosong <liyaosong1@qq.com>"

LABEL version="${QT_VERSION}"

LABEL description="Qt version ${QT_VERSION}."

# 设置Qt环境变量

ENV QT_DIR=/home/Qt/${QT_VERSION}/gcc_64

ENV PATH=$QT_DIR/bin:$PATH

ENV LD_LIBRARY_PATH=$QT_DIR/lib

ENV DISPLAY=host.docker.internal:0

CMD ["bash"]
