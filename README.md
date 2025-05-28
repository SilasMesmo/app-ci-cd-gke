# Treinamento - Implementação de APP com GKE

## 1 - Configuração do terminal

```sh
gcloud auth activate-service-account --key-file=chave.json
gcloud auth list
gcloud config set project playground-s-11-68845520

```

## 2 - Atualizar o arquivo terraform abaixo
Atualize o arquivo abaixo com o projectID

terraform.tfvars


## 3 - Execute o deploy do cluster

```sh
terraform plan
terraform apply --auto-approve
```
## 4 -  Instalar o Ingress no cluster
```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0-beta.0/deploy/static/provider/cloud/deploy.yaml

```

## 5 -  Instalar o CertManager
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.yaml
```

crie um arquivo chamado issuer-staging.yaml
```sh
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: seuemail@gmail.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-staging
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
```

Crie um arquivo chamado cluster-issue.yaml
```sh
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: seuemail@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-prod
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx

```

## 5 -  Deploy da aplicação

```sh
apiVersion: apps/v1
kind: Deployment
metadata:
  labels: 
    app: giropops-senhas
  name: giropops-senhas
spec:
  replicas: 2
  selector:
    matchLabels:
      app: giropops-senhas
  template:
    metadata:
      labels:
        app: giropops-senhas
    spec:
      containers:
      - name: giropops-senhas
        image: linuxtips/giropops-senhas:1.0
        env:
        - name: REDIS_HOST
          value: redis-service
        ports:
        - containerPort: 5000
        imagePullPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  name:  giropops-senhas-svc
  labels:
    app: giropops-senhas
spec:
  selector:
    app:  giropops-senhas
  type:  ClusterIP
  ports:
  - name:  tcp-giropops-senhas
    port:  5000
    targetPort: 5000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis
  name: redis-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - image: redis
        name: redis
        ports:
          - containerPort: 6379
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
          requests:
            memory: "128Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name:  redis-service
  labels:
    app: redis
spec:
  selector:
    app:  redis
  type:  ClusterIP
  ports:
  - protocol: TCP
    port:  6379
    targetPort: 6379
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: giropops-senhas
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - senhas.cosmosit.com.br
    secretName: giropops-container-expert-tls
  rules:
  - host: senhas.cosmosit.com.br
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: giropops-senhas-svc
            port:
              number: 5000
```

## 6 - Configure o CloudBuild com GIT

No Console GCP:

Vá até Cloud Build → Triggers.

Clique em “Create Trigger”.

Escolha o repositório (GitHub, GitLab, Cloud Source).

Defina a branch ou tag que deseja monitorar (main, master, etc.).

Escolha “cloudbuild.yaml” como arquivo de build.

Clique em Create.
