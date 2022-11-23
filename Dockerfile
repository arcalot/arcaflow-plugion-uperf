FROM quay.io/centos/centos:stream8 AS builder
RUN dnf install --setopt=tsflags=nodocs -y git make gcc lksctp-tools-devel automake && dnf clean all
RUN git clone -b 1.0.7 https://github.com/uperf/uperf.git /uperf
RUN cd /uperf && ./configure && make && make install

# build poetry
FROM quay.io/centos/centos:stream8 as poetry

RUN dnf module -y install python39 && dnf install --setopt=tsflags=nodocs -y python39 python39-pip lksctp-tools-devel && dnf clean all

WORKDIR /app

COPY poetry.lock /app/
COPY pyproject.toml /app/

RUN python3.9 -m pip install poetry \
 && python3.9 -m poetry config virtualenvs.create false \
 && python3.9 -m poetry install --without dev \
 && python3.9 -m poetry export -f requirements.txt --output requirements.txt --without-hashes

# run tests
COPY --from=builder /usr/local/bin/uperf /usr/local/bin/uperf
COPY uperf_plugin.py /app/
COPY test_uperf_plugin.py /app/
COPY uperf_schema.py /app/

RUN mkdir /htmlcov
RUN pip3 install coverage
RUN python3 -m coverage run test_uperf_plugin.py
RUN python3 -m coverage html -d /htmlcov --omit=/usr/local/*


# final image
FROM quay.io/centos/centos:stream8

RUN dnf module -y install python39 && dnf install --setopt=tsflags=nodocs -y python39 python39-pip lksctp-tools-devel && dnf clean all

WORKDIR /app

COPY --from=builder /usr/local/bin/uperf /usr/local/bin/uperf
COPY --from=poetry /app/requirements.txt /app/
COPY --from=poetry /htmlcov /htmlcov/
COPY LICENSE /app/
COPY README.md /app/
COPY uperf_schema.py /app/
COPY uperf_plugin.py /app/

RUN python3.9 -m pip install -r requirements.txt

EXPOSE 20000

ENTRYPOINT ["python3.9", "uperf_plugin.py"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-uperf"
LABEL org.opencontainers.image.licenses="Apache-2.0+GPL-3.0-only"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Uperf Arcalot Plugin"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
