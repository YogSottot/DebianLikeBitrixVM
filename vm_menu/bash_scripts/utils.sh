#!/bin/bash

declare -A ARR_ALL_DIR_SITES_DATA

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

list_sites(){
  ARR_ALL_DIR_SITES_DATA=()
  ARR_ALL_DIR_SITES=()
  echo -e "   List of sites dirs: \n";

  get_current_version_php

  # Функция для заполнения массива данными
  fill_array() {
    local index=0
    for tmp_dir in $(find "$BS_PATH_SITES" -maxdepth 1 -type d | grep -v "^$BS_PATH_SITES$" | sed 's|.*/||'); do

      if [[ $tmp_dir =~ ^\. ]]; then
        continue
      fi

      if [[ " ${BS_EXCLUDED_DIRS_SITES[@]} " =~ " $tmp_dir " ]]; then
        continue
      fi

      ARR_ALL_DIR_SITES+=("$tmp_dir")
      ARR_ALL_DIR_SITES_DATA["${index}_dir"]="$tmp_dir"
      ARR_ALL_DIR_SITES_DATA[$index,is_default]="N"
      ARR_ALL_DIR_SITES_DATA[$index,is_https]="N"
      ARR_ALL_DIR_SITES_DATA[$index,doc_root]="$BS_PATH_SITES/$tmp_dir"

      if [[ "$tmp_dir" == "$BS_DEFAULT_SITE_NAME" ]]; then
        ARR_ALL_DIR_SITES_DATA[$index,is_default]="Y"
      fi

      if [[ -f "$BS_PATH_SITES/$tmp_dir/.htsecure" ]]; then
        ARR_ALL_DIR_SITES_DATA[$index,is_https]="Y"
      fi

      # Add PHP version information
      local site_config="/etc/apache2/sites-enabled/${tmp_dir}.conf"

      if [ -f "$site_config" ]; then
        php_version=$(grep -oP 'php\K[\d.]+(?=-fpm\.sock)' "$site_config")

        if [ -z "$php_version" ]; then
          php_version=$default_version
          ARR_ALL_DIR_SITES_DATA[$index,php_default]="Y"
        else
          ARR_ALL_DIR_SITES_DATA[$index,php_default]=$([ "$php_version" == "$default_version" ] && echo "Y" || echo "N")
        fi
        ARR_ALL_DIR_SITES_DATA[$index,php_version]="$php_version"
      else
        ARR_ALL_DIR_SITES_DATA[$index,php_version]="N/A"
        ARR_ALL_DIR_SITES_DATA[$index,php_default]="N/A"
      fi

      ((index++))
    done
  }

  # Функция для вывода горизонтальной линии
  print_line() {
    printf "   +"
    for i in {1..20}; do printf "-"; done
    printf "+"
    for i in {1..21}; do printf "-"; done
    printf "+"
    for i in {1..16}; do printf "-"; done
    printf "+"
    for i in {1..25}; do printf "-"; done
    printf "+"
    for i in {1..26}; do printf "-"; done
    printf "+"
    for i in {1..13}; do printf "-"; done
    printf "+"
    for i in {1..18}; do printf "-"; done
    printf "+"
  }

  # Функция для вывода таблицы
  print_table() {
    print_line
    printf "   | %-40s | %-12s | %-50s | %-10s | %-16s |\n" "Directory site" "Redirect HTTPS" "Document root" "PHP Version" "Default PHP"
    print_line

    local index=0
    while [[ -n "${ARR_ALL_DIR_SITES_DATA["${index}_dir"]}" ]]; do
      printf "   | %-40s | %-14s | %-50s | %-11s | %-16s |\n" \
        "${ARR_ALL_DIR_SITES_DATA["${index}_dir"]}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,is_https]}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,doc_root]}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,php_version]}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,php_default]}"
      print_line
      ((index++))
    done
  }

  fill_array
  print_table
  get_current_version_php
}


press_any_key_to_return_menu(){
    echo -e "\n";
    while true; do
        read -r -p "   To return to the menu, please press Enter " answer
        case $answer in
            * ) break;;
        esac
    done
}

read_by_def(){
    local message=${1}   # сообщение
    local var_name=${2}  # имя устанавливаемой переменной
    local def_val=${3}   # значение по умолчанию
    local user_input     # то, что ввел пользователь

    read -r -p "$message" user_input

    if [[ -z "$user_input" ]]; then
        printf -v "$var_name" "%s" "$def_val"
    else
        printf -v "$var_name" "%s" "$user_input"
    fi
}

function load_bitrix_vm_version() {
  unset $BS_VAR_NAME_BVM
  if test -f "$BS_VAR_PATH_FILE_BVM"; then
      source "${BS_VAR_PATH_FILE_BVM}"
  fi
}

function get_interfaces() {
  ip -o -4 addr list | grep -v ' lo ' | awk '{print $2, $4}'
}

function  get_ip_current_server() {
  while true; do
    interfaces=$(get_interfaces)
    if [ -n "$interfaces" ]; then
        break
    fi
    # ip monitor address | grep -m 1 'inet ' > /dev/null
  done

  CURRENT_SERVER_IP="Interface\tIP\n"

  while read -r line; do
      iface=$(echo $line | awk '{print $1}')
      ip=$(echo $line | awk '{print $2}' | cut -d'/' -f1)
      CURRENT_SERVER_IP+="          $iface\t$ip\n"
  done <<< "$interfaces"
}

function get_current_version_php() {
    default_version=$(update-alternatives --query php | grep 'Value:' | awk '{print $2}' | grep -oP '\d+\.\d+')
    version_list=$(update-alternatives --list php | grep -oP '\d+\.\d+' | sort -u | tr '\n' ' ')
    
    echo -e "\n   Current default PHP version: $default_version"
    echo -e "   All installed PHP versions: $version_list"
}


function get_available_version_php() {
    echo -e "\n   Available PHP versions:\n"

    versions=$(apt-cache search php | grep -oP '^php[0-9.]+ ' | sort -ur)
    for version in $versions; do
        echo "   $version"
    done

    echo -e "\n"
}
