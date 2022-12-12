# add swap

fallocate -l 8G /swapfile
mkswap /swapfile
swapon /swapfile

# add user

adduser pacha
usermod -aG sudo pacha

# base

apt update
apt upgrade
apt install certbot python3-certbot-nginx gdebi-core fail2ban

printf '[sshd]\nenabled = true\nport = 22\nfilter = sshd\nlogpath = /var/log/auth.log\nmaxretry = 5' | tee -a /etc/fail2ban/jail.local
printf '\n\n[http-auth]\nenabled = true\nport = http,https\nlogpath = /var/log/auth.log\nmaxretry = 5' | tee -a /etc/fail2ban/jail.local
systemctl restart fail2ban

ufw enable
ufw allow 'Nginx Full'
ufw delete allow 'Nginx HTTP'
ufw allow 'OpenSSH'

certbot --nginx -d tradestatistics.io

apt install --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
apt install --no-install-recommends r-base
apt install r-base-dev libopenblas-dev

add-apt-repository ppa:c2d4u.team/c2d4u4.0+
apt install r-cran-tidyverse r-cran-data.table r-cran-shiny r-cran-fixest r-cran-highcharter r-cran-devtools r-cran-rio r-cran-plumber
apt install r-cran-rpostgres r-cran-pool

# shiny server

wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.16.958-amd64.deb
gdebi --n shiny-server-1.5.16.958-amd64.deb
rm shiny-server-1.5.16.958-amd64.deb

ufw allow 3838

# additional packages

# I installed this previously just to solve the dependencies
# I need the version from GH to use Arrow
apt remove r-cran-plumber

apt install libcurl4-openssl-dev libssl-dev

R --vanilla << EOF
options(repos = c(REPO_NAME = "https://packagemanager.rstudio.com/all/latest"))
Sys.setenv("NOT_CRAN" = TRUE)
install.packages("plumber")
remotes::install_github("tradestatistics/shinydashboard")
remotes::install_github("tradestatistics/tradestatistics")
q()
EOF

# postgresql 14
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

apt update
apt upgrade

apt install postgresql-14

sudo -u postgres createuser --interactive
sudo -u postgres psql
alter user x with encrypted password 'y';
\q

systemctl stop postgresql

nano /etc/postgresql/14/main/postgresql.conf

# search listen_addresses and add
# listen_addresses = '*'
# below

nano /etc/postgresql/14/main/pg_hba.conf 

# paste at the end
# host    all             all              0.0.0.0/0                       md5
# host    all             all              ::/0                            md5

ufw allow 5432
systemctl start postgresql

swapoff /swapfile
rm -rf /swapfile
