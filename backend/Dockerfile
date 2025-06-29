FROM ruby:3.2.2

# Instalar dependências do sistema
RUN apt-get update -qq && \
    apt-get install -y postgresql-client nodejs npm build-essential git libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Diretório de trabalho
WORKDIR /rails

# Copiar Gemfile e instalar gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copiar código da aplicação
COPY . .

# Expor porta
EXPOSE 3000

# Comando padrão
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"] 