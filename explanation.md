# Kubernetes Implementation Explanation

## 1. Kubernetes Objects Used

The Yolomy application uses several Kubernetes objects to provide reliable deployment and communication between its components.

### Backend Deployment

The backend is deployed using a Kubernetes Deployment with two replicas.

Using two replicas allows Kubernetes to maintain multiple backend Pods instead of depending on a single Pod.

The backend Pods are identified using labels such as:

```yaml
app: yolo
component: backend
```

The backend is exposed internally through a ClusterIP Service on port 5000.

### Frontend Deployment

The React frontend is also deployed using a Deployment with two replicas.

The frontend Docker image contains the production React build and uses Nginx to serve the application.

The frontend is exposed using a LoadBalancer Service so that traffic from outside the Kubernetes cluster can reach the application.

### MongoDB StatefulSet

MongoDB is deployed using a StatefulSet rather than an ordinary Deployment.

A StatefulSet is appropriate for a database because it provides stable Pod identity and works together with persistent storage.

MongoDB uses the stable Pod name:

```text
mongodb-0
```

A headless Service is used for the MongoDB StatefulSet.

## 2. Exposing the Application

The frontend is exposed to internet traffic through a Kubernetes LoadBalancer Service.

The LoadBalancer receives external traffic and forwards it to the frontend Pods.

The frontend Nginx server also acts as a reverse proxy for API requests.

Requests matching:

```text
/api/
```

are forwarded to:

```text
http://backend:5000
```

The backend itself remains internally accessible through its ClusterIP Service.

This prevents the backend from needing its own public IP address.

## 3. Persistent Storage

MongoDB uses a PersistentVolumeClaim through the StatefulSet's `volumeClaimTemplates`.

The database container mounts the persistent storage at:

```text
/data/db
```

The requested storage capacity is:

```text
5Gi
```

The PVC uses:

```text
ReadWriteOnce
```

This allows MongoDB data to remain available independently of the lifecycle of an individual MongoDB Pod.

## 4. Docker Images

The Kubernetes manifests use tagged Docker images hosted on Docker Hub.

The images include:

```text
hodhan/yolo-backend:v1.0.0
hodhan/yolo-frontend:v1.0.6
```

Version tags make the images easier to identify and allow a specific application version to be referenced by the Kubernetes manifests.

## 5. Git Workflow

The project is maintained in a dedicated GitHub repository.

The development process is recorded through descriptive Git commits. The repository contains the Kubernetes manifests and configuration required to deploy the application.
