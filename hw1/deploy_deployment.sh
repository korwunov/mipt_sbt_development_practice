#!/bin/bash

set -e

IMAGE_NAME="python-flask-app:latest"

echo "Сборка Docker-образа при помощи minikube..."
minikube image build -t ${IMAGE_NAME} ./logs_application

echo "Конфигурация istio"
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
echo "Istio настроен для использования в кластере"

echo "Применение ConfigMap..."
kubectl apply -f k8s/configmap.yaml

echo "Применение Deployment..."
kubectl apply -f k8s/deployment.yaml

echo "Применение Service..."
kubectl apply -f k8s/service.yaml

echo "Применение DaemonSet..."
kubectl apply -f k8s/daemonset.yaml

echo "Применение CronJob..."
kubectl apply -f k8s/cronjob.yaml

echo "Ожидание готовности Deployment..."
kubectl rollout status deployment/python-flask-app-deployment --timeout=300s
echo "Deployment готов!"

echo "Проверка DaemonSet..."
kubectl rollout status daemonset --timeout=120s
echo "DaemonSet запущен на узлах."

echo "Проверка CronJob..."
kubectl get cronjob archive-logs-cronjob
echo "CronJob создан."

echo "Применение Gateway..."
kubectl apply -f k8s/gateway.yaml
echo "Gateway создан"

echo "Применение VirtualService..."
kubectl apply -f k8s/virtualservice.yaml
echo "VirtualService создан"

echo "Применение DestinationRule..."
kubectl apply -f k8s/destinationrule.yaml
echo "DestinationRule создан"

echo "Добавление Prometheus в namespace istio-system"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/addons/prometheus.yaml
echo "Prometheus добавлен"

echo "Добавление Grafana в namespace istio-system"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.29/samples/addons/grafana.yaml
echo "Grafana добавлена"

echo "Открытие порта наружу..."
minikube service istio-ingressgateway -n istio-system