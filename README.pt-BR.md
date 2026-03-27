<p align="center">
  <img src="app/assets/images/testy-logo.png" width="200" alt="Testy Logo" />
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>Português (BR)</strong>
</p>

# Testy

Testy é uma ferramenta opinativa de gestão de testes para equipes de QA que priorizam simplicidade, praticidade e convenções. Crie planos de teste, escreva cenários no formato Dado que/Quando/Então, gere cenários manualmente ou com IA, anexe evidências e exporte relatórios PDF. Também há uma seção completa de gerenciamento de bugs que segue a mesma filosofia: registre-os e gere bug reports rapidamente. Testy é uma ferramenta feita de QA para QA.

A maioria das ferramentas de gestão de testes são repletas de campos, workflows, configurações e integrações que em nada ajudam o QA a escrever seus testes. O Testy adota outra abordagem: oferece-lhe o que precisa e sai do seu caminho.

## Funcionalidades

- **Planos de Teste** — agrupa cenários relacionados num plano nomeado, atribuído a um QA
- **Tags** — categoriza planos com tags (ex: "login", "sprint-23", "regressão") e pesquisa por elas
- **Cenários (Given/When/Then)** — formato Gherkin estruturado
- **Geração de Cenários com IA** — descreve uma funcionalidade em texto livre e deixa o Gemini gerar cenários de teste automaticamente, cobrindo caminhos felizes, casos extremos, valores limite e particionamento de equivalência
- **Drag & Drop para Reordenar** — reordena cenários arrastando-os, com animações FLIP suaves e zona de drop visual; a ordem é persistida e refletida nos relatórios
- **Anexos de Evidências** — faz upload de screenshots diretamente em cada cenário ou bug
- **Aprovar/Reprovar com Um Clique** — marca cenários como aprovados ou falhados inline
- **Status Derivado** — o status do plano é derivado automaticamente a partir dos seus cenários (sem atualizações manuais)
- **Registo de Bugs** — reporta bugs com título, descrição, passos para reproduzir, resultado obtido vs esperado e anexos de evidência; classifica por funcionalidade e causa-raiz; marca como aberto ou resolvido
- **Bug ↔ Cenário** — associa cenários reprovados a bugs
- **Dashboard de Causas-Raiz** — vista de bugs agrupados por tag de causa e tag de funcionalidade, com gráficos de barras para análise rápida de quais são as causas que mais estão originando bugs
- **Pesquisa e Filtros** — pesquisa planos por nome, QA ou tag; pesquisa bugs por ID, título ou descrição; filtra por status, tags e intervalo de datas
- **Paginação** — listagens de planos e bugs paginadas para grandes volumes de dados
- **Relatórios PDF** — exporta relatórios formatados para planos de teste e bugs individuais, com índice (âncoras clicáveis), resumo, cenários e evidências
- **Autenticação e Perfis** — login com username/password com perfis de administrador e utilizador comum
- **Bilingue (EN / PT-BR)** — interface completa em inglês e português brasileiro; alterna idiomas com um clique!
- **API REST** — API JSON completa com autenticação por token para planos de teste, cenários, bugs, tags e anexos de screenshots
- **Testy CLI** — assistente de linha de comando com IA que gerencia planos de teste, executa cenários no browser com Playwright, captura screenshots como evidência e aprova ou reprova cenários automaticamente — tudo a partir de comandos em linguagem natural

## Stack Tecnológica

| Camada | Escolha |
|--------|---------|
| Framework | Rails 8.1 |
| Ruby | 3.4+ |
| Base de Dados | SQLite |
| Frontend | Tailwind CSS v4, Hotwire (Turbo + Stimulus) |
| Armazenamento | Active Storage (disco local) |
| PDF | ferrum_pdf (Chrome headless) |
| IA | Gemini API (Google) |
| CLI | Go (Cobra) + Claude Code (modo IA) |
| Automação de Browser | Playwright MCP |
| Deploy | Kamal-ready (Docker + Thruster) |

## Começar

**Pré-requisitos:** Ruby 3.4+, Node.js (para o build do Tailwind CSS)

```bash
# Clonar o repositório
git clone https://github.com/VictorBitancourt/testy.git
cd testy

# Instalar dependências
bundle install

# Configurar base de dados
bin/rails db:setup

# (Opcional) Definir chave da API Gemini para geração de cenários com IA
export GEMINI_API_KEY=your_key_here

# Iniciar o servidor
bin/dev
```

Abre [http://localhost:3000](http://localhost:3000). No primeiro acesso, será solicitada a criação do utilizador administrador.

## Executar Testes

```bash
bin/rails test
```

Cobre modelos, controllers, autenticação, autorização e comportamento de filtros.

## Testy CLI

O Testy inclui um assistente de linha de comando com IA que permite gerenciar planos de teste, executar cenários no browser e capturar evidências — tudo a partir de comandos em linguagem natural.

### Pré-requisitos

| Requisito | Finalidade |
|---|---|
| Go 1.22+ (ou binário pré-compilado) | Binário do CLI (`cli/bin/testy`) |
| Node.js e `npm install` | Playwright MCP para automação de browser (apenas modo IA) |
| Chromium ou Chrome | Browser para screenshots e execução de testes (apenas modo IA) |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | Agente de IA que alimenta o `testy qa` (opcional) |

### Setup

```bash
# Compilar o CLI a partir do código-fonte (opcional — o binário pode já estar compilado)
cd cli && make build && cd ..

# Se o servidor Testy estiver num endereço diferente:
export TESTY_BASE_URL=http://192.168.1.x:3000

# Fazer login (cria um token local)
bin/testy login <username> <password>
```

### Uso — Comandos Diretos do CLI

O CLI disponibiliza comandos CRUD diretos para todos os recursos:

```bash
# Planos de teste
bin/testy plans list
bin/testy plans show 1
bin/testy plans create "Testes de Login" --qa "Victor"

# Cenários
bin/testy scenarios create "Login válido" --plan 1 --given "..." --when "..." --then "..."
bin/testy scenarios update 5 --plan 1 --status approved

# Bugs
bin/testy bugs list --status open
bin/testy bugs create "Botão partido" --description "..." --steps "..."

# Tags & evidências
bin/testy tags list
bin/testy screenshots attach --plan 1 --scenario 5 --file screenshot.png

# Verificação de saúde
bin/testy doctor
```

Todos os comandos suportam as flags `--json`, `--md` e `--quiet` para formatos de saída.

### Uso — Modo IA (testy qa)

Para execução de testes com IA via Playwright, é necessário o Claude Code e Node.js:

```bash
# Instalar dependências Node.js (Playwright MCP)
npm install

# Modo IA interativo
bin/testy qa

# Comando IA único
bin/testy qa "Executa os cenários do plano 'System Login' em http://localhost:3000"
```

### O que acontece quando executa cenários no modo IA

1. O agente lê os detalhes do cenário (Dado que/Quando/Então)
2. Abre um browser com Playwright e executa os passos (navegar, clicar, escrever)
3. Captura um screenshot do resultado e anexa como evidência
4. Aprova ou reprova o cenário com base no resultado

### Outros comandos do CLI

```bash
bin/testy logout     # Remove o token guardado
bin/testy whoami     # Verifica o estado da autenticação
bin/testy commands   # Lista todos os comandos disponíveis
bin/testy version    # Mostra a versão do CLI
```

### Variáveis de ambiente

| Variável | Padrão | Descrição |
|---|---|---|
| `TESTY_BASE_URL` | `http://localhost:3000` | URL do servidor Testy |
| `TESTY_MODEL` | `sonnet` | Modelo Claude para modo IA (`sonnet`, `opus`, `haiku`) |
| `CHROME_PATH` | Auto-detectado | Caminho para o binário Chromium/Chrome (modo IA) |

## Como Funciona

### Modelo de Dados

```
User (username, password_digest, role)
  |
  +-- Session (user_agent, ip_address)
  |
  +-- TestPlan (name, qa_name)
  |     |
  |     +-- TestScenario (title, given, when, then, status, position)
  |     |     |
  |     |     +-- Ficheiros de Evidência (Active Storage)
  |     |     |
  |     |     +-- Bug (link opcional)
  |     |
  |     +-- Tags (muitos-para-muitos via TestPlanTag)
  |
  +-- Bug (title, description, steps_to_reproduce, obtained_result, expected_result, status)
        |
        +-- Ficheiros de Evidência (Active Storage)
        |
        +-- feature_tag, cause_tag (tags livres com autocomplete)
        |
        +-- TestScenarios (cenários falhados vinculados)
```

### Status Derivado

O status do plano não é um campo armazenado. É calculado a partir dos cenários:

| Status | Regra |
|--------|-------|
| Não Iniciado | Plano tem zero cenários |
| Aprovado | Todos os cenários estão `approved` |
| Falhado | Pelo menos um cenário está `failed` |
| Em Progresso | Tem cenários, nenhum falhado, mas nem todos aprovados |

Um cenário não pode ser aprovado enquanto tiver um bug vinculado — o bug deve ser desvinculado ou resolvido primeiro.

### Exportação PDF

Cada plano tem um botão "Exportar Relatório PDF" que gera um documento formatado com:
- Índice com âncoras clicáveis para cada cenário
- Resumo do plano (total de cenários, contagem de aprovados, QA responsável, tags)
- Cada cenário com passos Dado que, Quando e Então e status
- Imagens de evidência anexadas

Bugs também têm relatórios PDF individuais com descrição, passos para reproduzir, resultado obtido vs esperado e evidências.

## Decisões de Design

**Sem E entre Dado que, Quando e Então.** Isto é intencional. Cada passo é um campo de texto único — não há forma de encadear múltiplas cláusulas com E.

Quando ferramentas permitem E, os cenários inevitavelmente transformam-se em scripts clique-a-clique:

> **Dado que** o utilizador está na página de login  
> **E** o utilizador tem uma conta válida  
> **E** o browser é Chrome  
> **Quando** o utilizador clica no campo de email  
> **E** escreve "user@email.com"  
> **E** clica no campo de password  
> **E** escreve "123456"  
> **E** clica no botão de submit  
> **Então** a página redireciona para /dashboard  
> **E** a mensagem de boas-vindas está visível  
> **E** o cookie de sessão está definido  

Isto não é um cenário de teste — é um script de teste manual. É frágil, ilegível para stakeholders não-técnicos, e descreve *como* em vez de *o quê*.

O Testy obriga o QA a escrever cenários que descrevem **comportamento**, não **procedimento**:

> **Dado que** um utilizador registado  
> **Quando** faz login com credenciais válidas  
> **Então** é redirecionado para o dashboard  

Um Dado que, um Quando, um Então. Se o QA não conseguir descrever o cenário em três frases concisas, provavelmente se trata de mais de um cenário. Isto mantém os testes legíveis tanto para desenvolvedores quanto para pessoas de negócio, que é o propósito do Gherkin — uma linguagem comum, não um roteiro de cliques.

**SQLite em produção.** Menos um serviço para gerir. Funciona bem para equipes pequenas a médias. O Rails 8 suporta-o bem com Solid Cache, Solid Queue e Solid Cable.

**Autenticação simples.** O Testy usa o `has_secure_password` nativo do Rails com login por username/password. No primeiro acesso, o usuário será redirecionado para criar o utilizador admin — sem seeds nem scripts de setup.

**Sem build step de JavaScript.** Usa import maps para JS e a gem `tailwindcss-rails` para CSS. `bin/dev` executa tanto o servidor como o watcher do Tailwind.

**Filtros server-side.** A filtragem acontece via query params e scopes SQL — sem estado client-side, sem complexidade JavaScript, e cada vista filtrada é um URL partilhável.

## Deployment

### Docker Compose (recomendado)

```bash
git clone https://github.com/VictorBitancourt/testy.git
cd testy
docker compose up -d
```

Abre [http://localhost:3000](http://localhost:3000). No primeiro acesso, será solicitada a criação do utilizador administrador.

Os dados são persistidos num volume Docker (`testy_storage`). Um `SECRET_KEY_BASE` é gerado automaticamente no primeiro uso.

Para ativar a geração de cenários com IA, passe a chave da API Gemini:

```bash
GEMINI_API_KEY=your_key_here docker compose up -d
```

### Docker Run

```bash
docker run -d \
  -p 3000:80 \
  -e SOLID_QUEUE_IN_PUMA=true \
  -e FORCE_SSL=false \
  -e ASSUME_SSL=false \
  -e GEMINI_API_KEY=your_key_here \
  -v testy_storage:/rails/storage \
  testy:latest
```

## Reset de Password

Se um utilizador esquecer a senha, um admin com acesso ao servidor pode fazer reset:

```bash
bin/rails password:reset
```

A task vai pedir o username e uma nova senha.

Para deployments Docker:

```bash
docker exec -it <container_name> bin/rails password:reset
```

## Contribuir

1. Faça fork do repositório
2. Crie a tua branch de feature (`git checkout -b feature/my-feature`)
3. Faça as suas alterações e garanta que os testes passam (`bin/rails test`)
4. Faça commit das alterações (`git commit -m 'Add my feature'`)
5. Faça push para a branch (`git push origin feature/my-feature`)
6. Abra um Pull Request

## Licença

Este projeto é open source sob a [Licença MIT](LICENSE).
