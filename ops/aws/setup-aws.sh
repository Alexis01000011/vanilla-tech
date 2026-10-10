#!/bin/bash
# setup-aws.sh — Configuración ÚNICA de AWS para el pipeline (requiere autorización del dueño de la cuenta).
# Crea/actualiza, sin costo mensual:
#   1. el proveedor OIDC de GitHub Actions (token.actions.githubusercontent.com), si no existe;
#   2. el rol vanilla-tech-github-deploy: solo asumible desde el environment "production" de ESTE repo,
#      con permiso de ejecutar UN documento SSM sobre UNA instancia y de prenderla (nunca apagarla);
#   3. el documento SSM VanillaTech-Deploy (ssm-document.yaml).
# No crea instancias, IPs, buckets ni cambia security groups. Imprime las variables para GitHub.
#
#   GITHUB_REPO=owner/repo INSTANCE_ID=i-... ./setup-aws.sh [--dry-run]
set -euo pipefail
cd "$(dirname "$0")"
: "${GITHUB_REPO:?owner/repo}"; : "${INSTANCE_ID:?i-...}"; REGION=${AWS_REGION:-us-east-1}; ROLE=vanilla-tech-github-deploy
[[ "$GITHUB_REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "GITHUB_REPO inválido"; exit 1; }
[[ "$INSTANCE_ID" =~ ^i-[0-9a-f]{8,17}$ ]] || { echo "INSTANCE_ID inválido"; exit 1; }
DRY=; [ "${1:-}" = --dry-run ] && DRY=1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
render() { ACCOUNT_ID=$ACCOUNT_ID GITHUB_REPO=$GITHUB_REPO INSTANCE_ID=$INSTANCE_ID REGION=$REGION \
  python3 -c 'import os,sys;s=open(sys.argv[1]).read();[s:=s.replace("${"+k+"}",os.environ[k]) for k in ("ACCOUNT_ID","GITHUB_REPO","INSTANCE_ID","REGION")];print(s)' "$1"; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
render github-oidc-trust.json.tmpl > "$T/trust.json"; render github-deploy-policy.json.tmpl > "$T/policy.json"
python3 -m json.tool "$T/trust.json" >/dev/null; python3 -m json.tool "$T/policy.json" >/dev/null
if [ -n "$DRY" ]; then echo "--- trust"; cat "$T/trust.json"; echo "--- policy"; cat "$T/policy.json"; echo "--- (dry run: nada creado)"; exit 0; fi

PROVIDER=arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$PROVIDER" >/dev/null 2>&1; then
  aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --tags Key=Project,Value=vanilla-tech >/dev/null
  echo "proveedor OIDC creado"
fi
if aws iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
  aws iam update-assume-role-policy --role-name "$ROLE" --policy-document "file://$T/trust.json"
else
  aws iam create-role --role-name "$ROLE" --assume-role-policy-document "file://$T/trust.json" \
    --description "GitHub Actions (environment production) -> SSM VanillaTech-Deploy" --max-session-duration 7200 \
    --tags Key=Project,Value=vanilla-tech >/dev/null
fi
aws iam put-role-policy --role-name "$ROLE" --policy-name vanilla-tech-github-deploy --policy-document "file://$T/policy.json"
echo "rol $ROLE listo"

if aws ssm describe-document --name VanillaTech-Deploy --region "$REGION" >/dev/null 2>&1; then
  v=$(aws ssm update-document --name VanillaTech-Deploy --document-version '$LATEST' --document-format YAML \
       --content file://ssm-document.yaml --region "$REGION" --query DocumentDescription.DocumentVersion --output text 2>&1) || {
    case "$v" in *DuplicateDocumentContent*) v=same ;; *) echo "$v"; exit 1 ;; esac; }
  [ "$v" != same ] && aws ssm update-document-default-version --name VanillaTech-Deploy --document-version "$v" --region "$REGION" >/dev/null
  echo "documento SSM VanillaTech-Deploy: versión ${v}"
else
  aws ssm create-document --name VanillaTech-Deploy --document-type Command --document-format YAML \
    --content file://ssm-document.yaml --tags Key=Project,Value=vanilla-tech --region "$REGION" >/dev/null
  echo "documento SSM VanillaTech-Deploy creado"
fi
cat <<OUT

Variables del repositorio GitHub (Settings > Secrets and variables > Actions > Variables):
  AWS_DEPLOY_ROLE_ARN = arn:aws:iam::$ACCOUNT_ID:role/$ROLE
  EC2_INSTANCE_ID     = $INSTANCE_ID
  AWS_REGION          = $REGION
OUT
