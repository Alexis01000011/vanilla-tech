#!/bin/bash
# install-on-instance.sh — Sube ops/ec2 a S3 y lo instala en la instancia por SSM (requiere autorización:
# modifica /opt/vanilla-tech en el servidor de producción, aunque NO detiene ni reinicia Minecraft).
#
#   INSTANCE_ID=i-... BUCKET=... RELEASE_URL=https://owner.github.io/repo ./install-on-instance.sh
#
# La instancia ya puede leer s3://$BUCKET/modpack/* con su rol; el paquete va a modpack/cd/.
set -euo pipefail
cd "$(dirname "$0")/../ec2"
: "${INSTANCE_ID:?}"; : "${BUCKET:?}"; : "${RELEASE_URL:?}"; export AWS_REGION=${AWS_REGION:-us-east-1}
ST=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text)
[ "$ST" = running ] || { echo "La instancia está $ST; préndela primero (vt-control.sh start)"; exit 1; }
for f in *.sh *.py; do bash -n "$f" 2>/dev/null || [[ "$f" == *.py ]] || { echo "sintaxis: $f"; exit 1; }; done
REV=$(git rev-parse --short HEAD 2>/dev/null || date +%s)
TGZ=$(mktemp --suffix=.tar.gz); trap 'rm -f "$TGZ"' EXIT
tar -czf "$TGZ" lib.sh deploy.sh rollback.sh healthcheck.sh status.sh drill.sh install.sh mc_tools.py cd.env.example
SHA=$(sha256sum "$TGZ" | cut -d' ' -f1); KEY=modpack/cd/vt-cd-$REV-${SHA:0:12}.tar.gz
aws s3 cp "$TGZ" "s3://$BUCKET/$KEY" --only-show-errors
CMD="set -e; d=\$(mktemp -d); aws s3 cp s3://$BUCKET/$KEY \$d/cd.tgz --region $AWS_REGION --only-show-errors; \
echo '$SHA  '\$d/cd.tgz | sha256sum -c --quiet; tar -xzf \$d/cd.tgz -C \$d; \
bash \$d/install.sh --release-url '$RELEASE_URL' --bucket '$BUCKET'; rm -rf \$d; /opt/vanilla-tech/cd/status.sh"
PARAMS=$(python3 -c 'import json,sys;print(json.dumps({"commands":[sys.argv[1]]}))' "$CMD")
CID=$(aws ssm send-command --instance-ids "$INSTANCE_ID" --document-name AWS-RunShellScript --parameters "$PARAMS" \
  --comment "install vanilla-tech cd $REV" --query Command.CommandId --output text)
for _ in $(seq 1 60); do
  S=$(aws ssm get-command-invocation --command-id "$CID" --instance-id "$INSTANCE_ID" --query Status --output text 2>/dev/null || echo Pending)
  case "$S" in Pending|InProgress|Delayed) sleep 3 ;; *) break ;; esac
done
aws ssm get-command-invocation --command-id "$CID" --instance-id "$INSTANCE_ID" --query '[StandardOutputContent,StandardErrorContent]' --output text
[ "$S" = Success ]
