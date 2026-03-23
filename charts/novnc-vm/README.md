# novnc-vm

가상머신(KubeVirt) + noVNC + Gateway HTTPRoute 구성을 위한 Helm 차트

## 아키텍처

```
Browser ──HTTP/WS──▶ nginx (noVNC UI)
                         │ /k8s/ proxy
                         ▼
                   kubectl-proxy (127.0.0.1:8001)
                         │ ServiceAccount token
                         ▼
                   KubeVirt VNC API (subresources.kubevirt.io)
                         │
                         ▼
                   VirtualMachineInstance (Debian 12)
                         │ CDI DataVolume
                         ▼
                   Debian 12 cloud image (imported via HTTP)
```

### 리소스 구성

| 리소스 | 설명 |
|--------|------|
| `VirtualMachine` | KubeVirt VM 정의 (CPU, Memory, Disk, Network) |
| `DataVolume` | CDI가 Debian 클라우드 이미지를 HTTP로 임포트하는 PVC |
| `Deployment` (noVNC) | kubectl-proxy + nginx 컨테이너 구성 |
| `ConfigMap` | nginx 설정 + noVNC 자동 연결 HTML |
| `Service` | noVNC 웹 UI 서비스 (기본 ClusterIP:8080) |
| `Ingress` / `HTTPRoute` | 외부 접근용 (선택) |
| `ServiceAccount` | noVNC kubectl-proxy 전용 계정 |
| `Role` / `RoleBinding` | KubeVirt VNC 서브리소스 접근 RBAC |

## 사전 요구사항

```bash
# KubeVirt 설치
export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest \
  | grep '"tag_name"' | sed 's/.*: "\(.*\)".*/\1/')
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml

# CDI (Containerized Data Importer) 설치
export CDI_VERSION=$(curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest \
  | grep '"tag_name"' | sed 's/.*: "\(.*\)".*/\1/')
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml
kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml

# KubeVirt 준비 상태 확인
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
```

## 설치

```bash
# 기본 설치
helm install my-debian ./charts/novnc-vm

# 커스텀 values 이용
helm install my-debian ./charts/novnc-vm -f values.example.yaml

# 파라미터 직접 지정
helm install my-debian ./charts/novnc-vm \
  --set vm.cpu.cores=4 \
  --set vm.memory.guest=8Gi \
  --set vm.disk.size=50Gi \
  --set novnc.ingress.enabled=true \
  --set novnc.ingress.hosts[0].host=novnc-vm.example.com
```

## VM 상태 확인

```bash
# DataVolume import 상태 확인 (Succeeded 될 때까지 대기)
kubectl get datavolume -w

# VM 상태 확인
kubectl get vm,vmi

# VM 시작/중지 (virtctl)
virtctl start  my-debian-novnc-vm
virtctl stop   my-debian-novnc-vm
virtctl restart my-debian-novnc-vm
```

## noVNC 웹 콘솔 접속

```bash
# 로컬 port-forward
kubectl port-forward svc/my-debian-novnc-vm-novnc 8080:8080

# 브라우저에서 접속
open http://localhost:8080
```

기본 로그인 정보:
- **Username**: `debian`
- **Password**: `debian`

> ⚠️ 운영 환경에서는 반드시 `vm.cloudInit.userData`의 비밀번호를 변경하세요.

## CLI VNC / SSH 접속

```bash
# VNC 콘솔 (virtctl)
virtctl vnc my-debian-novnc-vm

# SSH (VM에 SSH 서비스 필요)
virtctl ssh debian@my-debian-novnc-vm
```

## Gateway API HTTPRoute 사용

```yaml
# values.yaml
novnc:
  httpRoute:
    enabled: true
    parentRefs:
      - name: my-gateway
        sectionName: http
    hostnames:
      - novnc-vm.example.com
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /
```

## Values 참조

| Key | 기본값 | 설명 |
|-----|--------|------|
| `vm.running` | `true` | VM 실행 상태 |
| `vm.cpu.cores` | `2` | vCPU 코어 수 |
| `vm.cpu.sockets` | `1` | CPU 소켓 수 |
| `vm.cpu.threads` | `1` | 스레드 수 |
| `vm.memory.guest` | `4Gi` | 게스트 메모리 |
| `vm.disk.size` | `20Gi` | 루트 디스크 크기 |
| `vm.disk.storageClassName` | `""` | StorageClass (빈 값 = 클러스터 기본) |
| `vm.disk.accessMode` | `ReadWriteOnce` | PVC 접근 모드 |
| `vm.disk.imageUrl` | Debian 12 cloud URL | CDI 이미지 소스 URL |
| `vm.cloudInit.enabled` | `true` | cloud-init 활성화 |
| `vm.cloudInit.userData` | 기본 설정 | cloud-config 내용 |
| `vm.network.type` | `masquerade` | 네트워크 타입 (`masquerade`/`bridge`) |
| `vm.evictionStrategy` | `LiveMigrate` | 노드 유지보수 시 전략 |
| `novnc.enabled` | `true` | noVNC 콘솔 활성화 |
| `novnc.version` | `1.4.0` | noVNC 버전 |
| `novnc.service.type` | `ClusterIP` | 서비스 타입 |
| `novnc.service.port` | `8080` | 서비스 포트 |
| `novnc.ingress.enabled` | `false` | Ingress 활성화 |
| `novnc.httpRoute.enabled` | `false` | Gateway API HTTPRoute 활성화 |
| `serviceAccount.create` | `true` | ServiceAccount 생성 |

## 에어갭(Air-gap) 환경

noVNC init 컨테이너는 시작 시 GitHub에서 정적 파일을 다운로드합니다.
인터넷이 없는 환경에서는 다음 방법을 사용하세요:

1. noVNC 릴리즈 tarball을 내부 파일서버에 미러링
2. `novnc.image.init` 이미지를 커스텀 이미지로 교체하고 wget URL을 변경
3. 또는 noVNC 파일이 사전 포함된 커스텀 nginx 이미지 사용
