FROM centos:7
ENV SPLUNK_HOME /splunkforwarder
ENV SPLUNK_ROLE splunk_heavy_forwarder
ENV SPLUNK_PASSWORD changeme
ENV SPLUNK_START_ARGS --accept-license

RUN yum install -y epel-release \
    && yum install -y wget expect jq

RUN wget -O splunkforwarder-7.2.4-8a94541dcfac-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.4&product=universalforwarder&filename=splunkforwarder-7.2.4-8a94541dcfac-Linux-x86_64.tgz&wget=true' \
    && wget -O docker-18.09.3.tgz 'https://download.docker.com/linux/static/stable/x86_64/docker-18.09.3.tgz' \
    && tar -xvf splunkforwarder-7.2.4-8a94541dcfac-Linux-x86_64.tgz \
    && tar -xvf docker-18.09.3.tgz  \
    && rm -f splunkforwarder-7.2.4-8a94541dcfac-Linux-x86_64.tgz \
    && rm -f docker-18.09.3.tgz

COPY [ "inputs.conf", "docker-stats/props.conf", "/splunkforwarder/etc/system/local/" ]
COPY [ "docker-stats/docker_events.sh", "docker-stats/docker_inspect.sh", "docker-stats/docker_stats.sh", "docker-stats/docker_top.sh", "/splunkforwarder/bin/scripts/" ]
COPY splunkclouduf.spl /splunkclouduf.spl
COPY first_start.sh /splunkforwarder/bin/

RUN chmod +x /splunkforwarder/bin/scripts/*.sh \
    && groupadd -r splunk \
    && useradd -r -m -g splunk splunk \
    && echo "%sudo ALL=NOPASSWD:ALL" >> /etc/sudoers \
    && chown -R splunk:splunk $SPLUNK_HOME \
    && /splunkforwarder/bin/first_start.sh \
    && /splunkforwarder/bin/splunk install app /splunkclouduf.spl -auth admin:changeme \
    && /splunkforwarder/bin/splunk restart

COPY [ "init/entrypoint.sh", "init/checkstate.sh", "/sbin/" ]

VOLUME [ "/splunkforwarder/etc", "/splunkforwarder/var" ]

HEALTHCHECK --interval=30s --timeout=30s --start-period=3m --retries=5 CMD /sbin/checkstate.sh || exit 1

ENTRYPOINT [ "/sbin/entrypoint.sh" ]
CMD [ "start-service" ]
