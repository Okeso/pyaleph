# Monolithic Docker image for easy setup of an Aleph.im node in demo scenarios.

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# Install Python dependencies
RUN apt-get update && apt-get -y upgrade && apt-get install -y \
     python3 \
     python3-dev \
     python3-pip \
     python3-virtualenv \
     virtualenv \
     build-essential

# Install system dependencies
RUN apt-get install -y \
     libsnappy-dev \
     zlib1g-dev \
     libbz2-dev \
     libgflags-dev \
     liblz4-dev \
     librocksdb-dev \
     libgmp-dev \
     libsecp256k1-dev \
     git \
     pkg-config \
     libssl-dev \
     libleveldb-dev \
     libyaml-dev


# === Install MongoDB, IPFS and Supervisord ===

# Install MongoDB
RUN apt-get install -y mongodb
RUN mkdir /run/mongodb
RUN chown mongodb:mongodb /run/mongodb

# Install IPFS
RUN apt-get install -y wget
RUN wget https://ipfs.io/ipns/dist.ipfs.io/go-ipfs/v0.7.0/go-ipfs_v0.7.0_linux-amd64.tar.gz
RUN tar -xvzf go-ipfs_v0.7.0_linux-amd64.tar.gz -C /opt/
RUN ln -s /opt/go-ipfs/ipfs /usr/local/bin/
RUN /opt/go-ipfs/ipfs init
RUN mkdir /var/lib/ipfs

# Install Supervisord
RUN apt-get install -y supervisor


# ===  Create an unprivileged user to install Python dependencies ===
RUN useradd -s /bin/bash source
RUN mkdir /opt/venv /opt/pyaleph
RUN chown source:source /opt/venv /opt/pyaleph
RUN chown -R source:source /var/lib/ipfs
USER source


# === Install Python environment and dependencies ===
#
# Note: Most of the complexity in this section is due to conflicts in dependencies.
# These should ideally be fixed upstream.

# Create virtualenv
RUN virtualenv -p python3 /opt/venv

# Install pip
ENV PIP_NO_CACHE_DIR yes
RUN /opt/venv/bin/python3 -m pip install --upgrade pip
ENV PATH="/opt/venv/bin:${PATH}"

# Optional: Install pipdeptree to debug Python dependencies
RUN pip install --use-feature=2020-resolver pipdeptree

# Install custom dependencies
#RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/py-libp2p.git
#RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/nuls2-python.git
#RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/aleph-client.git

# Install patched version of py-libp2p
#COPY ../../py-libp2p /opt/py-libp2p
#RUN pip install --use-feature=2020-resolver /opt/py-libp2p/

# Install patched version of py-substrate-interface
# A commit on master fixes the status, but not published yet on Pypi as of 2020-10-27
# See https://github.com/polkascan/py-substrate-interface/pull/40
COPY ../../py-substrate-interface /opt/py-substrate-interface
# ENV variable used to detect the package version
ENV TRAVIS_TAG 0.9.26
RUN pip install --use-feature=2020-resolver /opt/py-substrate-interface/
ENV TRAVIS_TAG ""

#RUN pip install --use-feature=2020-resolver iniconfig==1.0.1
# Install patched version of two1-python
COPY ../../two1-python /opt/two1-python
RUN pip install --use-feature=2020-resolver /opt/two1-python

# === Copy source code, excluding 3rd-party libs ===
COPY ../../setup.py /opt/pyaleph/
COPY ../../setup.cfg /opt/pyaleph/
COPY ../../config.yml /opt/pyaleph/config.yml
COPY ../../tests /opt/pyaleph/tests
COPY ../../src /opt/pyaleph/src
COPY .git /opt/pyaleph/.git


# === Install source code ===

# Setup directories for `python setup.py develop`
USER root
RUN mkdir /opt/pyaleph/src/pyaleph.egg-info
RUN chown -R source:source /opt/pyaleph/src

# Install PyAleph source
USER source
WORKDIR /opt/pyaleph
RUN python setup.py develop
RUN /opt/venv/bin/pip install --use-feature=2020-resolver -e ".[testing]"
RUN /opt/venv/bin/pip install --use-feature=2020-resolver -e ".[nuls2]"

# TODO: Check if this is useful
RUN mkdir /opt/pyaleph/data

ENV IPFS_PATH /var/lib/ipfs

USER root
COPY deployment/docker-demo/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY deployment/docker-demo/entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]

# IPFS Swarm
EXPOSE 4001
# IPFS WebUI
EXPOSE 5001
# IPFS Gateway
EXPOSE 8080

# PyAleph API
EXPOSE 8081
# PyAleph p2p network
EXPOSE 4024 4025

VOLUME /var/lib/mongodb
VOLUME /var/lib/ipfs
