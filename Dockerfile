FROM alpine
RUN apk add qemu-system-x86_64 qemu-img ovmf
COPY win10-BASE.qcow2 /
COPY TU102.rom /
COPY start.sh /
RUN qemu-img create -f qcow2 -b /win10-BASE.qcow2 /win10-LIVE.qcow2 && cp /usr/share/OVMF/OVMF_VARS.fd /qemu-win10.nvram
CMD /start.sh
