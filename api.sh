#!/bin/bash

NC='\033[0m'
rbg='\033[41;37m'
r='\033[1;91m'
g='\033[1;92m'
y='\033[1;93m'
u='\033[0;35m'
c='\033[0;96m'
w='\033[1;97m'
q="\e[1;44;41m"
a='\033[0;34m'

MYIP=$(cat /root/.ipvps)
API_FOLDER="/etc/api/"
API_DB=".api.db"
API_FILE="api.py"
hosting="https://raw.githubusercontent.com/g9ktx7lm/api/main/"

lane_atas() {
  echo -e "${c}┌──────────────────────────────────────────┐${NC}"
}
lane_bawah() {
  echo -e "${c}└──────────────────────────────────────────┘${NC}"
}

fun_bar() {
  CMD[0]="$1"
  CMD[1]="$2"
  (
    [[ -e $HOME/fim ]] && rm $HOME/fim
    ${CMD[0]} -y >/dev/null 2>&1
    ${CMD[1]} -y >/dev/null 2>&1
    touch $HOME/fim
  ) >/dev/null 2>&1 &
  tput civis
  echo -ne "  \033[0;33mPlease Wait Loading \033[1;37m- \033[0;33m["
  while true; do
    for ((i = 0; i < 18; i++)); do
      echo -ne "\033[0;32m#"
      sleep 0.1s
    done
    [[ -e $HOME/fim ]] && rm $HOME/fim && break
    echo -e "\033[0;33m]"
    sleep 1s
    tput cuu1
    tput dl1
    echo -ne "  \033[0;33mPlease Wait Loading \033[1;37m- \033[0;33m["
  done
  echo -e "\033[0;33m]\033[1;37m -\033[1;32m OK !\033[1;37m"
  tput cnorm
}

function install_api() {
  clear
  domain=$(cat /etc/xray/domain)

  if [[ "$(systemctl is-active xdapi)" == "active" ]]; then
    systemctl stop xdapi &>/dev/null
    systemctl disable xdapi &>/dev/null
    rm -f /etc/systemd/system/xdapi.service &>/dev/null
    rm -rf /etc/api
  fi


  function cekos() {
    source /etc/os-release
    echo "$ID $VERSION_ID"
  }

  mkdir -p ${API_FOLDER}
  rm -f ${API_FOLDER}${API_DB}
  touch ${API_FOLDER}${API_DB}
  
  apt update
  apt install python3 python3-pip git -y
  apt install -y python3.11-venv
  python3 -m venv ${API_FOLDER}env
  source ${API_FOLDER}env/bin/activate
  pip3 install --upgrade pip
  pip3 install quart
  deactivate
  anu="${API_FOLDER}env/bin/python3"
  
  wget -q -O ${API_FOLDER}${API_FILE} "${hosting}${API_FILE}"
  wget -q -O /usr/sbin/m_api "${hosting}m_api"

  key=$(cat /proc/sys/kernel/random/uuid)
  port="1108"

  echo "### ${key} ${port}" > ${API_FOLDER}${API_DB}

  cat > /etc/systemd/system/xdapi.service << END
[Unit]
Description=XDTunnel API Create SSH/XRAY - @xdxlreal
After=network.target

[Service]
WorkingDirectory=/etc/api
Environment="PORT=$port"
ExecStart=$anu ${API_FILE}
Restart=always

[Install]
WantedBy=multi-user.target
END

  systemctl daemon-reload
  systemctl enable xdapi
  systemctl restart xdapi
  cd /root
  clear
  lane_atas
  echo -e "${c}│$NC       ${u}.::.${NC} ${w}INSTALL API SUCCESS${NC} ${u}.::.${NC}      ${c}│${NC}"
  lane_bawah
  echo -e " API KEY : $key"
  echo -e " PORT    : $port"
  lane_bawah
  echo
  read -n 1 -s -r -p "Press any key to back on menu"
  menuapi
}

function restart_api() {
  res1() {
    systemctl enable xdapi
    systemctl restart xdapi
  }
  export -f res1
  clear
  lane_atas
  echo -e "${c}│$NC      ${u}.::.${NC} ${w}RESTART API XDTunnel${NC} ${u}.::.${NC}      ${c}│${NC}"
  lane_bawah
  lane_atas
  echo -e ""
  echo -e "  \033[1;91m restart api service\033[1;37m"
  fun_bar 'res1'
  lane_bawah
  echo -e ""
  read -n 1 -s -r -p "Press any key to back on menu"
  menuapi
}

function stop_api() {
  res1() {
    systemctl disable xdapi
    systemctl stop xdapi
  }
  export -f res1
  clear
  lane_atas
  echo -e "${c}│$NC        ${u}.::.${NC} ${w}STOP API XDTunnel${NC} ${u}.::.${NC}       ${c}│${NC}"
  lane_bawah
  lane_atas
  echo -e ""
  echo -e "  \033[1;91m stop api service\033[1;37m"
  fun_bar 'res1'
  lane_bawah
  echo -e ""
  read -n 1 -s -r -p "Press any key to back on menu"
  menuapi
}

function delete_api() {
  res1() {
    systemctl stop xdapi &>/dev/null || true
    systemctl disable xdapi &>/dev/null || true
    rm -f /etc/systemd/system/xdapi.service
    systemctl daemon-reload &>/dev/null || true
    rm -rf /etc/api
    sleep 0.2
  }
  export -f res1
  clear
  lane_atas
  echo -e "${c}│$NC       ${u}.::.${NC} ${w}DELETE API XDTunnel${NC} ${u}.::.${NC}      ${c}│${NC}"
  lane_bawah
  lane_atas
  echo -e ""
  echo -e "  \033[1;91m delete api service\033[1;37m"
  fun_bar 'res1'
  lane_bawah
  echo -e ""
  read -n 1 -s -r -p "Press any key to back on menu"
  menuapi
}

function change_regkey() {
  read -r _ KEY PORT <${API_FOLDER}${API_DB}

  clear
  lane_atas
  echo -e "${c}│$NC         ${u}.::.${NC} ${w}CHANGE KEY API${NC} ${u}.::.${NC}          ${c}│${NC}"
  lane_bawah
  echo
  echo -e "${c}│$NC ${a}1.)${y}☞ ${w} Custom Key${NC}"
  echo -e "${c}│$NC ${a}2.)${y}☞ ${w} Regenerate Random Key (otomatis)${NC}"
  echo -e "${c}│$NC ${a}x.)${y}☞ ${w} Cancel${NC}"
  echo
  lane_bawah
  echo
  read -p " Select Options [ 1 - 2 or x ] " opt

  case $opt in
    01 | 1)
      clear
      echo
      read -p " Masukkan Custom Key (min. 5 karakter huruf/angka): " NEW_KEY

      if ! [[ "${NEW_KEY}" =~ ^[a-zA-Z0-9]{5,}$ ]]; then
        echo
        echo -e " ${r}Key tidak valid! Minimal 5 karakter huruf dan angka.${NC}"
        echo
        sleep 2
        change_regkey
        return
      fi

      echo "### ${NEW_KEY} ${PORT}" > ${API_FOLDER}${API_DB}
      systemctl restart xdapi &>/dev/null
      echo
      echo -e " ${g}Custom Key berhasil disimpan: ${w}${NEW_KEY}${NC}"
      echo
      sleep 2
      menuapi
      ;;

    02 | 2)
      clear
      NEW_KEY=$(cat /proc/sys/kernel/random/uuid)
      echo "### ${NEW_KEY} ${PORT}" > ${API_FOLDER}${API_DB}
      systemctl restart xdapi &>/dev/null
      echo
      echo -e " ${g}Random Key berhasil di-generate: ${w}${NEW_KEY}${NC}"
      echo
      sleep 2
      menuapi
      ;;

    x | X | *)
      menuapi
      ;;
  esac
}

function change_port_api() {
  read -r _ KEY PORT <${API_FOLDER}${API_DB}

  clear
  lane_atas
  echo -e "${c}│$NC         ${u}.::.${NC} ${w}CHANGE PORT API${NC} ${u}.::.${NC}          ${c}│${NC}"
  lane_bawah
  echo
  echo -e "${c}│$NC ${w}Port saat ini : ${y}${PORT}${NC}"
  echo -e "${c}│$NC ${a}x.)${y}☞ ${w} Cancel${NC}"
  echo
  lane_bawah
  echo
  read -p " Masukkan Port baru (4-6 angka) atau x untuk cancel: " NEW_PORT

  if [[ "${NEW_PORT}" == "x" || "${NEW_PORT}" == "X" ]]; then
    menuapi
    return
  fi

  if ! [[ "${NEW_PORT}" =~ ^[0-9]{4,6}$ ]]; then
    echo
    echo -e " ${r}Port tidak valid! Wajib angka, minimal 4 digit dan maksimal 6 digit.${NC}"
    echo
    sleep 2
    change_port_api
    return
  fi

  if ss -tlnp 2>/dev/null | awk '{print $4}' | grep -qE ":${NEW_PORT}$"; then
    used_by=$(ss -tlnp | awk '{print $4, $6}' | grep ":${NEW_PORT} " | awk -F'pid=' '{print $2}' | cut -d',' -f1)
    echo
    echo -e " ${r}Port ${NEW_PORT} sudah digunakan oleh service lain!${NC}"
    [[ -n "${used_by}" ]] && echo -e " ${r}PID : ${used_by}${NC}"
    echo
    sleep 2
    change_port_api
    return
  fi

  echo "### ${KEY} ${NEW_PORT}" > ${API_FOLDER}${API_DB}

  sed -i "s|Environment=\"PORT=.*\"|Environment=\"PORT=${NEW_PORT}\"|" /etc/systemd/system/xdapi.service
  systemctl daemon-reload &>/dev/null
  systemctl restart xdapi &>/dev/null

  echo
  echo -e " ${g}Port berhasil diubah: ${w}${PORT}${NC} ${g}→${NC} ${w}${NEW_PORT}${NC}"
  echo
  sleep 2
  menuapi
}

function menuapi() {
  if [[ "$(systemctl is-active xdapi)" == "active" ]]; then
    status_api="${g}ON${NC}"
  else
    status_api="${r}OFF${NC}"
  fi

  if [[ -e ${API_FOLDER}${API_DB} ]]; then
    KEY=$(awk '{print $2}' ${API_FOLDER}${API_DB})
    PORT=$(awk '{print $3}' ${API_FOLDER}${API_DB})
  else
    KEY=""
    PORT=""
  fi

  clear
  lane_atas
  echo -e "${c}│$NC        ${u}.::.${NC} ${w}MENU API XDTunnel${NC} ${u}.::.${NC}       ${c}│${NC}"
  lane_bawah
  lane_atas
  echo -e "${c}│$NC Status Service API : ${status_api}${NC}"
  echo -e "${c}│$NC KEY  : ${KEY}${NC}"
  echo -e "${c}│$NC Port : ${PORT}${NC}"
  echo -e "${c}│$NC IP   : ${MYIP}${NC}"
  lane_bawah
  lane_atas
  echo -e "${c}│$NC ${a}1.)${y}☞ ${w} Install Service API${NC}"
  echo -e "${c}│$NC ${a}2.)${y}☞ ${w} Restart Service API${NC}"
  echo -e "${c}│$NC ${a}3.)${y}☞ ${w} Stop Service API${NC}"
  echo -e "${c}│$NC ${a}4.)${y}☞ ${w} Delete Service API${NC}"
  echo -e "${c}│$NC ${a}5.)${y}☞ ${w} Change Port API${NC}"
  echo -e "${c}│$NC ${a}6.)${y}☞ ${w} Change Or Regenerate Key${NC}"
  echo -e "${c}│$NC ${a}x.)${y}☞ ${r} Exit${NC}"
  lane_bawah
  echo
  read -p " Select Options [ 1 - 6 or x ] : " opt
  case $opt in
    01 | 1) clear ; install_api ;;
    02 | 2) clear ; restart_api ;;
    03 | 3) clear ; stop_api ;;
    04 | 4) clear ; delete_api ;;
    05 | 5) clear ; change_port_api ;;
    06 | 6) clear ; change_regkey ;;
    x) clear ; echo "Thank you for using my script :)"; exit 0 ;;
    *) menuapi ;;
  esac
}
menuapi