#!/bin/bash

set -e

IMAGE_NAME="python-flask-app:latest"
POD_NAME="python-flask-app-pod"
SERVICE_PORT=5000

echo "Сборка Docker-образа при помощи minikube..."
minikube image build -t ${IMAGE_NAME} .

echo "Применение ConfigMap..."
kubectl apply -f configmap.yaml

echo "Применение Pod..."
kubectl apply -f pod.yaml

echo "Ожидание запуска Pod..."
kubectl wait --for=condition=ready pod/${POD_NAME} --timeout=300s

echo "Pod запущен"

kubectl port-forward ${POD_NAME} ${SERVICE_PORT}:${SERVICE_PORT} &
PORT_FORWARD_PID=$!

trap "kill $PORT_FORWARD_PID; echo 'Остановлено.'; exit 0" SIGINT
wait $PORT_FORWARD_PID