FROM ros:jazzy

ARG USERNAME=andrii
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update -q && \
	export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends \
        vim tar xz-utils \
        libx11-6 libxcb1 libxau6 libgl1-mesa-dev \
        xvfb dbus-x11 x11-utils libxkbcommon-x11-0 \
        libavcodec-dev libavformat-dev libswscale-dev \
        python3 python3-pip python3-venv libraw1394-11 libmpfr6 \
        libusb-1.0-0 \
        libxcb-xinerama0 \
        && \
    apt-get autoclean -y && apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /shared /opt

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip3 install pyzmq cbor2

COPY ./download/CoppeliaSim_Edu_V4_10_0_rev0_Ubuntu24_04.tar.xz /opt/
RUN tar -xf /opt/CoppeliaSim_Edu_V4_10_0_rev0_Ubuntu24_04.tar.xz -C /opt && \
    rm /opt/CoppeliaSim_Edu_V4_10_0_rev0_Ubuntu24_04.tar.xz

ENV COPPELIASIM_ROOT_DIR=/opt/CoppeliaSim_Edu_V4_10_0_rev0_Ubuntu24_04
ENV LD_LIBRARY_PATH=$COPPELIASIM_ROOT_DIR:$LD_LIBRARY_PATH
ENV PATH=$COPPELIASIM_ROOT_DIR:$PATH

# RUN echo '#!/bin/bash\ncd $COPPELIASIM_ROOT_DIR\n/usr/bin/xvfb-run --server-args "-ac -screen 0, 1024x1024x24" coppeliaSim "$@"' > /entrypoint && chmod a+x /entrypoint
# Run CoppeliaSim with the -h option (you can also specify a license key with -Glicense=licenseKey or use of Python with -GpreferredSandboxLang=python):
# CMD ["./coppeliaSim.sh", "-h"]

# Use following instead to open an application window via an X server:
RUN echo '#!/bin/bash\ncd $COPPELIASIM_ROOT_DIR\n./coppeliaSim "$@"' > /entrypoint && chmod a+x /entrypoint

EXPOSE 23000-23500


# Delete user if it exists in container (e.g Ubuntu Noble: ubuntu)
RUN if id -u $USER_UID ; then userdel `id -un $USER_UID` ; fi

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
CMD ["/bin/bash"]
