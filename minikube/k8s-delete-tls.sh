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

source .env
: "${TB_TLS_SECRET_NAME:=tb-ingress-tls}"
: "${TB_TLS_CLUSTER_ISSUER:=letsencrypt-prod}"

kubectl config set-context $(kubectl config current-context) --namespace=thingsboard

if kubectl -n thingsboard get ingress tb-ingress >/dev/null 2>&1; then
    kubectl -n thingsboard annotate ingress tb-ingress cert-manager.io/cluster-issuer- --overwrite || true
    kubectl -n thingsboard annotate ingress tb-ingress nginx.ingress.kubernetes.io/ssl-redirect="false" --overwrite
    kubectl -n thingsboard annotate ingress tb-ingress nginx.ingress.kubernetes.io/force-ssl-redirect="false" --overwrite
    kubectl -n thingsboard patch ingress tb-ingress --type=json -p='[{"op":"remove","path":"/spec/tls"}]' >/dev/null 2>&1 || true
fi

kubectl -n thingsboard delete secret "${TB_TLS_SECRET_NAME}" --ignore-not-found=true

if kubectl get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
    kubectl delete clusterissuer "${TB_TLS_CLUSTER_ISSUER}" --ignore-not-found=true
fi
