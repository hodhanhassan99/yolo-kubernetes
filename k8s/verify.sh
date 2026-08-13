#!/bin/bash

echo "=== YOLO Kubernetes Deployment Verification ==="

echo ""
echo "=== Nodes ==="
kubectl get nodes

echo ""
echo "=== Deployments ==="
kubectl get deployments

echo ""
echo "=== Pods ==="
kubectl get pods

echo ""
echo "=== Services ==="
kubectl get services

echo ""
echo "=== Persistent Volume Claims ==="
kubectl get pvc

echo ""
echo "=== StatefulSets ==="
kubectl get statefulsets

echo ""
echo "=== Frontend External IP ==="
kubectl get service frontend -o wide

echo ""
echo "=== Verification complete ==="