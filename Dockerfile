FROM ubuntu:20.04
#FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive
ENV PIP_NO_CACHE_DIR yes

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

RUN useradd -s /bin/bash source
RUN mkdir /opt/venv /opt/pyaleph
RUN chown source:source /opt/venv /opt/pyaleph

USER source

RUN virtualenv -p python3 /opt/venv

RUN /opt/venv/bin/python3 -m pip install --upgrade pip pipdeptree
ENV PATH="/opt/venv/bin:${PATH}"

#RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/py-libp2p.git
RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/nuls2-python.git
RUN pip install --use-feature=2020-resolver git+https://github.com/aleph-im/aleph-client.git

COPY . /opt/pyaleph

RUN pip install --use-feature=2020-resolver /opt/pyaleph/py-libp2p/

ENV TRAVIS_TAG 0.9.21
RUN pip install --use-feature=2020-resolver /opt/pyaleph/py-substrate-interface/
ENV TRAVIS_TAG ""

RUN pip install --use-feature=2020-resolver /opt/pyaleph/neo-python
RUN pip install --use-feature=2020-resolver python-binance-chain

USER root
#RUN mkdir /opt/src
#RUN mkdir /opt/src/pyaleph.egg-info
RUN mkdir /opt/pyaleph/src/pyaleph.egg-info
RUN chown -R source:source /opt/pyaleph/src
USER source

WORKDIR /opt/pyaleph
RUN python setup.py develop

#USER root
#RUN useradd -s /bin/bash aleph
