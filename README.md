# Projeto Infra com Docker

Infraestrutura AWS completa provisionada com Terraform, containerizada com Docker e entregue via pipeline CI/CD com GitHub Actions.

---

## Visão geral

Este projeto implementa uma arquitetura escalável na AWS com separação de ambientes (dev/prod), state remoto, autoscaling baseado em métricas de CPU, e deploy automatizado de containers Docker via ECR.

O foco principal está em dois pilares: **segurança por padrão** (IAM com least privilege, state criptografado, acesso público bloqueado) e **escalabilidade eficiente** (containers leves via Docker eliminam overhead de instalação, ASG ajusta capacidade automaticamente sem desperdício de recurso).

---

## Arquitetura

```
GitHub Actions
    ├── terraform plan / apply
    ├── docker build + push → Amazon ECR
    │
    └── AWS VPC (dev: 10.0.0.0/16 | prod: 10.1.0.0/16)
            │
            ├── Application Load Balancer (HTTP :80)
            │       ├── Subnet pública 1 — us-east-1a
            │       │       └── EC2 (t3.micro) → Docker → Node.js :3000
            │       └── Subnet pública 2 — us-east-1b
            │               └── EC2 (t3.micro) → Docker → Node.js :3000
            │
            ├── Auto Scaling Group (min 1 / desired 2 / max 4)
            ├── CloudWatch Alarms (CPU >70% scale out | <30% scale in)
            └── Internet Gateway + Route Tables
```

---

## Stack de tecnologias

| Categoria | Tecnologia |
|---|---|
| IaC | Terraform 1.14 |
| Cloud | AWS (VPC, EC2, ALB, ASG, ECR, S3, DynamoDB, IAM, CloudWatch) |
| Containerização | Docker + Amazon ECR |
| CI/CD | GitHub Actions |
| Aplicação | Node.js 18 (Alpine) |
| Estado remoto | S3 + DynamoDB (lock) |

---

## Estrutura do projeto

```
aws-scalable-infra-terraform/
├── .github/
│   └── workflows/
│       └── terraform.yml       # Pipeline CI/CD
├── app/
│   ├── app.js                  # Aplicação Node.js
│   ├── Dockerfile              # Imagem Docker
│   └── .dockerignore
├── modules/
│   ├── vpc/                    # VPC, subnets, IGW, route tables
│   ├── ec2/                    # Security group, IAM role, Launch Template
│   ├── asg/                    # ALB, Target Group, ASG, CloudWatch
│   └── ecr/                    # Repositório de imagens + lifecycle policy
└── environments/
    ├── dev/                    # Ambiente de desenvolvimento
    │   ├── main.tf
    │   ├── variables.tf
    │   └── backend.tf (S3 key: dev/terraform.tfstate)
    └── prod/                   # Ambiente de produção
        ├── main.tf
        ├── variables.tf
        └── backend.tf (S3 key: prod/terraform.tfstate)
```

---

## Destaques técnicos

**Segurança**
- IAM Role com `AmazonEC2ContainerRegistryReadOnly` — instâncias EC2 acessam o ECR sem credenciais estáticas
- Bucket S3 com criptografia AES-256, versionamento e bloqueio de acesso público
- Security Groups com regras mínimas (princípio do least privilege)
- Credenciais AWS nunca no código — armazenadas como Secrets no GitHub

**Eficiência de recursos**
- Imagem Docker baseada em `node:18-alpine` (~50MB vs ~900MB da imagem completa)
- Lifecycle policy no ECR mantém apenas as 5 últimas imagens
- ASG escala automaticamente com base em CPU real, sem capacidade ociosa fixa
- `terraform destroy` disponível via pipeline manual — infraestrutura sobe e desce sob demanda

**Multi-ambiente**
- Módulos compartilhados entre dev e prod — zero duplicação de código
- States completamente isolados no S3 (`dev/` e `prod/` keys separadas)
- CIDRs diferentes por ambiente (dev: `10.0.x.x` | prod: `10.1.x.x`)
- Nomes de recursos com prefixo de ambiente (`dev-app-alb`, `prod-app-alb`)

**CI/CD**
- Push na `master` dispara `terraform plan` + `terraform apply` automaticamente
- `terraform destroy` disponível via `workflow_dispatch` manual com escolha de ambiente
- Build Docker e push para ECR integrados ao pipeline antes do apply

---

## Como usar

### Pré-requisitos
- Terraform >= 1.14
- AWS CLI configurado (`aws configure`)
- Docker instalado
- Conta AWS com permissões de IAM, EC2, VPC, ELB, ECR, S3, DynamoDB

### Backend (executar uma vez)

```bash
cd terraform-backend
terraform init
terraform apply
```

### Deploy do ambiente dev

```bash
cd environments/dev

# Criar terraform.tfvars com os valores do ambiente
cp terraform.tfvars.example terraform.tfvars

terraform init
terraform plan
terraform apply
```

### Valores de variáveis (dev)

```hcl
aws_region          = "us-east-1"
vpc_cidr            = "10.0.0.0/16"
subnet_cidr         = "10.0.1.0/24"
availability_zone   = "us-east-1a"
subnet_cidr_2       = "10.0.2.0/24"
availability_zone_2 = "us-east-1b"
instance_type       = "t3.micro"
ami_id              = "ami-0c02fb55956c7d316"
```

### Build e push da imagem Docker

```bash
# Autenticar no ECR
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS \
  --password-stdin <905542450009>.dkr.ecr.us-east-1.amazonaws.com

# Build e push
docker build -t <ecr-url>/dev-app:latest ./app
docker push <ecr-url>/dev-app:latest
```

### Destruir recursos

Via pipeline (recomendado):
- GitHub Actions → Terraform CI/CD → Run workflow → action: `destroy` → environment: `dev`

Via CLI:
```bash
cd environments/dev && terraform destroy
```

---

## Autor

Desenvolvido por André Leão como projeto de portfólio DevOps.

[LinkedIn](https://www.linkedin.com/in/andré-leão-andrade-424786175/)  ·  [GitHub](https://github.com/LeaoAndre3107)