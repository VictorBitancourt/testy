<p align="center">
  <img src="app/assets/images/testy-logo.png" width="200" alt="Testy Logo" />
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>Português (BR)</strong>
</p>

# Testy

Uma ferramenta de gestão de testes opinativa para equipas de QA que valorizam simplicidade acima de configuração. Crie planos de teste, escreva cenários no formato Given/When/Then, gere cenários com IA, anexe evidências e exporte relatórios PDF — nada mais, nada menos.

A maioria das ferramentas de gestão de testes afoga-te em campos, workflows e integrações antes de conseguires escrever o primeiro caso de teste. O Testy segue a abordagem oposta: dá-te exatamente o que precisas e sai do caminho.

## Funcionalidades

- **Planos de Teste** — agrupa cenários relacionados num plano nomeado, atribuído a um QA
- **Tags** — categoriza planos com tags (ex: "login", "sprint-23", "regressão") e pesquisa por elas
- **Cenários (Given/When/Then)** — formato Gherkin estruturado sem a sobrecarga de um framework completo
- **Geração de Cenários com IA** — descreve uma funcionalidade em texto livre e deixa o Gemini gerar 5-15 cenários de teste automaticamente, cobrindo caminhos felizes, casos extremos, valores limite e particionamento de equivalência
- **Drag & Drop para Reordenar** — reordena cenários arrastando-os, com animações FLIP suaves e zona de drop visual; a ordem é persistida e refletida nos relatórios
- **Anexos de Evidências** — faz upload de screenshots e ficheiros diretamente em cada cenário ou bug
- **Aprovar/Reprovar com Um Clique** — marca cenários como aprovados ou falhados inline
- **Status Derivado** — o status do plano é calculado automaticamente a partir dos seus cenários (sem atualizações manuais)
- **Registo de Bugs** — reporta bugs com título, descrição, passos para reproduzir, resultado obtido vs esperado e anexos de evidência; classifica por funcionalidade e causa raiz; marca como aberto ou resolvido
- **Bug ↔ Cenário** — associa cenários falhados a bugs; um cenário não pode ser aprovado enquanto tiver um bug vinculado
- **Dashboard de Causas Raiz** — vista agregada de bugs agrupados por tag de causa e tag de funcionalidade, com gráficos de barras para análise rápida
- **Pesquisa e Filtros** — pesquisa planos por nome, QA ou tag; pesquisa bugs por ID, título ou descrição; filtra por status, tags e intervalo de datas
- **Paginação** — listagens de planos e bugs paginadas para grandes volumes de dados
- **Relatórios PDF** — exporta relatórios formatados para planos de teste e bugs individuais, com índice (âncoras clicáveis), resumo, cenários e evidências
- **Atalhos de Teclado** — navega rapidamente com atalhos de tecla única (N para novo, B para voltar, R para causas raiz, P para planos)
- **Autenticação e Perfis** — login com username/password com perfis de administrador e utilizador regular; admins gerem todos os planos e bugs, utilizadores gerem os seus
- **Bilingue (EN / PT-BR)** — interface completa em inglês e português brasileiro; alterna idiomas com um clique, preferência guardada em cookie

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
- Cada cenário com passos Given/When/Then e status
- Imagens de evidência anexadas

Bugs também têm relatórios PDF individuais com descrição, passos para reproduzir, resultado obtido vs esperado e evidências.

## Decisões de Design

**Sem AND entre Given, When e Then.** Isto é intencional. Cada passo é um campo de texto único — não há forma de encadear múltiplas cláusulas com AND.

Quando ferramentas permitem AND, os cenários inevitavelmente transformam-se em scripts clique-a-clique:

> **Given** o utilizador está na página de login
> **And** o utilizador tem uma conta válida
> **And** o browser é Chrome
> **When** o utilizador clica no campo de email
> **And** escreve "user@email.com"
> **And** clica no campo de password
> **And** escreve "123456"
> **And** clica no botão de submit
> **Then** a página redireciona para /dashboard
> **And** a mensagem de boas-vindas está visível
> **And** o cookie de sessão está definido

Isto não é um cenário de teste — é um script de teste manual. É frágil, ilegível para stakeholders não-técnicos, e descreve *como* em vez de *o quê*.

O Testy obriga-te a escrever cenários que descrevem **comportamento**, não **procedimento**:

> **Given** um utilizador registado
> **When** faz login com credenciais válidas
> **Then** é redirecionado para o dashboard

Um Given, um When, um Then. Se não consegues descrever o cenário em três frases concisas, provavelmente são mais do que um cenário. Isto mantém os testes legíveis tanto por developers como por pessoas de negócio, que é o propósito do Gherkin — uma linguagem partilhada, não um gravador de passos.

**SQLite em produção.** Menos um serviço para gerir. Funciona bem para equipas pequenas a médias. O Rails 8 suporta-o bem com Solid Cache, Solid Queue e Solid Cable.

**Autenticação simples.** O Testy usa o `has_secure_password` nativo do Rails com login por username/password. No primeiro acesso, serás redirecionado para criar o utilizador admin — sem seeds nem scripts de setup.

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

Os dados são persistidos num volume Docker (`testy_storage`). Um `SECRET_KEY_BASE` é gerado automaticamente no primeiro arranque.

Para ativar a geração de cenários com IA, descomenta `GEMINI_API_KEY` no `docker-compose.yml` e define a tua chave antes de iniciar.

### Docker Run

```bash
docker run -d \
  -p 3000:80 \
  -e SOLID_QUEUE_IN_PUMA=true \
  -e GEMINI_API_KEY=your_key_here \
  -v testy_storage:/rails/storage \
  ghcr.io/victorbitancourt/testy:latest
```

## Reset de Password

Se um utilizador esquecer a password, um admin com acesso ao servidor pode fazer reset:

```bash
bin/rails password:reset
```

A task vai pedir o username e uma nova password (input é escondido).

Para deployments Docker:

```bash
docker exec -it <container_name> bin/rails password:reset
```

## Contribuir

1. Faz fork do repositório
2. Cria a tua branch de feature (`git checkout -b feature/my-feature`)
3. Faz as tuas alterações e garante que os testes passam (`bin/rails test`)
4. Faz commit das alterações (`git commit -m 'Add my feature'`)
5. Faz push para a branch (`git push origin feature/my-feature`)
6. Abre um Pull Request

## Licença

Este projeto é open source sob a [Licença MIT](LICENSE).
