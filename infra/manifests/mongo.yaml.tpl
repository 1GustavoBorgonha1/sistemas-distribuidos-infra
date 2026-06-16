apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongo-data
  namespace: ${namespace}
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: ${storage_size}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
  namespace: ${namespace}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongo
          image: ${image}
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: data
              mountPath: /data/db
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: mongo-data
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
  namespace: ${namespace}
spec:
  selector:
    app: mongo
  ports:
    - port: 27017
      targetPort: 27017
