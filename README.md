# Ranking dos Gastos dos Deputados

Sistema web para análise dos gastos dos deputados federais, desenvolvido com Rails API + React SPA.

## Arquitetura

### Backend (Rails API)
- **Framework**: Ruby on Rails 7 (modo API)
- **Banco de dados**: PostgreSQL
- **Cache/Jobs**: Redis + Sidekiq
- **Processamento**: Jobs em background para importação de CSV

### Frontend (React SPA)
- **Framework**: React 18 + TypeScript
- **Estilização**: Tailwind CSS
- **Gráficos**: Recharts
- **Componentes**: Heroicons + Headless UI

### Infraestrutura
- **Containerização**: Docker + Docker Compose
- **Portas**: Backend (3000), Frontend (3001), PostgreSQL (5432), Redis (6379)

## Funcionalidades

### Dashboard
- Estatísticas gerais (total de deputados, gastos, médias)
- Rankings de maiores gastadores
- Distribuição de gastos por UF e partido
- Gastos por categoria de despesa
- Gráficos interativos (barras, pizza, área)

### Importação de Dados
- Upload de arquivos CSV dos gastos parlamentares
- Processamento em background via Sidekiq
- Validação de formato e integridade
- Status de processamento em tempo real
- Suporte a arquivos de até 80MB

### API REST
- **GET** `/api/deputados` - Lista deputados com paginação
- **GET** `/api/deputados/:id` - Detalhes de um deputado
- **GET** `/api/deputados/statistics` - Estatísticas consolidadas
- **GET** `/api/despesas` - Lista despesas com filtros
- **GET** `/api/rankings` - Rankings diversos
- **POST** `/api/uploads` - Upload de CSV
- **GET** `/api/uploads/:id/status` - Status do processamento

## Modelo de Dados

### Deputado
- `deputado_id` (único)
- `nome`, `uf`, `partido`
- Relacionamento: `has_many :despesas`

### Despesa
- `valor_liquido`, `descricao`, `fornecedor`
- `data_emissao`, `mes`, `ano`
- Relacionamento: `belongs_to :deputado`

## Setup e Execução

### Pré-requisitos
- Docker e Docker Compose
- Arquivo CSV dos gastos parlamentares

### Iniciando a aplicação
```bash
# Clonar o repositório
git clone <repo-url>
cd ranking-deputados

# Iniciar todos os serviços
docker-compose up --build

# Acessos:
# Frontend: http://localhost:3001
# Backend API: http://localhost:3000
# PostgreSQL: localhost:5432
# Redis: localhost:6379
```

### Primeira configuração
```bash
# Criar e migrar banco de dados
docker-compose exec backend rails db:create db:migrate

# (Opcional) Popular com dados de exemplo
docker-compose exec backend rails db:seed
```

### Importação de dados
1. Acesse http://localhost:3001
2. Navegue para "Upload CSV"
3. Selecione o arquivo CSV dos gastos
4. Acompanhe o processamento em tempo real

### Formato do CSV esperado
- Separador: ponto e vírgula (`;`)
- Codificação: UTF-8
- Colunas obrigatórias:
  - `nuDeputadoId`
  - `txNomeParlamentar`
  - `sgUF`
  - `sgPartido`
  - `txtDescricao`
  - `vlrLiquido`
  - `datEmissao`

## Desenvolvimento

### Comandos úteis
```bash
# Logs dos serviços
docker-compose logs -f [backend|frontend|sidekiq]

# Acesso ao console Rails
docker-compose exec backend rails console

# Executar testes
docker-compose exec backend rails test
docker-compose exec frontend npm test

# Rebuild completo
docker-compose down
docker-compose up --build
```

### Estrutura do projeto
```
├── backend/               # Rails API
│   ├── app/
│   │   ├── controllers/   # Endpoints da API
│   │   ├── models/        # Deputado, Despesa
│   │   ├── services/      # Lógica de negócio
│   │   └── jobs/          # Jobs Sidekiq
│   └── config/            # Configurações Rails
├── frontend/              # React SPA
│   ├── src/
│   │   ├── components/    # Dashboard, Navigation, FileUpload
│   │   └── services/      # Cliente da API
└── docker-compose.yml    # Orquestração dos serviços
```