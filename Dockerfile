ARG package=arcaflow_plugin_uperf

# build poetry
FROM quay.io/centos/centos:stream8 as poetry
ARG package
RUN dnf module -y install python39 && dnf install --setopt=tsflags=nodocs -y python39 python39-pip lksctp-tools-devel && dnf clean all \
 && dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
 && dnf -y install uperf

WORKDIR /app

COPY poetry.lock /app/
COPY pyproject.toml /app/

RUN python3.9 -m pip install poetry==1.4.2 \
 && python3.9 -m poetry config virtualenvs.create false \
 && python3.9 -m poetry install --without dev --no-root \
 && python3.9 -m poetry export -f requirements.txt --output requirements.txt --without-hashes

# run tests
COPY ${package}/ /app/${package}
COPY tests /app/tests

ENV PYTHONPATH /app/${package}

RUN mkdir /htmlcov \
 && pip3 install coverage \
 && python3 -m coverage run tests/test_uperf_plugin.py \
 && python3 -m coverage html -d /htmlcov --omit=/usr/local/*


# final image
FROM quay.io/centos/centos:stream8
ARG package
RUN dnf module -y install python39 && dnf install --setopt=tsflags=nodocs -y python39 python39-pip lksctp-tools-devel && dnf clean all \
 && dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
 && dnf -y install uperf

WORKDIR /app

COPY --from=poetry /app/requirements.txt /app/
COPY --from=poetry /htmlcov /htmlcov/
COPY LICENSE /app/
COPY README.md /app/
COPY ${package}/ /app/${package}

RUN python3.9 -m pip install -r requirements.txt

EXPOSE 20000

WORKDIR /app

ENTRYPOINT ["python3.9", "-m", "arcaflow_plugin_uperf.uperf_plugin"]
CMD []

LABEL org.opencontainers.image.source="https://github.com/arcalot/arcaflow-plugin-uperf"
LABEL org.opencontainers.image.licenses="Apache-2.0+GPL-3.0-only"
LABEL org.opencontainers.image.vendor="Arcalot project"
LABEL org.opencontainers.image.authors="Arcalot contributors"
LABEL org.opencontainers.image.title="Uperf Arcalot Plugin"
LABEL io.github.arcalot.arcaflow.plugin.version="1"
