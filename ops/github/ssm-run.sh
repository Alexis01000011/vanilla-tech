#!/bin/bash
# ssm-run.sh — Ejecuta el documento SSM VanillaTech-Deploy en la instancia y espera el resultado.
# Lo usan los workflows deploy/rollback (credenciales por OIDC); también sirve desde una terminal con
# credenciales de admin.
#
#   ssm-run.sh ACTION [--version V --sha256 S] [--target ID] [--flags none|kick|downgrade|kick-downgrade]
#
# Entorno: INSTANCE_ID (obligatorio), AWS_REGION (us-east-1), START_IF_STOPPED=true para prender una
# instancia apagada (solo si quien aprobó lo pidió). Nunca apaga la instancia: eso queda en el cron.
# Exporta a $GITHUB_OUTPUT: status, exit_code, result (línea RESULT del script) y escribe el resumen.
set -euo pipefail
ACTION=${1:?acción}; shift
VERSION=0.0.0; SHA=0000000000000000000000000000000000000000000000000000000000000000; TARGET=previous; FLAGS=none
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION=$2; shift 2 ;; --sha256) SHA=$2; shift 2 ;; --target) TARGET=$2; shift 2 ;; --flags) FLAGS=$2; shift 2 ;;
    *) echo "opción desconocida: $1" >&2; exit 1 ;;
  esac
done
: "${INSTANCE_ID:?INSTANCE_ID requerido}"; export AWS_REGION=${AWS_REGION:-us-east-1}
OUT=${GITHUB_OUTPUT:-/dev/null}; SUM=${GITHUB_STEP_SUMMARY:-/dev/null}
note() { echo "$*"; echo "$*" >> "$SUM"; }

state() { aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text; }
ST=$(state)
for _ in $(seq 1 30); do case "$ST" in pending|stopping) sleep 10; ST=$(state) ;; *) break ;; esac; done
if [ "$ST" = stopped ]; then
  if [ "${START_IF_STOPPED:-false}" != true ]; then
    note "::error::La instancia está apagada. Prende el server (botón o \`vt-control.sh start\`) y vuelve a lanzar el workflow, o lánzalo con start_if_stopped=true. No se cambió nada."
    echo "status=instance-stopped" >> "$OUT"; exit 20
  fi
  note "Prendiendo $INSTANCE_ID (start_if_stopped=true; el cron de inactividad la apagará con backup)."
  aws ec2 start-instances --instance-ids "$INSTANCE_ID" >/dev/null
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
elif [ "$ST" != running ]; then
  note "::error::Estado inesperado de la instancia: $ST"; exit 21
fi
for i in $(seq 1 60); do
  P=$(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID" --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || true)
  [ "$P" = Online ] && break; [ "$i" = 60 ] && { note "::error::El agente SSM no está Online ($P)"; exit 22; }; sleep 10
done

PARAMS=$(python3 -c 'import json,sys;print(json.dumps({k:[v] for k,v in zip(["action","version","sha256","target","flags"],sys.argv[1:])}))' \
  "$ACTION" "$VERSION" "$SHA" "$TARGET" "$FLAGS")
CID=$(aws ssm send-command --instance-ids "$INSTANCE_ID" --document-name VanillaTech-Deploy --parameters "$PARAMS" \
  --timeout-seconds 600 --comment "github ${GITHUB_RUN_ID:-local} $ACTION $VERSION" --query Command.CommandId --output text)
echo "SSM command $CID ($ACTION $VERSION $TARGET $FLAGS)"
while :; do
  sleep 15
  ST=$(aws ssm get-command-invocation --command-id "$CID" --instance-id "$INSTANCE_ID" --query Status --output text 2>/dev/null || echo Pending)
  case "$ST" in Pending|InProgress|Delayed) printf '.' ;; *) echo; break ;; esac
done
INV=$(aws ssm get-command-invocation --command-id "$CID" --instance-id "$INSTANCE_ID" --output json)
RC=$(python3 -c 'import json,sys;print(json.loads(sys.argv[1])["ResponseCode"])' "$INV")
python3 -c 'import json,sys;d=json.loads(sys.argv[1]);print(d["StandardOutputContent"]);print(d["StandardErrorContent"],file=sys.stderr)' "$INV"
RESULT=$(python3 -c 'import json,sys;print(next((l for l in reversed(json.loads(sys.argv[1])["StandardOutputContent"].splitlines()) if l.startswith(("RESULT ","HEALTH ","DRILL "))),""))' "$INV")
{ echo "status=$ST"; echo "exit_code=$RC"; echo "result=${RESULT#* }"; } >> "$OUT"
case "$RC" in
  0) note "✅ \`$ACTION\` OK: \`${RESULT:-sin resumen}\`" ;;
  2) note "⚠️ \`$ACTION\` falló y **se revirtió** al estado anterior (exit 2). Ver la salida del paso." ;;
  3) note "🛑 \`$ACTION\` falló y la reversión también: **intervención manual** (exit 3)." ;;
  10) note "⏸️ Hay jugadores conectados: no se desplegó nada (exit 10). Reintenta cuando salgan o usa kick con su acuerdo." ;;
  11) note "⏸️ Otro deploy/rollback está en curso (exit 11)." ;;
  12) note "🛑 Cambio de Minecraft/NeoForge sin autorización (exit 12)." ;;
  13) note "🛑 Downgrade sin allow_downgrade (exit 13): usa el workflow de rollback." ;;
  *) note "🛑 \`$ACTION\` terminó con código $RC (estado SSM $ST)." ;;
esac
exit "$RC"
