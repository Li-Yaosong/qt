# 步骤一 下载Qt
FROM liyaosong/aqtinstall AS qt-builder

ARG QT_VERSION=5.15.2
RUN aqt install-qt linux android ${QT_VERSION} android  --modules all --outputdir /Qt
RUN aqt install-tool linux desktop tools_cmake --outputdir /

FROM openjdk:17.0.2-jdk-slim AS android-builder

# 步骤二 下载Android SDK
ARG ANDROID_SDK_VERSION=9123335
ARG ANDROID_SDK_URL=https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip

RUN apt-get update && apt-get install -y wget unzip && \
    wget ${ANDROID_SDK_URL} && \
    unzip commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip -d /usr/local/temp && \
    rm commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    cd /usr/local/temp && \
    wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u422-b05/OpenJDK8U-jdk_x64_linux_hotspot_8u422b05.tar.gz && \
    tar -zxvf OpenJDK8U-jdk_x64_linux_hotspot_8u422b05.tar.gz && \
    mv jdk8u422-b05 /usr/local/jdk8
#在解压缩的 cmdline-tools 目录中，创建一个名为 latest 的子目录。
RUN mkdir /usr/local/android-sdk && \
    mkdir /usr/local/android-sdk/cmdline-tools && \
    mv /usr/local/temp/cmdline-tools /usr/local/android-sdk/cmdline-tools/latest

# 步骤三 安装Android SDK 31
RUN yes | /usr/local/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/usr/local/android-sdk "platforms;android-31" 

# 步骤四 安装Android NDK 22.1.7171670 25.1.8937393
RUN yes | /usr/local/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/usr/local/android-sdk "ndk;22.1.7171670" 
RUN yes | /usr/local/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/usr/local/android-sdk "ndk;25.1.8937393"

# 步骤五 安装Android Build Tools 31.0.0
RUN yes | /usr/local/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/usr/local/android-sdk "build-tools;31.0.0"

# 步骤六 安装Android Platform Tools
RUN yes | /usr/local/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/usr/local/android-sdk "platform-tools"

# 步骤七 安装Gradle
ARG GRADLE_VERSION=5.6.4
ARG GRADLE_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
RUN cd /usr/local && \
    wget ${GRADLE_URL}

FROM liyaosong/ubuntu:20.04 AS final

ARG GRADLE_VERSION=5.6.4
COPY --from=qt-builder /Qt /home/Qt
COPY --from=qt-builder /Tools/CMake /usr/local/cmake
COPY --from=android-builder /usr/local/jdk8 /usr/local/jdk8
COPY --from=android-builder /usr/local/android-sdk /usr/local/android-sdk
COPY --from=android-builder /usr/local/gradle-${GRADLE_VERSION}-bin.zip /root/.gradle/wrapper/dists/gradle-${GRADLE_VERSION}-bin/bxirm19lnfz6nurbatndyydux/

FROM scratch

COPY --from=final / /

ENV QTDIR=/home/Qt/5.15.2/android
ENV ANDROID_SDK_ROOT=/usr/local/android-sdk
ENV ANDROID_NDK_ROOT=/usr/local/android-sdk/ndk/22.1.7171670
ENV JAVA_HOME=/usr/local/jdk8
ENV PATH=$PATH:/home/Qt/5.15.2/android/bin
ENV PATH=$PATH:/usr/local/cmake/bin
ENV PATH=$PATH:/usr/local/jdk8/bin
ENV PATH=$PATH:/usr/local/android-sdk/platform-tools
ENV PATH=$PATH:/usr/local/android-sdk/build-tools/31.0.0
ENV PATH=$PATH:/usr/local/android-sdk/ndk/22.1.7171670/prebuilt/linux-x86_64/bin

CMD ["/bin/bash"]
