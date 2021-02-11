FROM golang:1.14.15-alpine AS build-env
WORKDIR /usr/app/

RUN apk add curl git make bash gcc musl-dev

# install kustomzie and sealed secret transformer
COPY . ./kustomize-plugins
ENV XDG_CONFIG_HOME=/usr/app/
RUN cd kustomize-plugins \
    && make setup \
    && XDG_CONFIG_HOME=$XDG_CONFIG_HOME make build \
    && mv ./bin/kustomize /usr/local/bin/kustomize

# install sealed secret
RUN curl -L https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.13.1/kubeseal-linux-amd64 -o kubeseal \
    && install -m 755 kubeseal /usr/local/bin/kubeseal 

FROM alpine

COPY --from=build-env /usr/local/bin/kustomize /usr/local/bin/
COPY --from=build-env /usr/local/bin/kubeseal /usr/local/bin/
COPY --from=build-env /usr/app/kustomize/plugin /usr/local/share/kustomize/plugin

ENV KUSTOMIZE_PLUGIN_HOME=/usr/local/share/kustomize/plugin
