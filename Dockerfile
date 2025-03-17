##############
# base stage #
##############
FROM registry.access.redhat.com/ubi9/python-312@sha256:b3316249c58e1800118ec1f311514f6ec355a60d8c78383bfa868887952b2ee1 AS base

COPY LICENSE /licenses/LICENSE

#################
# builder stage #
#################
FROM base AS builder
COPY --from=ghcr.io/astral-sh/uv:0.5.7@sha256:23272999edd22e78195509ea3fe380e7632ab39a4c69a340bedaba7555abe20a /uv /bin/uv

ENV \
    # use venv from ubi image
    UV_PROJECT_ENVIRONMENT="/opt/app-root" \
    # compile bytecode for faster startup
    UV_COMPILE_BYTECODE="true" \
    # disable uv cache. it doesn't make sense in a container
    UV_NO_CACHE=true

COPY pyproject.toml uv.lock ./
# Test lock file is up to date
RUN uv lock --locked
# Install the project dependencies
RUN uv sync --frozen --no-install-project --no-group dev

COPY README.md ./
COPY validator ./validator
RUN uv sync --frozen --no-group dev

##############
# test stage #
##############
FROM builder AS test
COPY Makefile ./
RUN uv sync --frozen
RUN make _test

##############
# prod stage #
##############
FROM base AS prod
COPY --from=builder /opt/app-root /opt/app-root
