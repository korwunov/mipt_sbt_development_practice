#!/bin/bash

set -e

IMAGE_NAME="python-flask-app:latest"

echo "Сборка Docker-образа при помощи minikube..."
minikube image build -t ${IMAGE_NAME} ./logs_application

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

echo "Открытие порта наружу..."
minikube service python-flask-app-service