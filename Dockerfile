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

# 步骤四 安装Android NDK 22.1.7171670
RUN yes | /usr/local/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/usr/local/android-sdk "ndk;22.1.7171670" 

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

# 添加自定义 .bashrc 内容
RUN echo 'echo Echo Qt Android Project Build Instructions' >> /root/.bashrc
RUN echo 'echo 1. Build the project' >> /root/.bashrc
RUN echo 'echo Navigate to the project directory inside the container and compile the project:' >> /root/.bashrc
RUN echo 'echo cd /workspace/your-project-name' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo Create a build directory' >> /root/.bashrc
RUN echo 'echo mkdir -p build' >> /root/.bashrc
RUN echo 'echo cd build' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo For qmake users' >> /root/.bashrc
RUN echo 'echo qmake ../ -spec android-clang ANDROID_ABIS=\"arm64-v8a\" \"CONFIG+=release\"' >> /root/.bashrc
RUN echo 'echo make -j4' >> /root/.bashrc
RUN echo 'echo make INSTALL_ROOT=/workspace/your-project-name/build/<your-project-name>-build install' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo For CMake users' >> /root/.bashrc
RUN echo 'echo cd /workspace/your-project-name' >> /root/.bashrc
RUN echo 'echo cmake --build ./build --target all' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo 2. Generate the APK' >> /root/.bashrc
RUN echo 'echo After a successful build, use the androiddeployqt tool to package the project as an APK file:' >> /root/.bashrc
RUN echo 'echo androiddeployqt --input android-libYourProjectName.so-deployment-settings.json --output /workspace/your-project-name/build/<your-project-name>-build --android-platform android-31 --jdk /usr/local/jdk8' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo The generated APK file will be located in the /workspace/your-project-name/build/<your-project-name>-build directory.' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo 3. Cleanup' >> /root/.bashrc
RUN echo 'echo After the build is complete, you can exit the Docker container and retrieve the APK file on your host system:' >> /root/.bashrc
RUN echo 'echo exit' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo 4. Notes' >> /root/.bashrc
RUN echo 'echo Ensure that the input file name for androiddeployqt matches your project name.' >> /root/.bashrc
RUN echo 'echo If you need to modify the Qt version or Android SDK version, adjust the relevant parameters in the Dockerfile.' >> /root/.bashrc
RUN echo 'echo' >> /root/.bashrc
RUN echo 'echo Environment Variables:' >> /root/.bashrc
RUN echo 'echo export QTDIR=$QTDIR' >> /root/.bashrc
RUN echo 'echo export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT' >> /root/.bashrc
RUN echo 'echo export ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT' >> /root/.bashrc
RUN echo 'echo export JAVA_HOME=$JAVA_HOME' >> /root/.bashrc
RUN echo 'echo export PATH=$PATH' >> /root/.bashrc

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
