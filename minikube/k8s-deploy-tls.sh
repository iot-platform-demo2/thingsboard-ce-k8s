#!/bin/bash
#
# Copyright © 2016-2020 The Thingsboard Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

wait_for_deployment() {
    local namespace=$1
    local deployment_name=$2

    until kubectl -n "$namespace" get deployment "$deployment_name" >/dev/null 2>&1; do
        sleep 2
    done

    kubectl -n "$namespace" rollout status "deployment/$deployment_name" --timeout=300s
}

ensure_cert_manager() {
    if ! kubectl get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
        kubectl apply -f "${TB_CERT_MANAGER_MANIFEST_URL}"
    fi

    wait_for_deployment cert-manager cert-manager
    wait_for_deployment cert-manager cert-manager-webhook
    wait_for_deployment cert-manager cert-manager-cainjector
}

render_manifest() {
    local source_file=$1
    local rendered_file

    rendered_file=$(mktemp)
    sed \
        -e "s|__TB_PUBLIC_HOST__|${TB_PUBLIC_HOST}|g" \
        -e "s|__TB_INGRESS_CLASS_NAME__|${TB_INGRESS_CLASS_NAME}|g" \
        -e "s|__TB_TLS_SECRET_NAME__|${TB_TLS_SECRET_NAME}|g" \
        -e "s|__TB_TLS_CLUSTER_ISSUER__|${TB_TLS_CLUSTER_ISSUER}|g" \
        -e "s|__TB_TLS_ACME_EMAIL__|${TB_TLS_ACME_EMAIL}|g" \
        -e "s|__TB_TLS_ACME_SERVER__|${TB_TLS_ACME_SERVER}|g" \
        -e "s|__TB_SSL_REDIRECT__|${TB_SSL_REDIRECT}|g" \
        "$source_file" > "$rendered_file"

    printf '%s\n' "$rendered_file"
}

apply_rendered_manifest() {
    local source_file=$1
    local rendered_file

    rendered_file=$(render_manifest "$source_file")
    if ! kubectl apply -f "$rendered_file"; then
        rm -f "$rendered_file"
        return 1
    fi

    rm -f "$rendered_file"
}

source .env
: "${TB_PUBLIC_HOST:=newgen.iot-platform.io.vn}"
: "${TB_INGRESS_CLASS_NAME:=nginx}"
: "${TB_CERT_MANAGER_MANIFEST_URL:=https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.yaml}"
: "${TB_TLS_SECRET_NAME:=tb-ingress-tls}"
: "${TB_TLS_CLUSTER_ISSUER:=letsencrypt-prod}"
: "${TB_TLS_ACME_EMAIL:=gpt.htv@gmail.com}"
: "${TB_TLS_ACME_SERVER:=https://acme-v02.api.letsencrypt.org/directory}"
: "${TB_SSL_REDIRECT:=true}"

ensure_cert_manager

kubectl apply -f tb-namespace.yml || echo
apply_rendered_manifest cluster-issuer.yml

kubectl config set-context $(kubectl config current-context) --namespace=thingsboard
apply_rendered_manifest routes.yml
