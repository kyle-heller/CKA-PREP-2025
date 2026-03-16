#!/bin/bash
# solve-and-verify.sh — Automated solve + verify for all 17 CKA questions
# Phase 1: Run all LabSetUp scripts (Q15 etcd-fix LAST — breaks API server)
# Phase 2: Solve + verify each question (Q15 FIRST — fix API server)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS_COUNT=0
FAIL_COUNT=0
ERROR_COUNT=0
RESULTS=()

# ─── Helpers ────────────────────────────────────────────────────────────────

wait_for_apiserver() {
  echo "[INFO] Waiting for API server to become available..."
  local max_wait=120
  local elapsed=0
  while ! kubectl get nodes &>/dev/null; do
    sleep 5
    elapsed=$((elapsed + 5))
    if [ $elapsed -ge $max_wait ]; then
      echo "[ERROR] API server did not come back after ${max_wait}s"
      return 1
    fi
    echo "[INFO] Still waiting... (${elapsed}s)"
  done
  echo "[INFO] API server is up after ${elapsed}s"
}

run_verify() {
  local dir="$1"
  local name="$(basename "$dir")"
  echo ""
  echo "━━━ Verifying: $name ━━━"
  if bash "$dir/Verify.bash"; then
    echo ">>> RESULT: $name = PASS"
    RESULTS+=("PASS: $name")
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo ">>> RESULT: $name = FAIL"
    RESULTS+=("FAIL: $name")
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# ─── Question directories ──────────────────────────────────────────────────

ALL_DIRS=(
  01-mariadb-persistent-volume
  02-argocd-helm
  03-sidecar
  04-resource-allocation
  05-hpa
  06-crds-cert-manager
  07-priority-class
  08-cni-network-policy
  09-cri-dockerd
  10-taints-tolerations
  11-gateway-api
  12-ingress
  13-network-policy
  14-storage-class
  15-etcd-fix
  16-nodeport
  17-tls-config
)

API_SERVER_QUESTION="15-etcd-fix"

# ─── Phase 1: LabSetUp ─────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   PHASE 1: Lab Setup (all questions)     ║"
echo "╚══════════════════════════════════════════╝"

# Run all non-API-server questions first
for dir in "${ALL_DIRS[@]}"; do
  if [ "$dir" = "$API_SERVER_QUESTION" ]; then
    continue
  fi
  full_path="$SCRIPT_DIR/$dir"
  if [ -f "$full_path/LabSetUp" ]; then
    echo ""
    echo "--- Setup: $dir ---"
    bash "$full_path/LabSetUp" || echo "[WARN] Setup had errors: $dir"
  fi
done

# Q15 etcd-fix LAST (intentionally breaks API server)
echo ""
echo "--- Setup: $API_SERVER_QUESTION (API SERVER WILL BREAK) ---"
bash "$SCRIPT_DIR/$API_SERVER_QUESTION/LabSetUp" || echo "[WARN] Setup had errors: $API_SERVER_QUESTION"

echo ""
echo "=== Phase 1 complete ==="

# ─── Phase 2: Solve + Verify ───────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  PHASE 2: Solve + Verify (all questions) ║"
echo "╚══════════════════════════════════════════╝"

# ─── Q15: Etcd Fix (MUST BE FIRST — API server is broken) ──────────────────

echo ""
echo "━━━ Solving: 15-etcd-fix (CRITICAL — fix API server first) ━━━"
sudo sed -i 's/:2380/:2379/g' /etc/kubernetes/manifests/kube-apiserver.yaml
wait_for_apiserver
run_verify "$SCRIPT_DIR/15-etcd-fix"

# ─── Q01: MariaDB Persistent Volume ────────────────────────────────────────

echo ""
echo "━━━ Solving: 01-mariadb-persistent-volume ━━━"
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  storageClassName: ""
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
EOF
sed -i 's/claimName: ""/claimName: "mariadb"/' ~/mariadb-deploy.yaml
kubectl apply -f ~/mariadb-deploy.yaml
kubectl wait --for=condition=Available deployment/mariadb -n mariadb --timeout=120s || true
run_verify "$SCRIPT_DIR/01-mariadb-persistent-volume"

# ─── Q02: ArgoCD Helm ──────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 02-argocd-helm ━━━"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm repo add argocd https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update
helm template argocd argocd/argo-cd \
  --version 7.7.3 \
  --namespace argocd \
  --set crds.install=false \
  > /root/argo-helm.yaml
run_verify "$SCRIPT_DIR/02-argocd-helm"

# ─── Q03: Sidecar ──────────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 03-sidecar ━━━"
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      volumes:
      - name: log
        emptyDir: {}
      containers:
      - name: wordpress
        image: wordpress:php8.2-apache
        command: ["/bin/sh", "-c", "while true; do echo 'WordPress is running...' >> /var/log/wordpress.log; sleep 5; done"]
        ports:
        - containerPort: 80
        volumeMounts:
        - name: log
          mountPath: /var/log
      - name: sidecar
        image: busybox:stable
        command: ["/bin/sh", "-c", "tail -f /var/log/wordpress.log"]
        volumeMounts:
        - name: log
          mountPath: /var/log
EOF
kubectl rollout status deployment wordpress --timeout=120s || true
run_verify "$SCRIPT_DIR/03-sidecar"

# ─── Q04: Resource Allocation ──────────────────────────────────────────────

echo ""
echo "━━━ Solving: 04-resource-allocation ━━━"
kubectl scale deployment wordpress -n resources --replicas=0
sleep 2
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: resources
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      initContainers:
      - name: init-setup
        image: busybox
        command: ["sh", "-c", "echo 'Preparing environment...' && sleep 5"]
        resources:
          requests:
            cpu: 300m
            memory: 600Mi
          limits:
            cpu: 400m
            memory: 700Mi
      containers:
      - name: wordpress
        image: wordpress:6.2-apache
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 300m
            memory: 600Mi
          limits:
            cpu: 400m
            memory: 700Mi
EOF
kubectl rollout status deployment wordpress -n resources --timeout=120s || true
run_verify "$SCRIPT_DIR/04-resource-allocation"

# ─── Q05: HPA ──────────────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 05-hpa ━━━"
kubectl apply -f - <<'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apache-server
  namespace: autoscale
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apache-deployment
  minReplicas: 1
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
EOF
run_verify "$SCRIPT_DIR/05-hpa"

# ─── Q06: CRDs (cert-manager) ──────────────────────────────────────────────

echo ""
echo "━━━ Solving: 06-crds-cert-manager ━━━"
kubectl get crd | grep cert-manager > /root/resources.yaml
kubectl explain certificate.spec.subject > /root/subject.yaml 2>/dev/null || \
  kubectl explain certificates.cert-manager.io --api-version=cert-manager.io/v1 > /root/subject.yaml 2>/dev/null || true
run_verify "$SCRIPT_DIR/06-crds-cert-manager"

# ─── Q07: PriorityClass ────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 07-priority-class ━━━"
kubectl apply -f - <<'EOF'
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 999
globalDefault: false
description: "High priority class"
EOF
kubectl patch deployment busybox-logger -n priority \
  -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
kubectl rollout status deployment busybox-logger -n priority --timeout=120s || true
run_verify "$SCRIPT_DIR/07-priority-class"

# ─── Q08: CNI & Network Policy ─────────────────────────────────────────────

echo ""
echo "━━━ Solving: 08-cni-network-policy ━━━"
echo "[INFO] CNI should already be present (Cilium on KillerCoda)"
# Fallback: install Calico if no CNI pods found
CNI_RUNNING=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -cE '(cilium|calico|flannel|weave)' || echo "0")
if [ "$CNI_RUNNING" -eq 0 ]; then
  echo "[INFO] No CNI found — installing Calico..."
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml 2>/dev/null || true
  sleep 30
fi
run_verify "$SCRIPT_DIR/08-cni-network-policy"

# ─── Q09: CRI-Dockerd ──────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 09-cri-dockerd ━━━"
# Install cri-dockerd if .deb exists and dpkg is available
if [ -s /root/cri-dockerd.deb ] && command -v dpkg &>/dev/null; then
  sudo dpkg -i /root/cri-dockerd.deb 2>/dev/null || true
  sudo systemctl enable --now cri-docker.service 2>/dev/null || true
fi
# Configure sysctl
sudo mkdir -p /etc/sysctl.d
sudo tee /etc/sysctl.d/kube.conf >/dev/null <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.ipv6.conf.all.forwarding=1
net.ipv4.ip_forward=1
net.netfilter.nf_conntrack_max=131072
EOF
sudo sysctl --system >/dev/null 2>&1
run_verify "$SCRIPT_DIR/09-cri-dockerd"

# ─── Q10: Taints & Tolerations ─────────────────────────────────────────────

echo ""
echo "━━━ Solving: 10-taints-tolerations ━━━"
kubectl taint nodes node01 PERMISSION=granted:NoSchedule 2>/dev/null || true
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
  tolerations:
  - key: PERMISSION
    operator: Equal
    value: granted
    effect: NoSchedule
EOF
kubectl wait --for=condition=Ready pod/nginx --timeout=120s || true
run_verify "$SCRIPT_DIR/10-taints-tolerations"

# ─── Q11: Gateway API ──────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 11-gateway-api ━━━"
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: nginx-class
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: gateway.web.k8s.local
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: web-tls
EOF
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "gateway.web.k8s.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80
EOF
run_verify "$SCRIPT_DIR/11-gateway-api"

# ─── Q12: Ingress ──────────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 12-ingress ━━━"
kubectl expose deployment echo -n echo-sound \
  --name echo-service --type NodePort --port 8080 --target-port 8080 2>/dev/null || true
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: echo-sound
spec:
  rules:
  - host: example.org
    http:
      paths:
      - path: /echo
        pathType: Prefix
        backend:
          service:
            name: echo-service
            port:
              number: 8080
EOF
run_verify "$SCRIPT_DIR/12-ingress"

# ─── Q13: Network Policy ───────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 13-network-policy ━━━"
kubectl apply -f /root/network-policies/network-policy-3.yaml
run_verify "$SCRIPT_DIR/13-network-policy"

# ─── Q14: StorageClass ─────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 14-storage-class ━━━"
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
# Remove default from any other SC
for sc in $(kubectl get sc -o jsonpath='{.items[*].metadata.name}'); do
  if [ "$sc" != "local-storage" ]; then
    kubectl patch storageclass "$sc" -p \
      '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' 2>/dev/null || true
  fi
done
run_verify "$SCRIPT_DIR/14-storage-class"

# ─── Q16: NodePort ─────────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 16-nodeport ━━━"
kubectl patch deployment nodeport-deployment -n relative --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/ports","value":[
    {"name":"http","containerPort":80,"protocol":"TCP"}
  ]}
]'
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  namespace: relative
spec:
  type: NodePort
  selector:
    app: nodeport-deployment
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    nodePort: 30080
EOF
run_verify "$SCRIPT_DIR/16-nodeport"

# ─── Q17: TLS Config ───────────────────────────────────────────────────────

echo ""
echo "━━━ Solving: 17-tls-config ━━━"
# Edit ConfigMap to remove TLSv1.2
kubectl get configmap nginx-config -n nginx-static -o yaml | \
  sed 's/ssl_protocols TLSv1.2 TLSv1.3;/ssl_protocols TLSv1.3;/' | \
  kubectl apply -f -
# Add /etc/hosts entry
SVC_IP=$(kubectl get svc nginx-static -n nginx-static -o jsonpath='{.spec.clusterIP}')
if ! grep -q 'ckaquestion.k8s.local' /etc/hosts; then
  echo "$SVC_IP ckaquestion.k8s.local" >> /etc/hosts
fi
# Restart to pick up new ConfigMap
kubectl rollout restart -n nginx-static deployment nginx-static
kubectl rollout status -n nginx-static deployment nginx-static --timeout=120s || true
run_verify "$SCRIPT_DIR/17-tls-config"

# ─── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║            FINAL RESULTS                 ║"
echo "╚══════════════════════════════════════════╝"
for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo ""
echo "  PASSED: $PASS_COUNT / $((PASS_COUNT + FAIL_COUNT + ERROR_COUNT))"
echo "  FAILED: $FAIL_COUNT"
echo "  ERRORS: $ERROR_COUNT"

if [ $FAIL_COUNT -eq 0 ] && [ $ERROR_COUNT -eq 0 ]; then
  echo ""
  echo "=== ALL 17 QUESTIONS PASSED ==="
  exit 0
else
  echo ""
  echo "=== SOME QUESTIONS FAILED ==="
  exit 1
fi
