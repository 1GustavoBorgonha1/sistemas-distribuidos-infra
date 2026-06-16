apiVersion: v1
kind: Namespace
metadata:
  name: ${namespace}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app_name}
  namespace: ${namespace}
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: ${app_name}
  template:
    metadata:
      labels:
        app: ${app_name}
    spec:
      containers:
        - name: ${app_name}
          image: ${image}
          imagePullPolicy: Always
          ports:
            - containerPort: ${container_port}
          env:
            - name: PORT
              value: "${container_port}"
            - name: NODE_ENV
              value: "production"
            - name: AWS_REGION
              value: "${aws_region}"
            - name: MONGO_URI
              value: "${mongo_uri}"
            - name: REDIS_URL
              value: "${redis_url}"
            - name: SQS_QUEUE_URL
              value: "${sqs_queue_url}"
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: JWT_SECRET
          readinessProbe:
            httpGet:
              path: ${health_check_path}
              port: ${container_port}
            initialDelaySeconds: 10
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: ${health_check_path}
              port: ${container_port}
            initialDelaySeconds: 20
            periodSeconds: 15
---
apiVersion: v1
kind: Service
metadata:
  name: ${app_name}
  namespace: ${namespace}
spec:
  type: NodePort
  selector:
    app: ${app_name}
  ports:
    - port: ${container_port}
      targetPort: ${container_port}
      nodePort: ${node_port}
