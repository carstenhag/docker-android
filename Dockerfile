FROM ubuntu:22.04

# Required for Jenv
SHELL ["/bin/bash", "-c"]

## Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

## Use unicode
RUN apt-get update && apt-get -y install locales && \
    locale-gen en_US.UTF-8 || true
ENV LANG=en_US.UTF-8

## Install dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
  openjdk-21-jdk \
  openjdk-17-jdk \
  git \
  wget \
  curl \
  build-essential \
  zlib1g-dev \
  libssl-dev \
  libreadline-dev \
  unzip \
  ssh

## Clean dependencies
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

## Install jenv
ENV JENV_ROOT "$HOME/.jenv"
RUN git clone https://github.com/jenv/jenv.git $JENV_ROOT
ENV PATH "$PATH:$JENV_ROOT/bin"
RUN mkdir $JENV_ROOT/versions
ENV JDK_ROOT "/usr/lib/jvm/"
RUN jenv add ${JDK_ROOT}/java-8-openjdk-amd64
RUN jenv add ${JDK_ROOT}/java-11-openjdk-amd64
RUN jenv add ${JDK_ROOT}/java-21-openjdk-amd64
RUN jenv add ${JDK_ROOT}/java-17-openjdk-amd64
RUN echo 'export PATH="$JENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(jenv init -)"' >> ~/.bashrc


## Install Android SDK
ARG sdk_version=commandlinetools-linux-6200805_latest.zip
ARG android_home=/opt/android/sdk
ARG android_api=android-34
ARG android_build_tools=34.0.0
ARG ndk_version=26.3.11579264
ARG cmake=3.22.1
RUN mkdir -p ${android_home} && \
    wget --quiet --output-document=/tmp/${sdk_version} https://dl.google.com/android/repository/${sdk_version} && \
    unzip -q /tmp/${sdk_version} -d ${android_home} && \
    rm /tmp/${sdk_version}

# Set environmental variables
ENV ANDROID_HOME ${android_home}
ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN mkdir ~/.android && echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg

RUN yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses
RUN sdkmanager --sdk_root=$ANDROID_HOME --install \
  "platform-tools" \
  "build-tools;${android_build_tools}" \
  "platforms;${android_api}"
RUN echo "Installing Android NDK ($ndk_version, cmake: $cmake)"; \
  sdkmanager --sdk_root="$ANDROID_HOME" --install \
  "ndk;${ndk_version}" \
  "cmake;${cmake}" ;