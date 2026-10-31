# Contribuindo

Obrigado pelo interesse! O `passport` é um único script bash — a ideia é continuar assim: fácil de ler, sem dependências além de `bash 4+`, `curl` e `python3`.

## Antes de abrir um PR

```bash
bash -n passport
shellcheck -S warning passport
./passport --help
./passport disponibilidade KZ
./passport KZ https://example.com
```

- Mensagens da CLI em português do Brasil; aliases em inglês são bem-vindos.
- Não adicione nada que dispare requisições contra sistemas de terceiros nos testes automáticos (o CI só roda checagens locais).
- Nunca coloque tokens, IPs internos ou hostnames reais nos exemplos — use `exemplo.com`.
- Respeite as APIs públicas (Globalping, check-host.net): sem rajadas, sem uso como gerador de carga.

## Ideias de evolução

- Saída `--json` para integração com outras ferramentas.
- Suporte a token do Globalping (cota maior) via variável de ambiente.
- Modo `--watch` para acompanhar uma URL por alguns minutos.
