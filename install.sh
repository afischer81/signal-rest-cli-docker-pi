#!/bin/bash

IMAGE=bbernhard/signal-cli-rest-api:0.55
NAME=signal-cli
PORT=8080

function get_hostname {
    if [ -x /bin/hostname ]
    then
        hostname -s
    elif [ -f /etc/hostname ]
    then
        cat /etc/hostname
    elif [ -x /sbin/uci ]
    then
        uci get system.@system[0].hostname
    fi | tr A-Z a-z
}

function do_image {
    docker pull ${IMAGE}
}

function do_start {
    do_run
}

function do_stop {
    docker rm -f ${NAME}
}

function do_restart {
    do_stop
    sleep 5
    do_run
}

function do_run {
    mkdir -p config
    docker run \
        -d \
        -e MODE=normal \
        -e AUTO_RECEIVE_SCHEDULE='43 4 * * *' \
        -p ${PORT}:8080 \
        -v ${PWD}/config:/home/.local/share/signal-cli \
        --name=${NAME} \
        --restart=unless-stopped \
        ${IMAGE}
}

function do_shell {
    mkdir -p config
    docker run \
        --rm -it \
        -e MODE=normal \
        -p ${PORT}:8080 \
        -v ${PWD}/config:/home/.local/share/signal-cli \
        ${IMAGE} /bin/bash
}

function do_backup {
    timestamp=$(date +'%Y-%m-%d')
    tar -c -J -f ${timestamp}_${NAME}.tar.xz config
    sudo mv ${timestamp}_${NAME}.tar.xz ${BACKUP_DIR}
}

function do_register {
    number=$(jq -r .number .config)
    captcha=$(jq -r .captcha .config)
    cat > tmp.json <<EOF
{
  "captcha": "${captcha}",
  "use_voice": true
}
EOF
    curl -s -S --location --request POST \
        --data @tmp.json \
        'http://localhost:8080/v1/register/'${number}
}

function do_register_verify {
    number=$(jq -r .number .config)
    token=$1
    curl -s -S --location --request POST \
        'http://localhost:8080/v1/register/'${number}/verify/${token}
}

function do_receive {
    number=$(jq -r .number .config)
    curl -s -S --location \
        --output - \
        'http://localhost:8080/v1/receive/'${number}
}

function do_identities {
    number=$(jq -r .number .config)
    trust=$1
    safety_number=$2
    if [ "${trust}" = "" ]
    then
        curl -s -S --location \
            'http://localhost:8080/v1/identities/'${number} | jq .
    else
    cat > data.json <<EOF
{
  "verified_safety_number": "${safety_number}"
}
EOF
        curl -s -S --location --request PUT \
            --data @data.json \
            'http://localhost:8080/v1/identities/'${number}/trust/${trust}
    fi
}

function do_profile {
    number=$(jq -r .number .config)
    name=$(jq -r .name .config)
    avatar=$(jq -r .avatar .config)
    receiver=$1
    cat > data.json <<EOF
{
  "base64_avatar": "${avatar}",
  "name": "${name}"
}
EOF
    curl -s -S --location --request PUT \
        --data @data.json \
        --output - \
        'http://localhost:8080/v1/profiles/'${number}
}

function do_qrcode {
    curl -v -S --location \
        --output qrcode.png \
        'http://localhost:8080/v1/qrcodelink?device_name='${HOST}
}

function do_message {
    number=$(jq -r .number .config)
    receiver=$1
    shift
    message=$*
    cat > data.json <<EOF
{
  "message": "${message}",
  "number": "${number}",
  "recipients": [
    "${receiver}"
  ]
}
EOF
    curl -s -S --location --request POST \
        --data @data.json \
        'http://localhost:8080/v2/send/'
}

HOST=$(get_hostname)
BACKUP_DIR=/backup/${HOST}

task=$1
shift
do_$task $*
