# Rubyのバージョンを指定（READMEに合わせて3.3系）
FROM ruby:3.3

# OSレベルで必要なパッケージ
#  build-essential : Gemのコンパイルに必要
#  libpq-dev       : PostgreSQLに接続するpg Gemに必要
#  libyaml-dev     : psych Gemに必要
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev git curl && \
    rm -rf /var/lib/apt/lists/*

# コンテナ内の作業ディレクトリ
WORKDIR /app

# 先にGemfileだけコピーしてbundle install
# （コードを変更してもGemのインストールがやり直しにならず、ビルドが速くなる）
COPY Gemfile Gemfile.lock ./
RUN bundle install

# アプリ本体をコピー
COPY . .

EXPOSE 3000

# デフォルトで実行するコマンド（compose.ymlで上書きします）
CMD ["bin/rails", "server", "-b", "0.0.0.0"]