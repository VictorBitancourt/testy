<p align="center">
  <img src="app/assets/images/testy-logo.svg" width="200" alt="Testy Logo" />
</p>

# Testy

An opinionated test management tool for QA teams that value simplicity over configuration. Create test plans, write scenarios in Given/When/Then format, attach evidence, and export PDF reports — nothing more, nothing less.

Most test management tools drown you in fields, workflows, and integrations before you can write your first test case. Testy takes the opposite approach: it gives you exactly what you need and stays out of the way.

## Features

- **Test Plans** — group related scenarios under a named plan assigned to a QA
- **Scenarios (Given/When/Then)** — structured BDD format without the overhead of a full framework
- **Evidence Attachments** — upload screenshots and files directly on each scenario
- **One-Click Approve/Reject** — mark scenarios as approved or failed inline
- **Derived Status** — plan status is computed automatically from its scenarios (no manual updates)
- **Filters** — filter plans by status (Approved, Failed, In Progress, Not Started) and date range
- **PDF Reports** — export a formatted report with summary, scenarios, and evidence

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Rails 8.1 |
| Ruby | 3.4.7 |
| Database | SQLite |
| Frontend | Tailwind CSS v4, Hotwire (Turbo + Stimulus) |
| File Storage | Active Storage (local disk) |
| PDF | wicked_pdf + wkhtmltopdf |
| Deploy | Kamal-ready (Docker + Thruster) |

## Getting Started

**Prerequisites:** Ruby 3.4+, Node.js (for Tailwind CSS build)

```bash
# Clone the repository
git clone https://github.com/VictorBitancourt/testy.git
cd testy

# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Start the server
bin/dev
```

Open [http://localhost:3000](http://localhost:3000).

## Running Tests

```bash
bin/rails test
```

53 tests, 174 assertions — covering models, controllers, and filter behavior.

## How It Works

### Data Model

```
TestPlan (name, qa_name)
  |
  +-- TestScenario (title, given, when, then, status)
        |
        +-- Evidence Files (Active Storage)
```

### Derived Status

Plan status is not a stored field. It's computed from the scenarios:

| Status | Rule |
|--------|------|
| Not Started | Plan has zero scenarios |
| Approved | All scenarios are `approved` |
| Failed | At least one scenario is `failed` |
| In Progress | Has scenarios, none failed, but not all approved |

### PDF Export

Each plan has an "Export PDF Report" button that generates a formatted document with:
- Plan summary (total scenarios, approved count, QA name)
- Each scenario with Given/When/Then steps and status
- Attached evidence images

## Design Decisions

**No AND between Given, When, and Then.** This is intentional. Each step is a single text field — there's no way to chain multiple clauses with AND.

When tools allow AND, scenarios inevitably turn into click-by-click scripts:

> **Given** the user is on the login page
> **And** the user has a valid account
> **And** the browser is Chrome
> **When** the user clicks the email field
> **And** types "user@email.com"
> **And** clicks the password field
> **And** types "123456"
> **And** clicks the submit button
> **Then** the page redirects to /dashboard
> **And** the welcome message is visible
> **And** the session cookie is set

This is not a test scenario — it's a manual test script. It's fragile, unreadable for non-technical stakeholders, and describes *how* instead of *what*.

Testy forces you to write scenarios that describe **behavior**, not **procedure**:

> **Given** a registered user
> **When** they log in with valid credentials
> **Then** they are redirected to the dashboard

One Given, one When, one Then. If you can't describe the scenario in three concise sentences, it's probably more than one scenario. This keeps tests readable by both developers and business people, which is the whole point of Gherkin — a shared language, not a step recorder.

**SQLite in production.** One fewer service to manage. Works great for small-to-medium teams. Rails 8 supports it well with Solid Cache, Solid Queue, and Solid Cable.

**No authentication.** Testy is designed for internal use behind a VPN or within a team's private network. Adding auth is straightforward with Rails' built-in `has_secure_password` if needed.

**No JavaScript build step.** Uses import maps for JS and the `tailwindcss-rails` gem for CSS. `bin/dev` runs both the server and the Tailwind watcher.

**Server-side filters.** Filtering happens via query params and SQL scopes — no client-side state, no JavaScript complexity, and every filtered view is a shareable URL.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Make your changes and ensure tests pass (`bin/rails test`)
4. Commit your changes (`git commit -m 'Add my feature'`)
5. Push to the branch (`git push origin feature/my-feature`)
6. Open a Pull Request

## License

This project is open source under the [MIT License](LICENSE).
