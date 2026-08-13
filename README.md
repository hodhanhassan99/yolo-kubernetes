# Yolomy Kubernetes Deployment

## Overview

This project deploys the Yolomy MERN application on Google Kubernetes Engine (GKE) using Kubernetes.

The project builds on the previous Docker containerization CAT. The application consists of:

* React frontend
* Node.js/Express backend
* MongoDB database
* Docker images hosted on Docker Hub
* Kubernetes Deployments, Services, and a StatefulSet

## Project Structure

```text
yolo-kubernetes/
├── k8s/
│   ├── backend.yaml
│   ├── frontend.yaml
│   └── mongodb.yaml
├── nginx/
│   └── default.conf
├── README.md
└── explanation.md
```

## Docker Images

The application uses personalized Docker Hub images:

```text
hodhan/yolo-backend:v1.0.0
hodhan/yolo-frontend:v1.0.6
```

The frontend image uses Nginx to serve the React production build.

## Kubernetes Deployment

The backend is deployed using two replicas:

```text
backend    2/2
```

The frontend is also deployed using two replicas:

```text
frontend   2/2
```

MongoDB is deployed using a Kubernetes StatefulSet.

The backend is exposed internally through a ClusterIP Service, while the frontend is exposed externally using a LoadBalancer Service.

## Current Services

The Kubernetes services include:

```text
backend    ClusterIP
frontend   LoadBalancer
mongodb    ClusterIP
```

The frontend LoadBalancer provides the external entry point to the application.

## Application

The frontend communicates with the backend through the Nginx reverse proxy. Requests to `/api/` are forwarded to the Kubernetes backend Service.

The backend communicates with MongoDB through the Kubernetes MongoDB Service.

## GKE

The application is running on a Google Kubernetes Engine cluster.

The live application URL will be documented here after final deployment verification.
