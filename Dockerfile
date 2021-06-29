# set ubuntu release version
ARG UBUNTU_VER="focal"

######## packages stage ###########
FROM ubuntu:${UBUNTU_VER} as package_stage

ARG DEBIAN_FRONTEND=noninteractive

# install build packages
RUN \
	apt-get update \
	&& apt-get install -y \
		acl \
		ansible \
		apt \
		bash \
		bc \
		build-essential \
		ca-certificates \
		curl \
		git \
		jq \
		nfs-common \
		openssl \
		python3 \
		python3.8-distutils \
		python3.8-venv \
		python3-dev \
		python3-pip \
		python-is-python3 \
		sqlite3 \
		sudo \
		tar \
		tzdata \
		unzip \
		vim \
		wget \
		cmake \
		rsync \
	\
# cleanup apt cache
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

######## build/runtime stage #########
FROM package_stage
# Base install of official Chia binaries at the given branch
ARG CHIA_BRANCH
ARG PATCH_CHIAPOS

# copy local files
COPY . /machinaris/

# set workdir
WORKDIR /chia-blockchain

# install Chia using official Chia Blockchain binaries
RUN \
	git clone --branch ${CHIA_BRANCH}  --single-branch https://github.com/Chia-Network/chia-blockchain.git /chia-blockchain \
	&& git submodule update --init mozilla-ca \
	&& chmod +x install.sh \
	&& /usr/bin/sh ./install.sh \
	\
# cleanup apt and pip caches
	\
	&& rm -rf \
		/root/.cache \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*
# install additional tools such as Plotman, Chiadog, and Machinaris
RUN \
       /usr/bin/bash /machinaris/scripts/patch_chiapos.sh ${PATCH_CHIAPOS} \
	&& . /machinaris/scripts/chiadog_install.sh \
	&& . /machinaris/scripts/plotman_install.sh \
	&& . /machinaris/scripts/machinaris_install.sh \
	\
# cleanup apt and pip caches
	\
	&& rm -rf \
		/root/.cache \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# Provide a colon-separated list of in-container paths to your mnemonic keys
ENV keys="/root/.chia/mnemonic.txt"  
# Provide a colon-separated list of in-container paths to your completed plots
ENV plots_dir="/plots"
# One of fullnode, plotter, farmer, or harvester. Default is fullnode
ENV mode="plotter" 
# If mode=plotter, optional 2 public keys will be set in your plotman.yaml
ENV farmer_pk="88f8ab59b7bffcccd6811790cf82c128c848534ed923efe4e8b7ee565812f2b6f3e6c657308374f4a491dab886c06e88"
ENV pool_pk="b7da82a07c6d2b93d8f3198921271ee7fe087f0bc67ccfcd7160dd8c583b199a544d4cfe2758abb446cc0534a9562265"
# If mode=harvester, required for host and port the harvester will your farmer
ENV farmer_address="null"
ENV farmer_port="8447"
# Only set true if using Chia's old test for testing only, default uses mainnet
ENV testnet="false"

ENV PATH="${PATH}:/chia-blockchain/venv/bin"
ENV TZ=Etc/UTC
ENV FLASK_ENV=production
ENV FLASK_APP=/machinaris/main.py
ENV XDG_CONFIG_HOME=/root/.chia
ENV AUTO_PLOT=false

VOLUME [ "/id_rsa" ]

# ports
EXPOSE 8555
EXPOSE 8444
EXPOSE 8926

WORKDIR /chia-blockchain
ENTRYPOINT ["bash", "./entrypoint.sh"]
