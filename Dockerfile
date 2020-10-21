FROM ubuntu:20.04
#FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && apt-get install -y \
     python3 \
     python3-dev \
     python3-pip \
     python3-virtualenv \
     virtualenv \
     build-essential

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

# /// Install MongoDB, IPFS and Supervisord
USER root
RUN apt-get install -y mongodb
RUN mkdir /run/mongodb

#
RUN apt-get install -y wget
RUN wget https://ipfs.io/ipns/dist.ipfs.io/go-ipfs/v0.7.0/go-ipfs_v0.7.0_linux-amd64.tar.gz
RUN tar -xvzf go-ipfs_v0.7.0_linux-amd64.tar.gz -C /opt/
RUN ln -s /opt/go-ipfs/ipfs /usr/local/bin/
RUN /opt/go-ipfs/ipfs init
#
RUN apt-get install -y supervisor
#COPY deployment/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# \\\

# /// Create an unprivileged user to run pyaleph
RUN useradd -s /bin/bash source
RUN mkdir /opt/venv /opt/pyaleph
RUN chown source:source /opt/venv /opt/pyaleph
#
USER source
# \\\

# /// Install Python dependencies
RUN virtualenv -p python3 /opt/venv

ENV PIP_NO_CACHE_DIR yes
RUN /opt/venv/bin/python3 -m pip install --upgrade pip
ENV PATH="/opt/venv/bin:${PATH}"
RUN pip install --use-feature=2020-resolver pipdeptree

#RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/py-libp2p.git
RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/nuls2-python.git
RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/aleph-client.git

COPY py-libp2p /opt/py-libp2p
RUN pip install --use-feature=2020-resolver /opt/py-libp2p/
#
COPY py-substrate-interface /opt/py-substrate-interface
ENV TRAVIS_TAG 0.9.21
RUN pip install --use-feature=2020-resolver /opt/py-substrate-interface/
ENV TRAVIS_TAG ""
#
RUN pip freeze
RUN pip install --use-feature=2020-resolver iniconfig==1.0.1
#RUN pip install --use-feature=2020-resolver protobuf==3.13.0
COPY two1-python /opt/two1-python
RUN pip install --use-feature=2020-resolver /opt/two1-python
#
COPY neo-python /opt/neo-python
RUN pip install --use-feature=2020-resolver /opt/neo-python
RUN pip install --use-feature=2020-resolver python-binance-chain==0.1.20
# \\\

# /// copy source code, excluding 3rd-party libs
COPY setup.py /opt/pyaleph/
COPY setup.cfg /opt/pyaleph/
COPY config.yml /opt/pyaleph/config.yml
COPY tests /opt/pyaleph/tests
COPY src /opt/pyaleph/src
COPY .git /opt/pyaleph/.git

USER root
RUN mkdir /opt/pyaleph/src/pyaleph.egg-info
RUN chown -R source:source /opt/pyaleph/src
USER source

WORKDIR /opt/pyaleph
RUN python setup.py develop
# RUN python setup.py testing

#CMD pyaleph -vv -c config.yml -p 8081 -h 0.0.0.0

#IPFS Swarm
EXPOSE 4001
#IPFS WebUI
EXPOSE 5001
# IPFS Gateway
EXPOSE 8080
# PyAleph API
EXPOSE 8081
# PyAleph network
EXPOSE 4024
EXPOSE 4025

RUN mkdir /opt/pyaleph/data

USER root
RUN mkdir /var/lib/ipfs
RUN chown -R source:source /var/lib/ipfs
USER source
ENV IPFS_PATH /var/lib/ipfs
RUN ipfs init

COPY deployment/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
USER root
RUN chown mongodb:mongodb /run/mongodb
#CMD /usr/bin/supervisord --nodaemon -c /etc/supervisor/conf.d/supervisord.conf
#CMD ["/usr/bin/supervisord", "--nodaemon", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
