# Yolomy — Kubernetes Orchestration on GKE

## Overview

This project deploys the **Yolomy MERN application** on **Google Kubernetes Engine (GKE)** using Kubernetes orchestration.

The project builds on the previous Docker containerization CAT. The existing application consists of:

* React frontend
* Node.js/Express backend
* MongoDB database
* Dockerized frontend and backend
* Docker images hosted on Docker Hub

The objective of this project was to move the application from a container-based setup into a reliable Kubernetes deployment on GKE, while implementing Kubernetes Services, Deployments, StatefulSets, and persistent storage.

---

## Repository Structure

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

### Kubernetes manifests

| File                 | Purpose                                                                           |
| -------------------- | --------------------------------------------------------------------------------- |
| `k8s/backend.yaml`   | Backend Deployment and ClusterIP Service                                          |
| `k8s/frontend.yaml`  | Frontend Deployment and LoadBalancer Service                                      |
| `k8s/mongodb.yaml`   | MongoDB StatefulSet, headless Service and persistent storage                      |
| `nginx/default.conf` | Nginx configuration for serving the React application and forwarding API requests |

---

# Docker Images

The Kubernetes manifests use personalized and version-tagged Docker Hub images.

### Backend

```text
hodhan/yolo-backend:v1.0.0
```

### Frontend

```text
hodhan/yolo-frontend:v1.0.6
```

Using versioned tags makes the images easier to identify and allows a specific image version to be referenced by Kubernetes.

MongoDB uses the official MongoDB image:

```text
mongo:6
```

---

# Kubernetes Architecture

The application is organized into three main layers:

```text
                    Internet
                       │
                       ▼
              GKE LoadBalancer
                       │
                       ▼
              Frontend Service
                       │
                       ▼
              Frontend Pods (2)
                       │
                       ▼
                    Nginx
                       │
                 /api/ requests
                       │
                       ▼
               Backend Service
                       │
                       ▼
              Backend Pods (2)
                       │
                       ▼
              MongoDB Service
                       │
                       ▼
             MongoDB StatefulSet
                       │
                       ▼
                Persistent PVC
                       │
                       ▼
                Persistent Disk
```

The frontend is the only application component exposed directly to internet traffic.

The backend communicates internally through its Kubernetes ClusterIP Service.

MongoDB is also accessed internally through its Kubernetes Service.

---

# Kubernetes Objects

## Backend Deployment

The backend is deployed using a Kubernetes Deployment with **2 replicas**.

The Deployment allows Kubernetes to maintain the desired number of backend Pods and recreate Pods if they fail.

The backend listens on port:

```text
5000
```

The backend Service exposes port 5000 internally inside the Kubernetes cluster.

---

## Frontend Deployment

The React frontend is deployed using a Kubernetes Deployment with **2 replicas**.

The frontend Docker image builds the React application and serves the production build using Nginx.

Nginx listens on:

```text
80
```

The frontend is exposed externally using a Kubernetes `LoadBalancer` Service.

---

## MongoDB StatefulSet

MongoDB is deployed using a Kubernetes **StatefulSet**.

A StatefulSet is appropriate for the database because databases require stable identity and persistent storage.

The MongoDB Pod has a stable identity:

```text
mongodb-0
```

The StatefulSet uses a headless Service:

```text
mongodb
```

MongoDB listens on:

```text
27017
```

---

# Persistent Storage

MongoDB uses a PersistentVolumeClaim created through the StatefulSet's `volumeClaimTemplates`.

The requested storage capacity is:

```text
5Gi
```

The storage uses:

```text
ReadWriteOnce
```

The MongoDB container mounts the persistent storage at:

```text
/data/db
```

The resulting PVC is:

```text
mongo-data-mongodb-0
```

The PVC was verified to be in the `Bound` state.

---

# Services

The deployment uses Kubernetes Services to provide communication between the application components.

```text
frontend    LoadBalancer
backend     ClusterIP
mongodb     ClusterIP
```

### Frontend Service

The frontend Service uses `LoadBalancer` so that GKE provisions an external IP address.

### Backend Service

The backend uses `ClusterIP` because it does not need to be directly exposed to the internet.

### MongoDB Service

MongoDB uses an internal headless Service because it is managed by a StatefulSet.

---

# Nginx Reverse Proxy

The frontend container uses Nginx to serve the React production build.

Nginx also forwards API requests to the backend Service.

Requests beginning with:

```text
/api/
```

are proxied to:

```text
http://backend:5000
```

This allows the browser to communicate with the application through the frontend's public endpoint without exposing the backend directly.

---

# GKE Deployment

The application was deployed to a Google Kubernetes Engine cluster.

The Kubernetes resources were applied using commands such as:

```bash
kubectl apply -f k8s/mongodb.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
```

The manifests were also validated using:

```bash
kubectl apply --dry-run=client -f k8s/frontend.yaml
```

---

# Deployment Verification

The deployed workloads were verified using:

```bash
kubectl get deployments
kubectl get pods
kubectl get svc
kubectl get pvc
```

The final deployment contained:

```text
backend     2/2
frontend    2/2
mongodb-0   1/1
```

The Services included:

```text
backend     ClusterIP
frontend    LoadBalancer
mongodb     ClusterIP
```

The MongoDB PVC was verified as:

```text
mongo-data-mongodb-0    Bound    5Gi
```

---

# Application Testing

The live frontend was accessed through the external IP provided by the GKE LoadBalancer.

The application was tested by:

1. Opening the Yolomy frontend through the external IP.
2. Confirming that existing products were displayed.
3. Adding a new product.
4. Confirming that the new product appeared in the application.
5. Confirming communication between the frontend and backend.
6. Deleting the MongoDB Pod.
7. Confirming that Kubernetes recreated `mongodb-0`.
8. Confirming that the previously stored products were still available.
9. Opening the application in an incognito browser session and confirming that the products remained available.

These tests demonstrated that the application was running successfully on GKE and that MongoDB data was persisted independently of the lifecycle of the MongoDB Pod.

---

# Persistence Test

The MongoDB Pod was deliberately deleted using:

```bash
kubectl delete pod mongodb-0
```

Kubernetes recreated the Pod automatically because it is managed by the StatefulSet.

The Pod returned to:

```text
mongodb-0    1/1    Running
```

The PVC remained:

```text
mongo-data-mongodb-0    Bound    5Gi
```

The products stored before the Pod deletion remained available after MongoDB restarted.

This demonstrates that deleting the database Pod did not delete the persistent database storage.

---

# Live Application

**Live application:**

```text
http://34.35.156.38
```

> The external IP is provided by the GKE LoadBalancer Service and may change if the Kubernetes Service is recreated.

---

# Git Workflow

The project was developed incrementally using Git.

Descriptive commits were used to document changes made during the deployment process.

Examples include:

```text
initial Kubernetes project structure
add backend deployment and nginx configuration
added frontend deployment and service
add initial project documentation
add initial Kubernetes implementation explanation
```

The repository is hosted on GitHub and contains the Kubernetes manifests required to recreate the deployment.

---

# Technologies Used

* Docker
* Docker Hub
* Kubernetes
* Google Kubernetes Engine (GKE)
* Kubernetes Deployments
* Kubernetes Services
* Kubernetes StatefulSets
* PersistentVolumeClaims
* Persistent Volumes
* MongoDB
* Node.js
* Express
* React
* Nginx
* Git
* GitHub

---

# Conclusion

The Yolomy MERN application was successfully migrated from its previous container-based setup into a Kubernetes-orchestrated environment on GKE.

The deployment uses multiple replicas for application availability, Kubernetes Services for communication and exposure, a StatefulSet for MongoDB, and persistent storage to protect database data from Pod deletion.

The application was tested on the live GKE deployment and verified to support normal product operations and persistent database storage.
