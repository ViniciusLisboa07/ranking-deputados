# Ranking dos Gastos dos Deputados

Este projeto é uma aplicação web para análise dos gastos dos deputados federais, desenvolvida com Rails API + React SPA.

## 🏗️ Arquitetura

- **Backend**: Rails 7 API com PostgreSQL
- **Frontend**: React 18 com TypeScript
- **Cache**: Redis
- **Containerização**: Docker + Docker Compose

## 🚀 Como executar

### Pré-requisitos

- Docker
- Docker Compose

### Configuração inicial

1. Clone o repositório:
```bash
git clone <url-do-repositorio>
cd ranking-deputados
```

2. Crie os projetos Rails e React:

```bash
# Criar o projeto Rails API
cd backend
rails new . --api --database=postgresql --skip-git
cd ..

# Criar o projeto React
cd frontend
npx create-react-app . --template typescript
cd ..
```

3. Construa e execute os containers:

```bash
# Construir as imagens
docker-compose build

# Executar os serviços
docker-compose up
```

4. Configure o banco de dados:

```bash
# Executar migrations
docker-compose exec backend rails db:create db:migrate

# (Opcional) Executar seeds
docker-compose exec backend rails db:seed
```

## 📚 Estrutura do Projeto

```
ranking-deputados/
├── backend/                 # Rails API
│   ├── app/
│   │   ├── controllers/     # Controllers da API
│   │   ├── models/         # Models (Deputado, Despesa)
│   │   ├── services/       # Lógica de negócio
│   │   ├── serializers/    # Serialização JSON
│   │   └── uploaders/      # Upload de arquivos
│   ├── db/                 # Migrations e seeds
│   ├── spec/              # Testes RSpec
│   └── Dockerfile
├── frontend/              # React SPA
│   ├── src/
│   │   ├── components/    # Componentes React
│   │   ├── pages/         # Páginas da aplicação
│   │   ├── services/      # Chamadas para API
│   │   ├── hooks/         # Custom hooks
│   │   └── utils/         # Utilitários
│   └── Dockerfile
├── docker-compose.yml     # Configuração Docker
└── README.md
```

## 🔧 Endpoints da API

### Deputados
- `GET /api/v1/deputados` - Lista deputados
- `GET /api/v1/deputados/:id` - Detalhes do deputado
- `GET /api/v1/deputados/:id/despesas` - Despesas do deputado
- `GET /api/v1/deputados/:id/maior_despesa` - Maior despesa

### Dados
- `POST /api/v1/upload_csv` - Upload do arquivo CSV
- `GET /api/v1/statistics` - Estatísticas gerais
- `GET /api/v1/ranking` - Ranking de gastos

## 🧪 Testes

### Backend
```bash
docker-compose exec backend rspec
```

### Frontend
```bash
docker-compose exec frontend npm test
```

## 📊 Funcionalidades

- [x] Upload de arquivo CSV
- [x] Listagem de deputados por estado
- [x] Ranking de gastos
- [x] Detalhes das despesas
- [x] Gráficos interativos
- [x] API RESTful
- [x] Testes automatizados

## 🚀 Deploy

### Heroku
1. Instale o Heroku CLI
2. Configure as variáveis de ambiente
3. Execute o deploy

### AWS/Docker
1. Configure o registry de imagens
2. Faça o build das imagens
3. Execute o deploy

## 📈 Próximos Passos

1. Implementar cache com Redis
2. Adicionar autenticação/autorização
3. Melhorar performance das queries
4. Adicionar mais visualizações
5. Implementar notificações

---

Desenvolvido como parte do desafio técnico para análise de gastos dos deputados federais. 