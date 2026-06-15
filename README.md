# aws-scalable-infra-terraform

Infraestrutura AWS escalável provisionada com Terraform, containerizada com Docker e com pipeline CI/CD via GitHub Actions.

---

## Arquitetura

```
GitHub Actions (push → master)
    ├── terraform init / validate / plan / apply
    └── docker build + push → Amazon ECR
           │
           └── AWS VPC (dev: 10.0.0.0/16 | prod: 10.1.0.0/16)
                   │
                   ├── Application Load Balancer (HTTP :80)
                   │       ├── Subnet pública 1 — us-east-1a
                   │       └── Subnet pública 2 — us-east-1b
                   │
                   ├── Auto Scaling Group
                   │       ├── Launch Template → EC2 (t3.micro) → Docker → Node.js :3000
                   │       ├── min: 1 / desired: 2 / max: 4
                   │       └── Health check via ALB
                   │
                   ├── CloudWatch Alarms
                   │       ├── CPU > 70% → scale out (+1 instância)
                   │       └── CPU < 30% → scale in  (-1 instância)
                   │
                   ├── Amazon ECR (repositório por ambiente)
                   │       └── Lifecycle policy: mantém 5 imagens mais recentes
                   │
                   └── Remote State: S3 + DynamoDB (lock)
```

---

## Stack

| Categoria | Tecnologia |
|---|---|
| IaC | Terraform ~> 6.0 (provider AWS) |
| Cloud | AWS — VPC, EC2, ALB, ASG, ECR, S3, DynamoDB, IAM, CloudWatch |
| Containerização | Docker + Amazon ECR |
| CI/CD | GitHub Actions |
| Aplicação | Node.js 18 (Alpine) |
| Estado remoto | S3 + DynamoDB (lock) |

---

## Estrutura

```
aws-scalable-infra-terraform/
├── .github/
│   └── workflows/
│       └── terraform.yml       # Pipeline CI/CD
├── app/
│   ├── app.js                  # Aplicação Node.js
│   ├── Dockerfile              # Imagem Docker (node:18-alpine)
│   └── .dockerignore
├── modules/
│   ├── vpc/                    # VPC, 2 subnets públicas, IGW, route tables
│   ├── ec2/                    # Security group, IAM role, Launch Template, user_data
│   ├── asg/                    # ALB, Target Group, Listener, ASG, CloudWatch alarms
│   └── ecr/                    # Repositório ECR + lifecycle policy
└── environments/
    ├── dev/                    # main.tf + variables.tf (state: s3/dev/terraform.tfstate)
    └── prod/                   # main.tf + variables.tf (state: s3/prod/terraform.tfstate)
```

---

## Decisões de design

**Módulos reutilizáveis entre ambientes**
Dev e prod compartilham os mesmos módulos (`vpc`, `ec2`, `asg`, `ecr`). O comportamento muda via variáveis — `instance_type`, `vpc_cidr`, `environment`. Nenhum código duplicado.

**State remoto isolado por ambiente**
Cada ambiente tem sua própria chave no S3 (`dev/terraform.tfstate`, `prod/terraform.tfstate`). Um `terraform apply` em dev não afeta o state do prod. Lock via DynamoDB previne apply concorrente.

**IAM sem credenciais estáticas nas instâncias**
EC2 assume uma IAM Role com `AmazonEC2ContainerRegistryReadOnly`. O `user_data` autentica no ECR via `aws ecr get-login-password`, que gera token temporário — sem `AWS_ACCESS_KEY_ID` ou `AWS_SECRET_ACCESS_KEY` no código.

**Container leve**
Imagem base `node:18-alpine` (~50MB). A instância não precisa de Node.js instalado — o Docker isola o runtime completamente.

**Autoscaling baseado em CPU real**
ASG escala com base em `CPUUtilization` medida pelo CloudWatch, não em schedule fixo. Cooldown de 120s entre ações evita oscillação.

---

## CI/CD

O pipeline em `.github/workflows/terraform.yml` é disparado em:
- `push` na branch `master` → `terraform apply` automático no ambiente dev
- `workflow_dispatch` manual → escolha de ambiente (dev/prod) e ação (apply/destroy)

**Credenciais AWS no pipeline**: atualmente via `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` como secrets no repositório. A evolução natural seria substituir por OIDC (sem credenciais de longa duração).

**Sequência do pipeline:**
1. Checkout
2. Configurar credenciais AWS
3. `terraform init` → `validate` → `plan`
4. Docker build + push para ECR
5. `terraform apply` (ou `destroy` se acionado manualmente)

---

## Como usar localmente

### Pré-requisitos
- Terraform >= 1.9
- AWS CLI configurado (`aws configure`)
- Bucket S3 e tabela DynamoDB para o backend já criados

### Deploy dev

```bash
cd environments/dev

# Criar arquivo de variáveis
cat > terraform.tfvars << EOF
aws_region          = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
subnet_cidr         = "10.0.1.0/24"
availability_zone   = "us-east-1a"
subnet_cidr_2       = "10.0.2.0/24"
availability_zone_2 = "us-east-1b"
instance_type       = "t3.micro"
ami_id              = "<ID da AMI Amazon Linux 2023>"
EOF

terraform init
terraform plan
terraform apply
```

### Build e push manual da imagem

```bash
# Autenticar no ECR
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS \
  --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build e push
docker build -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/dev-app:latest ./app
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/dev-app:latest
```

### Destruir recursos

```bash
cd environments/dev && terraform destroy
```

Ou via pipeline: **Actions → Terraform CI/CD → Run workflow → action: destroy → environment: dev**

---

## Autor

André Leão — [LinkedIn](https://www.linkedin.com/in/andreLeaoAndrade) · [GitHub](https://github.com/LeaoAndre3107)