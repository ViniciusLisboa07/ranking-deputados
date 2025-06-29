FROM ruby:3.2.2

# Instalar dependências do sistema
RUN apt-get update -qq && \
    apt-get install -y postgresql-client nodejs npm build-essential git libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Configurar bundler
ENV BUNDLE_PATH="/usr/local/bundle"
ENV BUNDLE_BIN="/usr/local/bundle/bin"
ENV PATH="${BUNDLE_BIN}:${PATH}"

# Diretório de trabalho
WORKDIR /rails

# Copiar Gemfile e instalar gems
COPY Gemfile Gemfile.lock ./

# Instalar bundler e gems
RUN gem install bundler && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle install


# Criar diretórios necessários
RUN mkdir -p tmp/pids log

# Expor porta
EXPOSE 3000

# Comando padrão
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"] 