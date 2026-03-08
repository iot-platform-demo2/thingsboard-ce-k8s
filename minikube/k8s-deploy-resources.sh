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

render_manifest() {
    local source_file=$1
    local rendered_file

    rendered_file=$(mktemp)
    sed \
        -e "s|__TB_PUBLIC_HOST__|${TB_PUBLIC_HOST}|g" \
        -e "s|__TB_INGRESS_CLASS_NAME__|${TB_INGRESS_CLASS_NAME}|g" \
        -e "s|__TB_MQTT_SERVICE_TYPE__|${TB_MQTT_SERVICE_TYPE}|g" \
        -e "s|__TB_COAP_SERVICE_TYPE__|${TB_COAP_SERVICE_TYPE}|g" \
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
: "${TB_PUBLIC_HOST:=things.iot-platform.io.vn}"
: "${TB_INGRESS_CLASS_NAME:=nginx}"
: "${TB_MQTT_SERVICE_TYPE:=LoadBalancer}"
: "${TB_COAP_SERVICE_TYPE:=LoadBalancer}"
kubectl apply -f tb-namespace.yml || echo

kubectl config set-context $(kubectl config current-context) --namespace=thingsboard

kubectl apply -f $DATABASE/tb-node-db-configmap.yml
kubectl apply -f tb-cache-configmap.yml
kubectl apply -f tb-kafka-configmap.yml
kubectl apply -f tb-node-configmap.yml
kubectl apply -f tb-transport-configmap.yml
apply_rendered_manifest thingsboard.yml
kubectl apply -f tb-node.yml

apply_rendered_manifest routes.yml
