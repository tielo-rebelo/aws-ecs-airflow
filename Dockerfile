# BUILD: docker build --rm -t airflow .
# ORIGINAL SOURCE: https://github.com/puckel/docker-airflow

FROM python:3.6-slim
MAINTAINER nicor88

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.10.0
# it's possible to use v1-10-stable, but it's a development branch
ARG AIRFLOW_HOME=/usr/local/airflow
ARG REDIS_VERSION=4.1.1
ENV AIRFLOW_GPL_UNIDECODE=yes

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN set -ex \
    && buildDeps=' \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        sudo \
        python3-pip \
        python3-requests \
        mysql-client \
        default-libmysqlclient-dev \
        apt-utils \
        curl \
        rsync \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install Cython \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install git+https://github.com/apache/incubator-airflow.git@$AIRFLOW_VERSION#egg=apache-airflow[async,crypto,celery,kubernetes,jdbc,password,postgres,s3,slack] \
    && pip install celery[redis]==$REDIS_VERSION \
    && pip install flask_oauthlib \
    && pip install psycopg2-binary \
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY config/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

COPY dags ${AIRFLOW_HOME}/dags
COPY plugins ${AIRFLOW_HOME}/plugins

ENV PYTHONPATH ${AIRFLOW_HOME}

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
COPY requirements.txt .
RUN pip install --user -r requirements.txt

WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]