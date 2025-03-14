#!/bin/bash
# script that is called after the build

# don't need
exit 0

set -e

# Telegram functions. Requires CHAT_ID and BOT_TOKEN
function tg_sendText() {
        curl -s "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
                -d "parse_mode=html" \
                -d text="${1}" \
                -d chat_id=$CHAT_ID \
                -d "disable_web_page_preview=true"
}
function tg_sendFile() {
        curl -s "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
                -F parse_mode=markdown \
                -F chat_id=$CHAT_ID \
                -F document=@"${1}" \
                -F caption="$2"
}

if [ ! -f "${srctree}/local.config" ]; then
echo "Please fill in your credentials in local.config"
exit 0
fi

source "${srctree}/local.config"
if [ -n "${DEVICE+x}" ]; then
DEVICE_STR=" for $DEVICE"
fi
tg_sendText "Build completed${DEVICE_STR}!"
if [ ! -n "${OBJ+x}" ]; then
echo "OBJ was not set. Not uploading"
exit 0
fi
${HOSTCC} ${srctree}/scripts/kernelversion.c -Iinclude/generated/ -o scripts/kernelversion -D__UTS__
${HOSTCC} ${srctree}/scripts/kernelversion.c -Iinclude/generated/ -o scripts/ccversion -D__CC__
KERNELSTR="$(./scripts/kernelversion)"
CCSTR="$(./scripts/ccversion)"
MY_PWD=$(pwd)
TIME="$(date "+%m%d-%H%M%S")"
KERNELZIP="$(echo ${KERNELSTR} | sed "s/$(echo "${KERNELSTR}" | sed 's/-/ /g' | awk '{print $1}')-//")@${TIME}.zip"
COMMITMSG="$(git log --pretty=format:'"%h : %s"' -1)"
BRANCH="$(git branch --show-current)"

# Make the script fail if submodile is not there
ls ${srctree}/scripts/packaging/* 2>&1 > /dev/null
cd ${srctree}/scripts/packaging/

bash pack.sh "${MY_PWD}/${OBJ}" "${KERNELZIP}"
tg_sendText "<b>${KERNELSTR} Kernel Build</b>%0ABuild ended <code>Target: ${OBJ}</code>%0AFor device ${DEVICE}%0Abranch <code>${BRANCH}</code>%0AUnder commit <code>${COMMITMSG}</code>%0AUsing compiler: <code>${CCSTR}</code>%0AEnded on <code>$(date)</code>"
tg_sendFile "${KERNELZIP}"
