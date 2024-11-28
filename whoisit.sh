#!/bin/bash

clear
echo "Установка зависимостей на удаленный сервер."
echo -e "\n"
apt update -y && apt install sudo -y # для аеза нужен sudo
sudo apt-get update -y --fix-missing && sudo apt-get install wireguard-tools jq wget -y --fix-missing # апдейт

priv="${1:-$(wg genkey)}"
pub="${2:-$(echo "${priv}" | wg pubkey)}"
api="https://api.cloudflareclient.com/v0i1909051800"
ins() { curl -s -H 'user-agent:' -H 'content-type: application/json' -X "$1" "${api}/$2" "${@:3}"; }
sec() { ins "$1" "$2" -H "authorization: Bearer $3" "${@:4}"; }
response=$(ins POST "reg" -d "{\"install_id\":\"\",\"tos\":\"$(date -u +%FT%T.000Z)\",\"key\":\"${pub}\",\"fcm_token\":\"\",\"type\":\"ios\",\"locale\":\"en_US\"}")

clear
echo -e "Команда Hitech починит вам дискорд! :)"

id=$(echo "$response" | jq -r '.result.id')
token=$(echo "$response" | jq -r '.result.token')
response=$(sec PATCH "reg/${id}" "$token" -d '{"warp_enabled":true}')
peer_pub=$(echo "$response" | jq -r '.result.config.peers[0].public_key')
#peer_endpoint=$(echo "$response" | jq -r '.result.config.peers[0].endpoint.host')
client_ipv4=$(echo "$response" | jq -r '.result.config.interface.addresses.v4')
client_ipv6=$(echo "$response" | jq -r '.result.config.interface.addresses.v6')

conf=$(cat <<-EOM
[Interface]
PrivateKey = ${priv}
S1 = 0
S2 = 0
Jc = 120
Jmin = 23
Jmax = 911
H1 = 1
H2 = 2
H3 = 3
H4 = 4
MTU = 1280
Address = ${client_ipv4}, ${client_ipv6}
DNS = 1.1.1.1, 2606:4700:4700::1111, 1.0.0.1, 2606:4700:4700::1001

[Peer]
PublicKey = ${peer_pub}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 188.114.97.66:3138
EOM
)

echo -e "\n"
[ -t 1 ] && echo "Если боитесь скачивать можете скопировать то что ниже в блокнот и назвать его WARP.conf"
echo -e "\n"
echo "${conf}"
echo -e "\n"
[ -t 1 ] && echo "#############конец конфига"

conf_base64=$(echo -n "${conf}" | base64 -w 0)
echo "Ссылка для скачивания файла WARP.conf:"
echo -e "\n"
echo "https://dmitriy-nasyrov.github.io/warps/?filename=WARP.conf&content=${conf_base64}"
echo -e "\n"
echo "если что-то не получилось могу помочь в телеге https://t.me/perspektiv_net"
