FROM alpine
RUN apk add qemu-system-x86_64 qemu-img ovmf
COPY TU102.rom /
COPY start.sh /
RUN cp /usr/share/OVMF/OVMF_VARS.fd /qemu-win10.nvram
CMD /start.sh
