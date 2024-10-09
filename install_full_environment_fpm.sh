#!/usr/bin/env bash
set +x
set -euo pipefail
# Install full environment
# MASTER branch

# use curl
# bash <(curl -sL https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/install_full_environment_fpm.sh)

# use wget
# apt install wget -y
# wget https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/.env.menu.example -O /root/.env.menu
# edit .env.menu with your settings.
# bash <(wget -qO- https://raw.githubusercontent.com/YogSottot/DebianLikeBitrixVM/feature/php-fpm/install_full_environment_fpm.sh)

generate_password() {
    local length=$1
    local specials='!@#$%^&*()-_=+[]|;:,.<>?/~'
    local all_chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789${specials}"

    local password=""
    for i in $(seq 1 $length); do
        local char=${all_chars:RANDOM % ${#all_chars}:1}
        password+=$char
    done

    echo "$password"
}

BRANCH="feature/php-fpm"
REPO_URL="https://github.com/YogSottot/DebianLikeBitrixVM"

DB_NAME="bitrix"
DB_USER="bitrix"
DBPASS=$(generate_password 24)

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

apt update -y
apt upgrade -y
apt install -y ansible git locales-all
# fix for mysql role
ansible-galaxy collection install 'community.mysql:==3.10.3'

site_user_password=$(generate_password 24)

# Clone directory vm_menu with repositories
git clone --branch=$BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/DebianLikeBitrixVM"
cd "$DEST_DIR_MENU/DebianLikeBitrixVM"
git sparse-checkout set $DIR_NAME_MENU

# Move vm_menu in /root and clean
rm -rf "${DEST_DIR_MENU:?}/${DIR_NAME_MENU:?}"
mv -f $DIR_NAME_MENU $DEST_DIR_MENU
rm -rf "${DEST_DIR_MENU:?}/DebianLikeBitrixVM"

cd $DEST_DIR_MENU

chmod -R +x $DEST_DIR_MENU/$DIR_NAME_MENU

# Check script in .profile and add to .profile if not exist
if ! grep -qF "$FULL_PATH_MENU_FILE" /root/.profile; then
  cat << INSTALL_MENU >> /root/.profile

#if [ -n "\$SSH_CONNECTION" ]; then
#  $FULL_PATH_MENU_FILE
#fi

INSTALL_MENU
fi

ln -fs $FULL_PATH_MENU_FILE "$DEST_DIR_MENU/menu.sh"

# Final actions
# shellcheck source=/dev/null
source $DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh

# shellcheck source=/dev/null
if [ -e /root/.env.menu ]; then
  source /root/.env.menu
fi

# set timezone
timedatectl set-timezone "${BS_SERVER_TIMEZONE}"

DOCUMENT_ROOT="${BS_PATH_DEFAULT_SITE}"

# setup repos
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_REPOS}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

# install deps
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_DEPS}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

# setup bashrc
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_BASHRC}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  path_sites=${BS_PATH_SITES} "

# setup postfix
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETUP_POSTFIX}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS"

# setup user / nginx / mysql / apache2 / firewalld / php-fpm
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INITIAL_SETUP}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "domain=default \

  db_name=${DB_NAME} \
  db_user=${DB_USER} \
  db_password=${DBPASS} \
  mysql_flavor=${BS_DB_FLAVOR} \
  mysql_version=${BS_DB_VERSION} \
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

  push_server_config=${BS_PUSH_SERVER_CONFIG} \
  php_version=${BX_PHP_DEFAULT_VERSION} \
  server_timezone=${BS_SERVER_TIMEZONE}"

# SMTP
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
  -e "is_new_install_env=Y \
  account_name='' \
  smtp_file_sites_config=${BS_SMTP_FILE_SITES_CONFIG} \
  smtp_file_user_config=${BS_SMTP_FILE_USER_CONFIG} \
  smtp_file_group_user_config=${BS_SMTP_FILE_GROUP_USER_CONFIG} \
  smtp_file_permissions_config=${BS_SMTP_FILE_PERMISSIONS_CONFIG} \
  smtp_file_user_log=${BS_SMTP_FILE_USER_LOG} \
  smtp_file_group_user_log=${BS_SMTP_FILE_GROUP_USER_LOG} \
  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH}"

# Full enviroment
ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_NEW_FULL_ENVIRONMENT}" "$BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS" \
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

  push_server_config=${BS_PUSH_SERVER_CONFIG} \
  
  php_version=${BX_PHP_DEFAULT_VERSION} \
  php_current_default_version=${BX_PHP_DEFAULT_VERSION} \
  server_timezone=${BS_SERVER_TIMEZONE}"

# disable httpd access logs
find /etc/apache2/ -type f -print0 | xargs -0 sed -i 's/CustomLog/#CustomLog/g'
systemctl restart apache2.service
# fix services
systemctl restart php"${BX_PHP_DEFAULT_VERSION}"-fpm.service
systemctl restart postfix@-.service
firewall-cmd --reload
apt install -y mysqltuner

# fix journald sizes
sed -i -e 's/#SystemMaxUse=/SystemMaxUse=100M/g' /etc/systemd/journald.conf
sed -i -e 's/#RuntimeMaxUse=/RuntimeMaxUse=100M/g' /etc/systemd/journald.conf
systemctl restart systemd-journald

if [ "$BS_PUSH_SERVER_STOPPED" == true  ]; then
  systemctl stop push-server.service
  systemctl disable push-server.service
  systemctl stop redis.service
  systemctl disable redis.service
fi

echo -e "\n\n";
echo "Full environment installed";
echo -e "\n";
echo "Password for the user ${BS_USER_SERVER_SITES}:";
echo "${site_user_password}";
echo -e "\n";
