## AWSの設定
### EC2インスタンスを作成する。
### Route53の設定
## サーバーの準備（AmazonLinux編）
### 各種パッケージのインストール

`$ yum update`

`$ yum -y install gcc gcc-c++ autoconf git`

`$ yum -y install openssl-devel zlib-devel readline-devel curl-devel gettext-devel`

`$ yum -y install httpd-devel sqlite-devel`

`$ yum install libxml2-devel`

`$ yum install libxslt-devel`

## libyamlのインストール

`$ cd /usr/local/src`

`$ wget http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz`

`$ tar xzf yaml-0.1.4.tar.gz`

`$ cd yaml-0.1.4`

`$ ./configure`

`$ make && make install`

ここまでrootユーザー
## Ruby 1.9.3のインストール
ここからsudoユーザー

`% mkdir ~/src`

`% cd ~/src`

`% wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p392.tar.gz`

`% tar xzf ruby-1.9.3-p392.tar.gz`

`% cd ruby-1.9.3-p392`

`% ./configure`

`% make`

`% sudo make install`

# SSH公開鍵の設置

`% scp -i k2works.pem ~/.ssh/id_rsa.pub ec2-user@demo.k2-works.net:~`

`$ cat id_rsa.pub >> .ssh/authorized_keys`

`$ chmod 600 .ssh/authorized_keys`

`$ rm id_rsa.pub`

## Railsアプリケーションのセットアップ
### railsユーザーの作成
`$ sudo useradd -m -d /var/rails rails`

`$ sudo passwd rails`

`$ sudo chmod 750 /var/rails`

### Apache実行ユーザーをグループに追加

`$ sudo gpasswd -a apache rails`

### Bundlerのインストール

`$ sudo gem install bundler --no-ri --no-rdoc`

gemが無いとエラーが出た場合は sudo /usr/local/bin/gem install bundler --no-ri --no-rdoc

## ApacheとPhusion Passengerのセットアップ
### Phusion Passengerのインストール

`$ sudo gem install passenger --no-ri --no-rdoc`

`$ sudo passenger-install-apache2-module`

### Apacheの準備

`% sudo -s`

`$ cd /etc/httpd`

`$ echo "Include /etc/httpd/sites-enabled/" >> conf/httpd.conf`

`$ mkdir sites-available`

`$ mkdir sites-enabled`

`$ rm conf.d/welcome.conf`

エディタで /etc/httpd/conf/httpd.conf を開き

/#ServerName www.example.com:80
という箇所のコメント記号（#）を取り除いてください。

また、

/#NameVirtualHost *:80

のコメント記号（#）を取り除いてください。

Phusion PassengerをApacheに組み込む

新規ファイル /etc/httpd/conf.d/passenger.conf に次の内容を書き込みます。

    LoadModule passenger_module /usr/local/lib/ruby/gems/1.9.1/gems/passenger-4.0.2/libout/apache2/mod_passenger.so
    PassengerRoot /usr/local/lib/ruby/gems/1.9.1/gems/passenger-4.0.2
    PassengerDefaultRuby /usr/local/bin/ruby

バーチャルホストの追加

新規ファイル /etc/httpd/sites-available/default に次の内容を書き込みます。

    <VirtualHost *:80>
      DocumentRoot /var/www/html
       <Directory /var/www/html>
         AllowOverride all
         Options None
         Order Deny,Allow
         Deny from All
       </Directory>
    </VirtualHost>

`$ ln -s /etc/httpd/sites-available/default /etc/httpd/sites-enabled/000-default`

新規ファイル /etc/httpd/sites-available/railsdemo に次の内容を書き込みます。

    <VirtualHost *:80>
      ServerName depot.demo.k2-works.net
        DocumentRoot /var/rails/railsdemo/current/public
        RackEnv production
       <Directory /var/rails/railsdemo/current/public>
          AllowOverride all
          Options -MultiViews
       </Directory>
    </VirtualHost>

`$ ln -s /etc/httpd/sites-available/railsdemo /etc/httpd/sites-enabled/001-railsdemo`

### Apacheの起動

`$ service httpd start`

## データベースとの接続（MySQL編）
### MySQLサーバのインストール

`$ sudo yum install -y mysql-server mysql-devel `

`$ sudo mysql_install_db`

`$ sudo chown -R mysql:mysql /var/lib/mysql`

### MySQLサーバの起動および自動起動設定

`$ sudo service mysqld start`

`$ sudo chkconfig mysqld on`

`$ mysql -u root`

 `SET PASSWORD FOR 'root'@'localhost' = PASSWORD('hogehoge');`

railsdemo_productionデータベースを作り、railsdemoユーザーに全権を与えます。

`CREATE DATABASE railsdemo_production DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;`

`GRANT ALL ON railsdemo_production.* TO 'railsdemo'@'localhost';`

`SET PASSWORD FOR 'railsdemo'@'localhost' = PASSWORD('hogehoge');`

MySQLモニターを抜けます。

`quit`

## GitHubの設定
railsユーザーでリモートマシンにログインし、次のコマンドを実行します。

`$ ssh-keygen`

生成した公開鍵をGitHubに登録する。

`$ git ls-remote git@github.com:k2works/railsdemo.git`

## Capistranoによるデプロイ
### SSH公開鍵の設置

sudo権限を持つ一般ユーザーでリモートマシンにログインします。そして、自分のauthorized_keysを/var/rails/.sshディレクトリにコピーします。以下のコマンドを順に実行してください。

`$ sudo cp /home/ec2-user/.ssh/authorized_keys /var/rails/.ssh/`

`$ sudo chown -R rails:rails /var/rails/.ssh`

### Capistranoの準備

ローカルマシンのrailsdemoのルートディレクトリに移動して、次のコマンドを実行します。

`% gem install capistrano`

`% capify .`

エディタで config/deploy.rb を次のように修正します。

    require 'bundler/capistrano'
    load 'deploy/assets'

    set :application, "railsdemo"
    set :deploy_to, "/var/rails/railsdemo"
    set :user, "rails"
    set :use_sudo, false

    set :repository, "git@github.com:k2works/railsdemo.git"
    set :branch, "master"
    set :scm, :git
    set :deploy_via, :remote_cache

    set :normalize_asset_timestamps, false
    set :keep_releases, 3

    role :web, "demo.k2-works.net"
    role :app, "demo.k2-works.net"
    role :db, "demo.k2-works.net", :primary => true

    after "deploy:update", :roles => :app do
    run "cp #{shared_path}/config/database.yml #{release_path}/config/"
    end

    after "deploy:update", "deploy:cleanup"

    namespace :deploy do
    desc "Restarts your application."
     task :restart, :roles => :app do
      run "touch #{current_path}/tmp/restart.txt"
     end
    end

MySQLを利用している場合は、新規ファイル /var/rails/railsdemo/shared/config/database.yml を次の内容で作成します。

    production:
    adapter: mysql2
    database: railsdemo_production
    username: railsdemo
    password: hogehoge
    host: 127.0.0.1
    encoding: utf8

`% cap deploy:setup`

`% cap deploy`

デプロイ完了後にデータを登録する

`$ RAILS_ENV=production rake db:schema:load`

`$ RAILS_ENV=production rake db:seed`
