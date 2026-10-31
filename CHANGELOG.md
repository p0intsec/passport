# Changelog

## 1.0.0 — 2026-10-31

- Atalho `passport CC[,CC...] URL`: requisição a partir de um ou vários países.
- `disponibilidade [CC]`: painel de países/servidores ativos (Globalping + check-host.net), com separação datacenter × residencial.
- `requisicao`: GET/HEAD a partir de país (`--pais`) ou nó (`--no`), várias sondas.
- `teste-armadilha`: validação de honeypot/WAF em 4 etapas (canary, isca, bloqueio da mesma sonda, controle), gancho `--ao-final`, código de saída para CI.
- Sondas de datacenter por padrão (`--residencial` para liberar as residenciais).
