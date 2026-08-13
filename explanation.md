# Kubernetes Orchestration — Implementation Explanation

## Introduction

This project builds on the previous Yolomy Docker containerization CAT.

The previous project provided the application containers and Docker images. For this assignment, the objective was to apply Kubernetes orchestration concepts by deploying the application to Google Kubernetes Engine (GKE).

The implementation focuses on:

1. Appropriate Kubernetes objects for each application component.
2. Exposing the application to internet traffic.
3. Persistent storage for MongoDB.
4. A clear Git workflow.
5. Successful deployment and debugging.
6. Good Docker image tagging practices.

The final deployment consists of a React frontend, Node.js/Express backend, and MongoDB database.

---

# 1. Choice of Kubernetes Objects

## Backend — Deployment

The backend is implemented using a Kubernetes `Deployment`.

The Deployment uses two replicas.

The main reason for using a Deployment is that the backend is a stateless application layer. The backend does not need a permanent Pod identity because application state is stored in MongoDB rather than inside the backend container.

Using two replicas also improves availability.

If one backend Pod becomes unavailable, Kubernetes can maintain another replica to continue serving requests.

The backend is therefore a suitable candidate for a Deployment rather than a StatefulSet.

The backend Deployment is exposed through a `ClusterIP` Service on port 5000.

The backend Pods use labels:

```yaml
app: yolo
component: backend
```

These labels allow the backend Service to select the correct Pods.

---

## Frontend — Deployment

The React frontend is also deployed using a Kubernetes `Deployment` with two replicas.

The frontend is stateless because the React production files are contained in the Docker image and served by Nginx.

There is therefore no need for stable Pod identity or persistent storage for the frontend.

Using two replicas allows Kubernetes to maintain multiple frontend Pods and improves availability.

The frontend is exposed through a Kubernetes `LoadBalancer` Service.

---

## MongoDB — StatefulSet

MongoDB is implemented using a Kubernetes `StatefulSet`.

This was a deliberate choice because MongoDB is a stateful database and has requirements that differ from the frontend and backend.

A StatefulSet provides:

* Stable Pod identity.
* Predictable Pod naming.
* Stable association with persistent storage.
* Ordered management of Pods.
* Integration with persistent volume claims.

The MongoDB Pod is therefore named:

```text
mongodb-0
```

rather than receiving an arbitrary Deployment-generated Pod name.

The StatefulSet is associated with a headless Service called:

```text
mongodb
```

The database listens on port 27017.

### Why a StatefulSet instead of a Deployment?

A Deployment is well suited to stateless workloads where Pods can be freely replaced.

MongoDB contains persistent application data, so the database requires stable storage and predictable identity.

For this reason, a StatefulSet is the more appropriate Kubernetes object.

This also satisfies the bonus requirement concerning StatefulSets for the database layer.

---

# 2. Method Used to Expose Pods to Internet Traffic

The frontend is exposed using a Kubernetes `LoadBalancer` Service.

The Service configuration is conceptually:

```text
Internet
   |
   v
GKE LoadBalancer
   |
   v
Frontend Service
   |
   v
Frontend Pods
```

When the LoadBalancer Service is created on GKE, GKE provisions an external IP address.

The external IP used during testing was:

```text
34.35.156.38
```

Therefore, the live application was accessible at:

```text
http://34.35.156.38
```

---

## Why the Backend Was Not Exposed Publicly

The backend does not require a public IP.

Instead, it is exposed internally using a Kubernetes `ClusterIP` Service.

The frontend communicates with the backend through the Kubernetes network.

This reduces unnecessary public exposure of the backend.

The architecture is:

```text
Browser
   |
   v
Frontend LoadBalancer
   |
   v
Frontend Service
   |
   v
Nginx
   |
   | /api/
   v
Backend Service
   |
   v
Backend Pods
```

---

## Nginx Reverse Proxy

The frontend Docker image uses Nginx to serve the React production build.

Nginx was configured to forward API requests from:

```text
/api/
```

to:

```text
http://backend:5000
```

The hostname `backend` resolves to the Kubernetes backend Service.

This was important because the original React application contained API requests pointing to:

```text
http://localhost:5000
```

That would not work correctly from the deployed browser application because `localhost` refers to the user's own machine.

The frontend API requests were therefore changed to use relative paths such as:

```javascript
axios.get('/api/products')
axios.post('/api/products', newProduct)
axios.delete('/api/products/' + id)
axios.put('/api/products/' + id, editedProduct)
```

Nginx then forwards those requests to the backend Service.

This makes the frontend work correctly through the public GKE address.

---

# 3. Persistent Storage

Persistent storage was implemented for MongoDB using the StatefulSet's `volumeClaimTemplates`.

The MongoDB container mounts the persistent storage at:

```text
/data/db
```

The PVC requests:

```text
5Gi
```

of storage.

The access mode is:

```text
ReadWriteOnce
```

The resulting PVC was:

```text
mongo-data-mongodb-0
```

and was verified to be in the `Bound` state.

---

## Why Persistent Storage Was Necessary

Without persistent storage, deleting the MongoDB Pod could result in loss of database data when the database container is recreated.

The PersistentVolumeClaim separates the database's storage from the temporary lifecycle of the Pod.

Therefore:

```text
MongoDB Pod
     |
     v
PersistentVolumeClaim
     |
     v
Persistent Volume
     |
     v
Persistent Disk
```

If the Pod is recreated, the StatefulSet can reconnect the database to its persistent storage.

---

# Persistence Verification

Persistence was not only configured but also tested.

A product was added to the application before testing the database failure scenario.

The MongoDB Pod was then deliberately deleted:

```bash
kubectl delete pod mongodb-0
```

Because MongoDB was managed by a StatefulSet, Kubernetes automatically recreated the Pod.

The replacement Pod returned to:

```text
mongodb-0    1/1    Running
```

The PVC remained:

```text
mongo-data-mongodb-0    Bound    5Gi
```

After MongoDB restarted, the previously stored products were still visible in the application.

The application was also opened in an incognito browser session and the products remained available.

This provides evidence that the database data was stored on persistent storage rather than only inside the MongoDB Pod's ephemeral filesystem.

---

# 4. Git Workflow

A separate GitHub repository was created specifically for this Kubernetes CAT, as required by the assignment.

The repository contains the Kubernetes manifests and supporting configuration needed to recreate the deployment.

The Git workflow was incremental rather than placing all files into the repository in one commit.

Descriptive commits were used to show the development stages.

Examples include:

```text
initial Kubernetes project structure
add backend deployment and nginx configuration
added frontend deployment and service
add initial project documentation
add initial Kubernetes implementation explanation
```

Additional commits document later improvements and final documentation.

This makes the repository history useful for tracking how the Kubernetes deployment developed from its initial structure to the final working deployment.

---

# 5. Successful Application and Debugging

The application was successfully deployed to GKE.

The Kubernetes resources were checked using commands including:

```bash
kubectl get deployments
kubectl get pods
kubectl get svc
kubectl get pvc
```

The final deployment showed:

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

The MongoDB PVC showed:

```text
mongo-data-mongodb-0    Bound    5Gi
```

---

## Backend Verification

The backend Service was tested from inside the Kubernetes cluster using a temporary curl Pod.

The command:

```bash
kubectl run backend-test \
  --rm -it \
  --image=curlimages/curl \
  --restart=Never \
  -- curl http://backend:5000
```

returned:

```text
Cannot GET /
```

Although this is an HTTP 404 response, it confirmed that the backend Service was reachable.

The backend logs then confirmed:

```text
Server listening on port 5000
Database connected successfully
```

The `Cannot GET /` response was expected because the Express application does not define a root `/` route. Its API is under:

```text
/api/products
```

Therefore the response demonstrated network connectivity rather than a backend failure.

---

## Frontend/API Debugging

The original frontend contained API URLs pointing to:

```text
http://localhost:5000/api/products
```

This was unsuitable for the GKE deployment.

The requests were changed to relative API paths:

```text
/api/products
```

The Nginx configuration was then used to forward `/api/` requests to the Kubernetes backend Service.

This allowed the frontend to communicate with the backend through the public frontend address.

---

## Docker Image Verification

The Docker images were verified on Docker Hub using version-specific tags.

The backend image was:

```text
hodhan/yolo-backend:v1.0.0
```

The frontend image was:

```text
hodhan/yolo-frontend:v1.0.6
```

The manifests therefore reference identifiable, versioned images rather than relying on ambiguous tags.

---

# 6. Docker Image Tag Naming Standards

Personalized Docker Hub repository names were used:

```text
hodhan/yolo-backend
hodhan/yolo-frontend
```

Version tags were added:

```text
v1.0.0
v1.0.6
```

The format makes it possible to distinguish the application and version being deployed.

For example:

```text
hodhan/yolo-backend:v1.0.0
```

can be understood as:

```text
hodhan        → Docker Hub username
yolo-backend  → application/component
v1.0.0       → image version
```

This is preferable to using only `latest`, because the Kubernetes deployment can reference a predictable version.

---

# Kubernetes Controllers and Availability

Kubernetes controllers were used to maintain the desired state of the application.

The backend Deployment specifies:

```text
2 replicas
```

and the frontend Deployment also specifies:

```text
2 replicas
```

If a Pod managed by a Deployment fails, Kubernetes can create a replacement to restore the desired number of replicas.

MongoDB is managed by the StatefulSet controller.

The database Pod was deliberately deleted during testing, and Kubernetes recreated it automatically.

This demonstrated the controller's ability to maintain the desired workload state.

---

# Labels and Selectors

Labels were used to identify application components and allow Services to select the correct Pods.

For example, the backend uses:

```yaml
labels:
  app: yolo
  component: backend
```

The backend Service uses matching selectors to route traffic to the backend Pods.

The frontend similarly uses application/component labels.

MongoDB uses its own `app: mongodb` selector because its StatefulSet was created with that selector and Kubernetes StatefulSet selectors are immutable after creation.

This demonstrates how labels and selectors are used to organize workloads and connect Services to their intended Pods.

---

# Final Verification

The final application was tested through the external GKE LoadBalancer address.

The following functionality was verified:

* Frontend loads successfully.
* Backend is reachable from the frontend.
* MongoDB connects successfully.
* Existing products are displayed.
* New products can be added.
* Products remain available after MongoDB Pod recreation.
* Frontend and backend run with multiple replicas.
* MongoDB runs as a StatefulSet.
* MongoDB uses a PersistentVolumeClaim.
* The frontend is externally exposed through a LoadBalancer.
* The backend and MongoDB remain internally accessible through ClusterIP Services.

---

# Conclusion

The Yolomy application was successfully transitioned from the previous Docker-based deployment into a Kubernetes-orchestrated environment on GKE.

The implementation uses Deployments for the stateless frontend and backend, a StatefulSet for MongoDB, Services for application networking, a LoadBalancer for external access, and persistent storage for database durability.

The deployment was tested both at the Kubernetes networking level and through the live application.

Most importantly, deleting the MongoDB Pod did not result in data loss because the database was backed by persistent storage.

The resulting deployment demonstrates Kubernetes orchestration concepts including workload controllers, service discovery, external exposure, StatefulSets, persistent storage, replica management, labels/selectors, and container image versioning.
