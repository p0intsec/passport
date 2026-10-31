# passport

> **Troubleshooting de qualquer URL a partir de qualquer país** — direto do terminal, sem conta e sem token.
>
> *Troubleshoot any URL from any country, straight from your terminal, using the public Globalping and check-host.net probe networks. CLI in Brazilian Portuguese, with English aliases (`availability`, `request`, `trap-test`).*

Desenvolvido por **[p0intsec](https://github.com/p0intsec)**.

```
$ passport KZ https://exemplo.com
  KZ Almaty             G-Core Labs                    AS202422  → HTTP 200  108 ms

$ passport BR,DE,JP https://exemplo.com
  BR Sao Paulo          Oracle                         AS31898   → HTTP 200  25 ms
  DE Falkenstein        Hetzner Online                 AS24940   → HTTP 200  58 ms
  JP Tokyo              xTom                           AS3258    → HTTP 200  29 ms
```

Serve para responder rápido perguntas como *"o site abre no Cazaquistão?"*, *"o geobloqueio está funcionando?"*, *"a latência na Ásia está ruim só pra gente?"* e *"a regra do WAF por país/ASN está ativa?"*. Também tem um modo de **validação de armadilha** (honeypot/WAF) em 4 etapas:

```
$ passport teste-armadilha --host app.exemplo.com.br --pais KZ --canary-texto meu-canary

passport — teste de armadilha
  host: app.exemplo.com.br   isca: /wp-login.php   origem: país KZ   controle: US

1) Canary (/robots.txt)
  ✔ texto do canary presente — host atrás da proteção
2) Isca a partir de KZ
     sonda: Almaty/KZ — Scalaxy (AS58061)
  ✔ HTTP 200 em 5076 ms
3) A mesma sonda acessa /
  ✔ barrado (HTTP 403)
4) Controle: US acessa /
  ✔ HTTP 200 em 1320 ms (Buffalo/US)
Tudo certo.
```

---

## Sumário

- [Por que existe](#por-que-existe)
- [Instalação](#instalação)
- [Atalho: `passport CC URL`](#atalho-passport-cc-url)
- [Comandos](#comandos)
  - [`disponibilidade` — quais países estão ativos agora](#disponibilidade--quais-países-estão-ativos-agora)
  - [`requisicao` — uma requisição a partir de um país](#requisicao--uma-requisição-a-partir-de-um-país)
  - [`teste-armadilha` — validação de honeypot/WAF em 4 etapas](#teste-armadilha--validação-de-honeypotwaf-em-4-etapas)
- [Gancho `--ao-final` (ex.: desbloquear o IP de teste)](#gancho---ao-final)
- [Como funciona por dentro](#como-funciona-por-dentro)
- [Limites e pegadinhas](#limites-e-pegadinhas)
- [Uso responsável](#uso-responsável)
- [Desenvolvimento](#desenvolvimento)

---

## Por que existe

Quem opera WAF, honeypot, geobloqueio ou regras por país precisa responder perguntas como:

- *"Um visitante do Cazaquistão consegue abrir o site?"*
- *"A regra de bloqueio por país está funcionando de verdade?"*
- *"Se um IP cai na armadilha, ele fica bloqueado em todo lugar — e só ele?"*

Testar da própria máquina não serve: a sua saída é sempre o mesmo país, e muitas vezes passa por VPN/ZTNA (Cloudflare WARP, Zscaler…) que a própria proteção trata de forma diferente. O `passport` dispara a requisição de **servidores públicos espalhados pelo mundo**, escolhendo o país, e organiza o resultado.

Ele usa duas redes públicas e gratuitas:

| Rede | Alcance | Como escolher | Tipo de origem |
|---|---|---|---|
| [**Globalping**](https://globalping.io) | ~5.000 sondas, ~120 países | código do país (`--pais KZ`) | datacenter **e** residencial (voluntários) |
| [**check-host.net**](https://check-host.net) | ~50 nós, ~30 países | nome do nó (`--no kz1`) | datacenter |

## Instalação

Requisitos: **bash 4+**, **curl** e **python3** (só biblioteca padrão). Linux, macOS (com bash do Homebrew) e WSL.

```bash
git clone https://github.com/p0intsec/passport.git
cd passport
./passport --help

# opcional: deixar no PATH
sudo ln -s "$PWD/passport" /usr/local/bin/passport
```

Não precisa de conta nem token: as duas APIs são públicas.

## Atalho: `passport CC URL`

O jeito mais rápido — um ou vários países separados por vírgula, uma sonda por país:

```bash
passport KZ https://exemplo.com
passport BR,US,DE,JP,ZA https://exemplo.com/api/status
```

É o mesmo que `passport requisicao --pais KZ --url https://exemplo.com`. Use `passport disponibilidade` para ver quais países têm sondas agora.

## Comandos

### `disponibilidade` — quais países estão ativos agora

```bash
passport disponibilidade          # painel geral
passport disponibilidade KZ       # detalhe de um país
```

O painel cruza as duas redes por país:

```
  Disponibilidade agora — check-host: 48 nós · Globalping: 5390 sondas em 120 países

  País  check-host               Globalping DC  resid.
  ----  ------------------------ ------------- -------
  BR    br1                                 78     102
  KE                                         0       5  (só residencial)
  KZ    kz1                                  8       8
  MA                                         2       0
  ...
```

- **check-host**: nós disponíveis naquele país (use em `--no`).
- **Globalping DC / resid.**: quantas sondas de datacenter e residenciais existem agora.
- **(só residencial)**: o país só tem sondas em internet doméstica — veja [Uso responsável](#uso-responsável).

O detalhe de um país mostra cidade, provedor e ASN de cada origem:

```
  KZ Kazakhstan
  check-host.net (use --no <nó>)
    kz1    Karaganda            185.120.77.165   AS203087
  Globalping (use --pais KZ)
      2x datacenter  Almaty               Scalaxy                              AS58061
      2x datacenter  Almaty               G-Core Labs                          AS202422
      1x residencial Astana               Kazakhtelecom                        AS9198
```

> A disponibilidade muda o tempo todo (sondas entram e saem). País sem nenhuma origem hoje — por exemplo a Argélia (`DZ`) — aparece vazio; use um vizinho (`MA`, `TN`).

### `requisicao` — uma requisição a partir de um país

```bash
passport requisicao --url https://exemplo.com/ --pais KZ
passport requisicao --url https://exemplo.com/ --pais DE --sondas 3
passport requisicao --url https://exemplo.com/ --no kz1
passport requisicao --url https://exemplo.com/status --pais BR --metodo HEAD
```

```
  KZ Almaty             Scalaxy                        AS58061   → HTTP 200  388 ms
  KZ Almaty             G-Core Labs                    AS202422  → HTTP 200  129 ms
```

Bom para: conferir geobloqueio, latência por região, se uma regra de WAF por país/ASN está ativa, ou se um site responde igual em todo lugar.

| Opção | Padrão | |
|---|---|---|
| `--url URL` | — | obrigatório (`https://` é assumido se omitido) |
| `--pais CC` / `--no NÓ` | — | uma das duas |
| `--metodo GET\|HEAD` | `GET` | |
| `--sondas N` | `1` | quantas sondas no país (só Globalping) |
| `--residencial` | desligado | aceita sondas residenciais |

### `teste-armadilha` — validação de honeypot/WAF em 4 etapas

Para quem tem uma **armadilha**: um caminho que nenhum usuário legítimo acessa (ex.: `/wp-login.php` num site que não é WordPress) e que, quando acessado, faz a proteção bloquear o IP.

```bash
passport teste-armadilha --host app.exemplo.com.br --pais KZ --canary-texto meu-canary
passport teste-armadilha --host app.exemplo.com.br --no tr1 --caminho /.env
```

| Etapa | O que faz | Esperado |
|---|---|---|
| 1. canary | `GET /robots.txt` e procura `--canary-texto` | texto presente = o host está atrás da proteção. **Se não estiver, o teste para aqui** e nada é acionado |
| 2. isca | a sonda acessa o caminho-armadilha | `--esperado-isca` (padrão `200`, a isca) |
| 3. bloqueio | **a mesma sonda** acessa `/` | `--esperado-bloqueio` (padrão `403`) |
| 4. controle | sonda de **outro país** acessa `/` | 2xx/3xx — só o IP capturado foi barrado |

Como a etapa 3 garante que é o **mesmo IP**: no Globalping, a medição seguinte reaproveita as sondas da anterior (`locations` = id da medição); no check-host, o nó é fixo.

Saída com código **0** se tudo passou e **1** se alguma etapa falhou — dá para usar em CI ou em rotina agendada.

| Opção | Padrão | |
|---|---|---|
| `--host HOST` | — | obrigatório |
| `--pais CC` / `--no NÓ` | — | uma das duas |
| `--caminho P` | `/wp-login.php` (Globalping), `/.env` (check-host) | caminho-armadilha |
| `--canary-caminho P` | `/robots.txt` | |
| `--canary-texto T` | — | sem ele a etapa 1 é pulada (não recomendado) |
| `--esperado-isca N` | `200` | |
| `--esperado-bloqueio N` | `403` | |
| `--controle CC` | `US` | |
| `--ao-final CMD` | — | ver abaixo |
| `--residencial` | desligado | |

## Gancho `--ao-final`

A origem de teste **fica bloqueada** no seu sistema depois do teste. Como cada proteção desbloqueia de um jeito (painel, API, lista de IP…), o `passport` não faz isso sozinho: ele executa o comando que você passar em `--ao-final`, com estas variáveis:

| Variável | Conteúdo |
|---|---|
| `PC_HOST` | host testado |
| `PC_CAMINHO` | caminho-armadilha usado |
| `PC_INICIO_MS` | início do teste (epoch em ms) — para achar a captura certa no seu log |
| `PC_IP` | IP da origem (só check-host; o Globalping não expõe o IP da sonda) |
| `PC_SONDA_PAIS`, `PC_SONDA_ASN`, `PC_SONDA_REDE` | país, ASN e provedor da sonda |

Exemplo genérico — buscar no seu log o IP capturado depois de `PC_INICIO_MS` e chamar a sua API de desbloqueio:

```bash
passport teste-armadilha --host app.exemplo.com.br --pais KZ --canary-texto meu-canary \
  --ao-final './meu-desbloqueio.sh'
```

```bash
#!/usr/bin/env bash
# meu-desbloqueio.sh — exemplo; adapte à sua proteção
IP=$(minha-ferramenta capturas --host "$PC_HOST" --caminho "$PC_CAMINHO" --desde "$PC_INICIO_MS" --ultimo-ip)
[ -n "$IP" ] && curl -s -X POST "https://minha-protecao.exemplo/api/unblock" \
  -H "Authorization: Bearer $MEU_TOKEN" -d "{\"ip\":\"$IP\"}"
```

Mais exemplos em [`exemplos/`](exemplos/).

## Como funciona por dentro

- **Globalping** — `POST https://api.globalping.io/v1/measurements` com `type: http`, `locations: [{country, tags:["datacenter-network"]}]` e o caminho em `measurementOptions.request.path`; depois `GET /v1/measurements/{id}` até terminar. Para repetir a mesma sonda, `locations` passa a ser o id da medição anterior.
- **check-host.net** — `GET https://check-host.net/check-http?host=URL&node=NÓ` e `GET /check-result/{id}`; a lista de nós vem de `/nodes/hosts`.
- O `passport` envia um `User-Agent` próprio nas chamadas às APIs; a requisição ao seu site sai com o User-Agent de cada rede (`CheckHost (https://check-host.net/)` no check-host).

## Limites e pegadinhas

- **O Globalping recusa caminhos sensíveis** como `/.env` e `/.git/config` ("not allowed for security reasons") — é proteção antiabuso deles. Por isso a isca padrão no Globalping é `/wp-login.php`. Para `/.env`, use `--no` (check-host). A mensagem de recusa é mostrada como veio da API.
- **Cota** do Globalping sem conta: cerca de 250 medições por hora por IP. Um `teste-armadilha` gasta 3.
- **O Globalping não informa o IP da sonda** — só país, cidade, provedor e ASN. Ache o IP pelo log da sua proteção (veja `PC_INICIO_MS`).
- **Tempo**: a etapa 2 costuma demorar alguns segundos se a sua armadilha atrasa a resposta de propósito (tarpit) — é esperado.
- **Sua VPN/ZTNA não interfere**: as requisições ao site saem das sondas, não da sua máquina. Só o canary (etapa 1) sai da sua máquina.

## Uso responsável

- **Teste apenas sistemas que você opera ou está autorizado a testar.** O `teste-armadilha` dispara acesso a caminhos típicos de varredura.
- **Prefira hosts de desenvolvimento**: a URL testada passa por serviços de terceiros e o resultado pode ficar visível neles por um tempo.
- **Sempre desbloqueie a origem de teste.** As sondas residenciais do Globalping rodam em **computadores de voluntários** — esquecer o bloqueio barra uma pessoa real no seu site. Por isso o padrão é usar só sondas de datacenter; `--residencial` existe para quando o país não tem outra opção.
- **Respeite os serviços**: sem rajadas, sem uso como ferramenta de carga. Eles são gratuitos e mantidos pela comunidade.

## Desenvolvimento

```bash
bash -n passport           # sintaxe
shellcheck -S warning passport
./passport disponibilidade KZ
```

O CI (`.github/workflows/ci.yml`) roda `bash -n`, ShellCheck e o `--help` a cada push. Contribuições são bem-vindas — veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Autor

Desenvolvido e mantido por **[p0intsec](https://github.com/p0intsec)**.

Licença: [MIT](LICENSE).
