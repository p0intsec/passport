#!/usr/bin/env bash
# Exemplo de gancho para `passport teste-armadilha --ao-final ./exemplos/desbloqueio-generico.sh`.
#
# Depois do teste, a origem usada fica bloqueada na SUA proteção. Este script
# mostra o formato: descobrir o IP capturado (no seu log/API, a partir de
# PC_INICIO_MS) e pedir o desbloqueio. Adapte as duas funções ao seu produto.
#
# Variáveis recebidas do passport:
#   PC_HOST, PC_CAMINHO, PC_INICIO_MS, PC_IP (só check-host),
#   PC_SONDA_PAIS, PC_SONDA_ASN, PC_SONDA_REDE
set -euo pipefail

descobrir_ip() {
  # check-host informa o IP direto; no Globalping, consulte o log da sua proteção:
  # capturas em $PC_HOST + $PC_CAMINHO depois de $PC_INICIO_MS (ASN $PC_SONDA_ASN).
  if [[ -n "${PC_IP:-}" ]]; then echo "$PC_IP"; return; fi
  curl -s "https://minha-protecao.exemplo/api/capturas?host=$PC_HOST&caminho=$PC_CAMINHO&desde=$PC_INICIO_MS" \
    -H "Authorization: Bearer ${MEU_TOKEN:?defina MEU_TOKEN}" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d[-1]['ip'] if d else '')"
}

desbloquear() {
  curl -s -X POST "https://minha-protecao.exemplo/api/desbloquear" \
    -H "Authorization: Bearer ${MEU_TOKEN:?defina MEU_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"ip\":\"$1\",\"motivo\":\"teste passport\"}"
}

ip=$(descobrir_ip)
if [[ -z "$ip" ]]; then echo "     IP de teste não encontrado — desbloqueie manualmente"; exit 1; fi
echo "     desbloqueando $ip ($PC_SONDA_PAIS AS$PC_SONDA_ASN $PC_SONDA_REDE)"
desbloquear "$ip" >/dev/null
