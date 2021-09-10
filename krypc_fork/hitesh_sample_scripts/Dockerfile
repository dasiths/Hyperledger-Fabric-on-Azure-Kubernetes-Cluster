# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

ARG GO_VER=1.14.4
ARG ALPINE_VER=3.12

FROM golang:${GO_VER}-alpine${ALPINE_VER}

RUN apk update && apk add --no-cache git build-base

ARG git_token
ENV git_token=$git_token

ENV GO111MODULE=on
ENV GOPRIVATE={specify private repo info}

WORKDIR /myapp

COPY . .

RUN git config \
    --global \
    url."https://{xxxx}:${git_token}@dev.azure.com".insteadOf \
    "https://dev.azure.com"

RUN go get -d -v ./...
RUN go install -v ./...

EXPOSE 9999
CMD ["chaincode.git"]
