#!/bin/bash

clear
echo "Создание директории для Cloud Shell"
mkdir -p ~/.cloudshell && touch ~/.cloudshell/no-apt-get-warning # Для Google Cloud Shell, но лучше там не выполнять

echo "Установка зависимостей..."
echo "Обновляем репозитории..."
apt update -y && apt install sudo -y # Для Aeza Terminator, там sudo не установлен по умолчанию

echo "Вторичное обновление и установка дополнительных пакетов..."
sudo apt-get update -y --fix-missing && sudo apt-get install wireguard-tools jq wget -y --fix-missing # Update второй раз, если sudo установлен и обязателен (в строке выше не сработал)

# Генерация ключей
echo "Генерация ключей..."
priv="${1:-$(wg genkey)}"
pub="${2:-$(echo "${priv}" | wg pubkey)}"
api="https://api.cloudflareclient.com/v0i1909051800"
echo "API адрес: ${api}"

ins() {
    echo "Отправка запроса с методом: $1 и URL: $2"
    curl -s -H 'user-agent:' -H 'content-type: application/json' -X "$1" "${api}/$2" "${@:3}"
}
sec() {
    echo "Отправка PATCH запроса на ${api}/$2 с токеном: $3"
    ins "$1" "$2" -H "authorization: Bearer $3" "${@:4}"
}
response=$(ins POST "reg" -d "{\"install_id\":\"\",\"tos\":\"$(date -u +%FT%T.000Z)\",\"key\":\"${pub}\",\"fcm_token\":\"\",\"type\":\"ios\",\"locale\":\"en_US\"}")
echo "Ответ после регистрации: $response"

clear
echo -e "НЕ ИСПОЛЬЗУЙТЕ GOOGLE CLOUD SHELL ДЛЯ ГЕНЕРАЦИИ! Если вы сейчас в Google Cloud Shell, прочитайте актуальный гайд: https://t.me/immalware/1211\n"

# Извлекаем данные из ответа
echo "Извлекаем ID и токен из ответа..."
id=$(echo "$response" | jq -r '.result.id')
token=$(echo "$response" | jq -r '.result.token')
echo "ID: $id, Токен: $token"

response=$(sec PATCH "reg/${id}" "$token" -d '{"warp_enabled":true}')
echo "Ответ на PATCH запрос: $response"

peer_pub=$(echo "$response" | jq -r '.result.config.peers[0].public_key')
client_ipv4=$(echo "$response" | jq -r '.result.config.interface.addresses.v4')
client_ipv6=$(echo "$response" | jq -r '.result.config.interface.addresses.v6')

echo "Получены данные для конфига:"
echo "PublicKey: $peer_pub"
echo "Client IPv4: $client_ipv4"
echo "Client IPv6: $client_ipv6"

# Создаем конфиг
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

# Выводим конфиг на экран
echo -e "\n\n\n"
[ -t 1 ] && echo "########## НАЧАЛО КОНФИГА ##########"
echo "${conf}"
[ -t 1 ] && echo "########### КОНЕЦ КОНФИГА ###########"

# Дополнительная информация
echo -e "\nЕсли что-то не получилось или есть вопросы, пишите в чат: https://t.me/immalware_chat"
