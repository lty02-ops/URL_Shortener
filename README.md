# URL Shortener

긴 URL을 짧고 관리하기 쉬운 링크로 변환하는 URL 단축 서비스입니다.

Spring Boot와 MySQL로 URL 매핑 및 클릭 통계를 관리하며, 로컬 환경은 Docker Compose로 실행합니다. AWS 환경은 Terraform으로 구성하며 CloudFront, S3, ALB, EC2, RDS를 이용한 3-tier 아키텍처를 사용합니다.

## 기능

- 랜덤 단축 코드 생성
- 사용자 지정 단축 코드 생성
- 단축 URL을 통한 원본 URL 리다이렉트
- 생성한 URL 목록 및 클릭 횟수 조회
- 단축 URL 복사 버튼
- 저장된 URL 삭제
- GitHub Actions와 Amazon ECR을 이용한 백엔드 자동 배포
- Auto Scaling Group을 이용한 확장 및 무중단 롤링 배포
- CloudWatch와 SNS를 이용한 EC2, RDS, ALB 모니터링 및 이메일 알림

## 아키텍처

### 전체 구성

![URL Shortener 아키텍처](./image/architecture-final.png)


CloudFront가 서비스의 진입점 역할을 합니다. HTML, CSS, JavaScript 같은 정적 파일은 S3에서 제공하고, API 요청과 단축 URL 리다이렉트 요청은 ALB를 거쳐 Spring Boot 애플리케이션으로 전달합니다.

### 요청 처리 흐름

사용자는 `https://www.url-shortener.p-e.kr`로 접속합니다. 도메인은 CNAME으로 CloudFront에 연결했고, HTTPS 인증서는 CloudFront 요구 사항에 맞춰 `us-east-1`에서 발급했습니다.

정적 파일은 S3에서 제공합니다. `/api/*`와 `/s/*` 요청만 ALB로 보내며, 이 두 경로는 캐시 때문에 응답이 꼬이지 않도록 TTL을 `0`으로 두었습니다. ALB가 받은 요청은 Target Group을 거쳐 EC2의 Spring Boot 컨테이너(`5000`)로 전달되고, URL과 클릭 데이터는 RDS MySQL에 저장됩니다.

### 네트워크 구성

VPC(`10.0.0.0/16`)는 `ap-northeast-2a`, `ap-northeast-2c` 두 가용 영역에 걸쳐 있습니다. 각 AZ마다 Public, Private App, Private DB Subnet을 하나씩 뒀습니다.

ALB와 NAT Gateway는 Public Subnet에 있고, EC2와 RDS는 Private Subnet에 있습니다. EC2에는 공인 IP를 붙이지 않았습니다. Private App Subnet은 같은 AZ의 NAT Gateway를 사용하므로 이미지 다운로드나 패키지 설치 같은 아웃바운드 통신은 가능하고, NAT 장애 범위는 해당 AZ로 제한됩니다.

### 백엔드와 Auto Scaling

백엔드는 EC2에서 Docker 컨테이너로 실행됩니다. Launch Template은 Ubuntu 24.04와 `t3.micro`를 사용하며, User Data에서 Docker와 AWS CLI를 설치한 뒤 ECR의 `latest` 이미지를 실행합니다.

ASG는 두 Private App Subnet에 걸쳐 최소 2대, 기본 2대, 최대 4대로 설정했습니다. 평균 CPU 사용률 `60%`를 기준으로 자동 확장·축소하고, `/health` 검사에 통과한 인스턴스만 ALB 트래픽을 받습니다. 새 버전을 배포할 때는 Instance Refresh로 기존 인스턴스를 차례대로 교체합니다.

### 데이터베이스와 자격 증명

RDS는 MySQL 8.0, `db.t3.micro`, 20GB로 구성했고 현재는 Single-AZ입니다. DB Subnet Group 자체는 두 AZ의 Private DB Subnet을 포함하며, 자동 백업은 하루 동안 보관합니다.

DB 비밀번호는 코드나 User Data에 넣지 않고 RDS 관리형 Secrets Manager secret으로 보관합니다. EC2는 IAM Role로 RDS 접속 정보와 비밀번호를 조회해 컨테이너 환경 변수로 넘깁니다.

### 접근 제어와 보안

Security Group은 `ALB → EC2:5000 → RDS:3306` 흐름만 열었습니다. S3 버킷도 공개하지 않고 CloudFront OAI를 통해서만 파일을 읽을 수 있게 했습니다.

EC2 관리는 SSH 대신 Session Manager를 사용합니다. 이를 위해 SSM, SSM Messages, EC2 Messages용 VPC Endpoint를 두 App Subnet에 만들었습니다. EC2 IAM Role에는 SSM 접속, ECR 이미지 조회, DB 비밀번호 조회에 필요한 권한만 넣었습니다.

### CI/CD 배포 흐름

`main` 브랜치의 백엔드 코드가 바뀌면 GitHub Actions가 테스트와 Docker 빌드를 실행합니다. AWS 인증에는 Access Key 대신 OIDC Role을 사용합니다.

빌드한 이미지는 커밋 SHA와 `latest` 태그로 ECR에 올리고, 이어서 ASG Instance Refresh를 시작합니다. 워크플로는 롤링 교체가 끝날 때까지 기다리며 실패하거나 시간 제한을 넘기면 배포도 실패로 처리합니다.

### 모니터링

CloudWatch에서는 아래 세 항목을 보고 있습니다. 경보가 발생하거나 정상 상태로 돌아오면 SNS를 통해 이메일을 보냅니다.

- EC2 평균 CPU 사용률 80% 초과
- RDS 평균 CPU 사용률 80% 초과
- 5분 동안 ALB 대상에서 발생한 HTTP 5xx 응답 합계가 1 이상

ASG의 CPU 목표값 `60%`는 인스턴스 수를 조절하는 기준이고, CPU `80%` 경보는 운영 알림용입니다.

## 사용 기술

### Application

![Java 17](https://img.shields.io/badge/Java_17-ED8B00?style=flat-square&logo=openjdk&logoColor=white)
![Spring Boot 3.2](https://img.shields.io/badge/Spring_Boot_3.2-6DB33F?style=flat-square&logo=springboot&logoColor=white)
![MySQL 8](https://img.shields.io/badge/MySQL_8-4479A1?style=flat-square&logo=mysql&logoColor=white)
![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=flat-square&logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=flat-square&logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=flat-square&logo=javascript&logoColor=black)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=flat-square&logo=nginx&logoColor=white)

### Infrastructure

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=flat-square&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat-square&logo=amazonwebservices&logoColor=white)

- AWS: VPC, CloudFront, ACM, S3, ALB, EC2 Auto Scaling, ECR, RDS, IAM, Systems Manager, Secrets Manager, CloudWatch, SNS
- CI/CD: GitHub Actions, AWS OIDC, EC2 Instance Refresh
- Local: Docker Compose

## API

| Method | Endpoint | 설명 |
|---|---|---|
| `POST` | `/api/shorten` | 랜덤 또는 사용자 지정 코드로 단축 URL 생성 |
| `GET` | `/s/{shortCode}` | 원본 URL로 리다이렉트하고 클릭 수 증가 |
| `GET` | `/api/urls` | 생성된 URL 목록 조회 |
| `GET` | `/api/stats/{shortCode}` | 생성 시각과 클릭 수 조회 |
| `DELETE` | `/api/urls/{id}` | 저장된 URL 삭제 |

단축 URL 생성 요청 예시:

```json
{
  "url": "https://example.com/very/long/url",
  "custom_code": "my-link"
}
```

`custom_code`는 생략할 수 있습니다.

## 로컬 실행

### 사전 요구 사항

- Docker
- Docker Compose

`infra/.env` 파일을 생성합니다.

```env
MYSQL_ROOT_PASSWORD=change_me
DB_PASSWORD=change_me
```

프로젝트 루트에서 실행합니다.

```powershell
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d --build
```

접속 주소:

```text
Frontend: http://localhost:3000
Backend:  http://localhost:5000
MySQL:    localhost:3306
```

상태 및 로그 확인:

```powershell
docker compose --env-file infra/.env -f infra/docker-compose.yml ps
docker compose --env-file infra/.env -f infra/docker-compose.yml logs -f
```

종료:

```powershell
docker compose --env-file infra/.env -f infra/docker-compose.yml down
```

MySQL 데이터 볼륨까지 삭제하려면 `down -v`를 사용합니다.

## AWS 배포

### 사전 요구 사항

- AWS CLI 인증
- Terraform
- 대상 AWS 계정에서 리소스를 생성할 권한

Terraform 디렉터리로 이동합니다.

```powershell
cd infra/Terraform
```

알림을 받을 이메일 주소를 사용해 `terraform.tfvars`를 생성합니다. `region`, `github_repository`, `github_branch`는 기본값을 변경할 때만 지정하면 됩니다.

```hcl
alarm_email      = "your-email@example.com"
region           = "ap-northeast-2"
github_repository = "lty02-ops/URL_Shortener"
github_branch     = "main"
```

RDS 마스터 비밀번호는 AWS가 관리하며 Secrets Manager에 저장됩니다. `terraform.tfvars`에는 배포 환경 정보가 포함될 수 있으므로 Git에 커밋하지 않습니다.

인프라를 검증하고 배포합니다.

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

배포 결과를 확인합니다.

```powershell
terraform output
```

주요 출력값:

- `cloudfront_domain_name`: 서비스 접속 도메인
- `alb_dns_name`: 백엔드 ALB 도메인
- `db_endpoint`: RDS 접속 엔드포인트
- `autoscaling_group_name`: 백엔드 Auto Scaling Group 이름
- `launch_template_id`: 백엔드 EC2 Launch Template ID
- `ecr_repository_url`: 백엔드 Docker 이미지를 저장할 ECR 주소
- `github_actions_role_arn`: GitHub Actions가 OIDC로 사용할 IAM Role ARN
- `certificate_validation_records`: ACM 인증서 검증에 필요한 DNS 레코드
- `cloudfront_certificate_arn`: CloudFront에 연결되는 ACM 인증서 ARN

### 백엔드 자동 배포

Terraform 적용 후 출력된 IAM Role ARN을 GitHub 저장소의 Actions secret으로 등록합니다.

```bash
terraform output -raw github_actions_role_arn
```

GitHub 저장소의 `Settings > Secrets and variables > Actions`에서 다음 secret을 생성합니다.

```text
AWS_GITHUB_ACTIONS_ROLE_ARN=<github_actions_role_arn 출력값>
```

`main` 브랜치의 `backend/**` 또는 백엔드 배포 워크플로가 변경되면 GitHub Actions가 다음 작업을 수행합니다.

1. Java 17과 Maven으로 백엔드 테스트 실행
2. Docker 이미지 빌드
3. 커밋 SHA와 `latest` 태그로 Amazon ECR에 이미지 푸시
4. Auto Scaling Group Instance Refresh 시작
5. 롤링 배포가 완료될 때까지 상태 확인

EC2 인스턴스는 Launch Template의 User Data를 통해 시작 시 ECR의 `latest` 이미지를 내려받습니다. RDS 접속 정보와 관리형 마스터 비밀번호는 RDS 및 Secrets Manager에서 조회한 후 컨테이너 환경 변수로 전달합니다. 따라서 EC2에 직접 접속해 백엔드를 설치할 필요가 없습니다.

리소스 삭제:

```powershell
terraform destroy
```

## 현재 제약 사항

- RDS는 Single-AZ 인스턴스로 구성되어 데이터베이스 가용 영역 장애에 자동으로 대응하지 못합니다.
- 로그인 기능과 URL 소유권 구분이 없어 모든 사용자가 같은 URL 목록을 조회하고 삭제할 수 있습니다.
- CloudFront에서 ALB로 전달되는 Origin 요청은 HTTP 80을 사용하며, ALB 자체에 HTTPS 리스너는 구성하지 않았습니다.

## 개발자

- GitHub: [lty02-ops](https://github.com/lty02-ops)
