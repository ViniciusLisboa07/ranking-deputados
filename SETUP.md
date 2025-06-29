# 🚀 Setup do Projeto - Ranking Deputados

Este guia contém as instruções detalhadas para configurar o projeto localmente.

## 📋 Pré-requisitos

- Docker (versão 20.10+)
- Docker Compose (versão 2.0+)
- Git

## 🔧 Configuração Passo a Passo

### 1. Clone e configuração inicial

```bash
# Clone o repositório
git clone <url-do-repositorio>
cd ranking-deputados

# Copie o arquivo de exemplo
cp .env.example .env
```

### 2. Criação dos projetos Rails e React

#### Backend (Rails API)

```bash
cd backend

# Criar projeto Rails API
rails new . --api --database=postgresql --skip-git --force

# Adicionar gems específicas ao Gemfile (já criado)
# O Gemfile já contém todas as gems necessárias

# Instalar gems
bundle install

cd ..
```

#### Frontend (React + TypeScript)

```bash
cd frontend

# Criar projeto React com TypeScript
npx create-react-app . --template typescript --yes

# O package.json já foi criado com as dependências necessárias
# Instalar dependências
npm install

cd ..
```

### 3. Configuração do Docker

```bash
# Construir as imagens Docker
docker-compose build

# Iniciar os serviços
docker-compose up -d
```

### 4. Configuração do Banco de Dados

```bash
# Criar banco de dados
docker-compose exec backend rails db:create

# Executar migrations (depois de criá-las)
docker-compose exec backend rails db:migrate

# (Opcional) Executar seeds
docker-compose exec backend rails db:seed
```

## 🏗️ Próximos Passos de Desenvolvimento

### 1. Configurar Rails API

#### Models a criar:
```bash
# Deputado
docker-compose exec backend rails generate model Deputado \
  nome:string cpf:string sg_uf:string ide_cadastro:integer \
  nome_parlamentar:string

# Despesa
docker-compose exec backend rails generate model Despesa \
  deputado:references dat_emissao:date txt_cnpj_cpf:string \
  txt_fornecedor:string txt_descricao:string vlr_documento:decimal \
  vlr_glosa:decimal vlr_liquido:decimal url_documento:string
```

#### Controllers a criar:
```bash
# API Controllers
docker-compose exec backend rails generate controller Api::V1::Deputados
docker-compose exec backend rails generate controller Api::V1::Despesas
docker-compose exec backend rails generate controller Api::V1::Uploads
docker-compose exec backend rails generate controller Api::V1::Statistics
```

#### Services a criar:
- `CsvImportService` - Processar upload do CSV
- `RankingService` - Calcular rankings
- `StatisticsService` - Dados agregados

### 2. Configurar React Frontend

#### Estrutura de pastas a criar:
```
frontend/src/
├── components/
│   ├── common/         # Componentes reutilizáveis
│   ├── charts/         # Componentes de gráficos
│   └── layout/         # Header, Footer, etc.
├── pages/
│   ├── Dashboard/      # Página principal
│   ├── Deputados/      # Listagem e detalhes
│   └── Upload/         # Upload CSV
├── services/
│   └── api.ts          # Configuração Axios
├── hooks/
│   └── useApi.ts       # Custom hooks para API
├── types/
│   └── index.ts        # TypeScript interfaces
└── utils/
    └── formatters.ts   # Utilitários
```

## 🧪 Executar Testes

### Backend (RSpec)
```bash
# Configurar ambiente de teste
docker-compose exec backend rails db:test:prepare

# Executar testes
docker-compose exec backend rspec
```

### Frontend (Jest)
```bash
# Executar testes
docker-compose exec frontend npm test
```

## 📊 Dados de Exemplo

1. Baixe o arquivo CSV de 2024 do portal da transparência
2. Use o endpoint `POST /api/v1/upload_csv` para fazer upload
3. Os dados serão processados e salvos no banco

## 🔍 Verificar se está funcionando

### Backend
```bash
# Verificar se API está respondendo
curl http://localhost:3000/api/v1/deputados

# Logs do Rails
docker-compose logs backend
```

### Frontend
```bash
# Acessar no navegador
http://localhost:3001

# Logs do React
docker-compose logs frontend
```

## 🚨 Troubleshooting

### Problemas com Docker
```bash
# Recriar containers
docker-compose down
docker-compose up --build

# Limpar cache Docker
docker system prune -a
```

### Problemas com Gems
```bash
# Reinstalar gems
docker-compose exec backend bundle install
```

### Problemas com NPM
```bash
# Limpar cache e reinstalar
docker-compose exec frontend npm cache clean --force
docker-compose exec frontend npm install
```

## 📈 Performance Tips

1. **Database**: Adicionar índices nas consultas frequentes
2. **Cache**: Implementar cache com Redis
3. **API**: Paginação nas listagens
4. **Frontend**: Lazy loading e virtualization

---

📝 **Nota**: Este setup cria uma base sólida para o desenvolvimento. Ajuste conforme necessário durante o desenvolvimento. 