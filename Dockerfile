FROM quay.io/centos/centos:stream8 AS builder
RUN dnf install --setopt=tsflags=nodocs -y git make gcc lksctp-tools-devel automake && dnf clean all
RUN git clone -b 1.0.7 https://github.com/uperf/uperf.git /uperf
RUN cd /uperf && ./configure && make && make install

FROM quay.io/centos/centos:stream8
RUN dnf module -y install python39 && dnf install --setopt=tsflags=nodocs -y python39 python39-pip lksctp-tools-devel && dnf clean all
COPY --from=builder /usr/local/bin/uperf /usr/local/bin/uperf
RUN mkdir /plugin
ADD https://raw.githubusercontent.com/arcalot/arcaflow-plugins/main/LICENSE /plugin/
ADD uperf_plugin.py /plugin/
ADD uperf_schema.py /plugin/
ADD test_uperf_plugin.py /plugin/
ADD poetry.lock pyproject.toml /plugin/
WORKDIR /plugin

RUN pip3 install poetry
RUN poetry config virtualenvs.create false
RUN poetry install --without dev
RUN python3.9 test_uperf_plugin.py

EXPOSE 20000

ENTRYPOINT ["python3.9", "uperf_plugin.py"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-uperf"
LABEL org.opencontainers.image.licenses="Apache-2.0+GPL-3.0-only"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Uperf Arcalot Plugin"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
