#!/usr/bin/env bash
set +x
set -euo pipefail
# Install full environment
# MASTER branch

# use curl
# bash <(curl -sL https://raw.githubusercontent.com/EduardRe/YogSottot/master/install_full_environment.sh)

# use wget
# bash <(wget -qO- https://raw.githubusercontent.com/EduardRe/YogSottot/master/install_full_environment.sh)

cat > /root/temp_install_full_environment.sh <<\END
#!/usr/bin/env bash
set +x
set -euo pipefail

generate_password() {
    local length=$1
    local specials='!@#$%^&*()-_=+[]|;:,.<>?/~'
    local all_chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789${specials}"

    local password=""
    for i in $(seq 1 $length); do
        local char=${all_chars:RANDOM % ${#all_chars}:1}
        password+=$char
    done

    echo $password
}

BRANCH="feature/php-fpm"
SETUP_BITRIX_DEBIAN_URL="https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/$BRANCH/repositories/bitrix-gt/bitrix24_gt.sh"
REPO_URL="https://github.com/YogSottot/DebianLikeBitrixVM"

DB_NAME="bitrix"
DB_USER="bitrix"

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

# Function to compare versions
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Get OS and version information
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
fi

# Check if it's Ubuntu 22.04 or less
if [[ "$OS" == "Ubuntu" && $(echo -e "$VER\n22.04" | sort -V | head -n1) == "$VER" ]]; then
    apt update -y
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/nginx
fi
apt update -y
apt upgrade -y
apt install -y perl wget curl ansible git ssl-cert cron locales locales-all poppler-utils catdoc nginx-light libnginx-mod-http-brotli-filter libnginx-mod-http-brotli-static libnginx-mod-http-headers-more-filter unattended-upgrades software-properties-common

# Set locales
locale-gen en_US.UTF-8
locale-gen en_GB.UTF-8
locale-gen en_DK.UTF-8
locale-gen ru_RU.UTF-8
locale-gen C.UTF-8

cat > /etc/default/locale <<CONFIG_LOCALE
LANG=en_GB.UTF-8
LANGUAGE=
LC_CTYPE="en_GB.UTF-8"
LC_NUMERIC="ru_RU.UTF-8"
LC_TIME="en_DK.UTF-8"
LC_COLLATE="ru_RU.UTF-8"
LC_MONETARY="C.UTF-8"
LC_MESSAGES="en_GB.UTF-8"
LC_PAPER="ru_RU.UTF-8"
LC_NAME="ru_RU.UTF-8"
LC_ADDRESS="ru_RU.UTF-8"
LC_TELEPHONE="en_GB.UTF-8"
LC_MEASUREMENT="C.UTF-8"
LC_IDENTIFICATION="ru_RU.UTF-8"
LC_ALL=
CONFIG_LOCALE

source /etc/default/locale
export LC_ALL="en_US.UTF-8"

bash -c "$(curl -sL $SETUP_BITRIX_DEBIAN_URL)"

source /root/run.sh

set +x
set -euo pipefail

# set mysql root password
#root_pass=$(generate_password 24)
site_user_password=$(generate_password 24)

#mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${root_pass}');FLUSH PRIVILEGES;"

#cat > /root/.my.cnf <<CONFIG_MYSQL_ROOT_MY_CNF
#[client]
#user=root
#password="${root_pass}"
# socket=/var/lib/mysqld/mysqld.sock

#CONFIG_MYSQL_ROOT_MY_CNF

# Clone directory vm_menu with repositories
git clone -b $BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/DebianLikeBitrixVM"
cd "$DEST_DIR_MENU/DebianLikeBitrixVM"
git sparse-checkout set $DIR_NAME_MENU

# Move vm_menu in /root and clean
rm -rf $DEST_DIR_MENU/$DIR_NAME_MENU
mv -f $DIR_NAME_MENU $DEST_DIR_MENU
rm -rf "$DEST_DIR_MENU/DebianLikeBitrixVM"

cd $DEST_DIR_MENU

chmod -R +x $DEST_DIR_MENU/$DIR_NAME_MENU

# Check script in .profile and add to .profile if not exist
#if ! grep -qF "$FULL_PATH_MENU_FILE" /root/.profile; then
#  cat << INSTALL_MENU >> /root/.profile

#if [ -n "\$SSH_CONNECTION" ]; then
#  $FULL_PATH_MENU_FILE
#fi

#INSTALL_MENU
#fi

# Configure apache2 modules
a2enmod remoteip
a2enmod rewrite
a2enmod setenvif
a2dismod ssl

cat > /etc/apache2/mods-enabled/remoteip.conf <<CONFIG_APACHE2_REMOTEIP
<IfModule remoteip_module>
  RemoteIPHeader X-Real-IP
  RemoteIPInternalProxy 127.0.0.1
</IfModule>
CONFIG_APACHE2_REMOTEIP

cat > /etc/apache2/conf-enabled/php.conf <<CONFIG_APACHE2_FASTCGI
      #
      # The following lines prevent .user.ini files from being viewed by Web clients.
      #
      <Files ".user.ini">
          <IfModule mod_authz_core.c>
              Require all denied
          </IfModule>
          <IfModule !mod_authz_core.c>
              Order allow,deny
              Deny from all
              Satisfy All
          </IfModule>
      </Files>

      # Cause the PHP interpreter to handle files with a .php extension.
      <FilesMatch "\.php$">
      #        SetHandler "proxy:fcgi://127.0.0.1:9000"
              SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
      #       AddType application/x-httpd-php .php
      </FilesMatch>

      # Add index.php to the list of files that will be served as directory
      # indexes.

      DirectoryIndex index.php

      # Uncomment the following line to allow PHP to pretty-print .phps
      # files as PHP source code:
      #
      #AddType application/x-httpd-php-source .phps
CONFIG_APACHE2_FASTCGI

# set PHP 8.2
update-alternatives --set php /usr/bin/php8.2
update-alternatives --set phar /usr/bin/phar8.2
update-alternatives --set phar.phar /usr/bin/phar.phar8.2
update-alternatives --set php-fpm.sock /run/php/php8.2-fpm.sock


ln -s $FULL_PATH_MENU_FILE "$DEST_DIR_MENU/menu.sh"

# Final actions

source $DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh

DOCUMENT_ROOT="${BS_PATH_SITES}/bx-site"

DELETE_FILES=(
  "$BS_PATH_APACHE_SITES_CONF/000-default.conf"
  "$BS_PATH_APACHE_SITES_ENABLED/000-default.conf"
)

ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "is_new_install_env=Y \
  account_name='' \
  smtp_file_sites_config=${BS_SMTP_FILE_SITES_CONFIG} \
  smtp_file_user_config=${BS_SMTP_FILE_USER_CONFIG} \
  smtp_file_group_user_config=${BS_SMTP_FILE_GROUP_USER_CONFIG} \
  smtp_file_permissions_config=${BS_SMTP_FILE_PERMISSIONS_CONFIG} \
  smtp_file_user_log=${BS_SMTP_FILE_USER_LOG} \
  smtp_file_group_user_log=${BS_SMTP_FILE_GROUP_USER_LOG} \
  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH}"

ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_NEW_FULL_ENVIRONMENT}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "domain=default \

  db_name=${DB_NAME} \
  db_user=${DB_USER} \
  db_password=${DBPASS} \
  mysql_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
  mysql_collation_server=${BS_DB_COLLATION} \

  site_user_password=${site_user_password} \

  path_sites=${BS_PATH_SITES} \
  document_root=${DOCUMENT_ROOT} \

  delete_files=$(IFS=,; echo "${DELETE_FILES[*]}") \

  download_bitrix_install_files_new_site=$(IFS=,; echo "${BS_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE[*]}") \
  timeout_download_bitrix_install_files_new_site=${BS_TIMEOUT_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE} \

  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \

  permissions_sites_dirs=${BS_PERMISSIONS_SITES_DIRS} \
  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \

  service_nginx_name=${BS_SERVICE_NGINX_NAME} \
  path_nginx=${BS_PATH_NGINX} \
  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  path_nginx_sites_enabled=${BS_PATH_NGINX_SITES_ENABLED} \

  service_apache_name=${BS_SERVICE_APACHE_NAME} \
  path_apache=${BS_PATH_APACHE} \
  path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
  path_apache_sites_enabled=${BS_PATH_APACHE_SITES_ENABLED} \

  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \

  bx_cron_agents_path_file_after_document_root=${BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT} \
  bx_cron_logs_path_dir=${BS_BX_CRON_LOGS_PATH_DIR} \
  bx_cron_logs_path_file=${BS_BX_CRON_LOGS_PATH_FILE} \

  push_key=${PUSH_KEY}"

echo -e "\n\n";
echo "Full environment installed";
echo -e "\n";
echo "Password for the user ${BS_USER_SERVER_SITES}:";
echo "${site_user_password}";
echo -e "\n";
END

bash /root/temp_install_full_environment.sh

rm /root/temp_install_full_environment.sh
rm /root/run.sh
