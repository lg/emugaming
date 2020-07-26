#!/bin/ash

# disconnect all virtual terminals (for GPU passthrough to work)
test -e /sys/class/vtconsole/vtcon0/bind && echo 0 > /sys/class/vtconsole/vtcon0/bind
test -e /sys/class/vtconsole/vtcon1/bind && echo 0 > /sys/class/vtconsole/vtcon1/bind
test -e /sys/devices/platform/efi-framebuffer.0/driver && echo "efi-framebuffer.0" > /sys/devices/platform/efi-framebuffer.0/driver/unbind

# load vfio drivers onto devices if it's not loaded (for GPU passthrough to work)
modprobe vfio_pci
modprobe vfio_iommu_type1
for pci_id in "0000:01:00.0" "0000:01:00.1" "0000:01:00.2" "0000:01:00.3"; do
  test -e /sys/bus/pci/devices/$pci_id/driver && echo -n "$pci_id" > /sys/bus/pci/devices/$pci_id/driver/unbind
  echo "$(cat /sys/bus/pci/devices/$pci_id/vendor) $(cat /sys/bus/pci/devices/$pci_id/device)" > /sys/bus/pci/drivers/vfio-pci/new_id
done
sleep 1     # TODO: remove this

# let the killing begin
qemu-system-x86_64 \
  -nodefaults \
  -monitor stdio \
  \
  -machine type=q35 `# allows for PCIe` \
  -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd `# read-only UEFI bios` \
  -drive if=pflash,format=raw,file=/qemu-win10.nvram `# UEFI writeable NVRAM` \
  -rtc clock=host,base=localtime `# faster boot aparently` \
  -device qemu-xhci `# USB3 bus` \
  \
  -enable-kvm \
  -cpu host,check,enforce,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time,l3-cache=on,-hypervisor,kvm=off,migratable=no,+invtsc,hv_vendor_id=1234567890ab \
  -smp cpus=20,cores=10,threads=2,sockets=1 \
  -m 8G \
  \
  -object iothread,id=io1 \
  -device virtio-blk-pci,drive=disk0,iothread=io1 \
  -drive if=none,id=disk0,cache=none,format=qcow2,aio=threads,file=/emugaming.qcow2 \
  \
  -nic user,model=virtio-net-pci `# simple passthrough networking that cant ping` \
  \
  -device vfio-pci,host=01:00.0,multifunction=on,x-vga=on,rombar=1,romfile=/TU102.rom \
  -device vfio-pci,host=01:00.1 `# audio` \
  \
  -device usb-host,vendorid=0x1532,productid=0x0062 `# razer atheris mouse` \
  -device usb-host,vendorid=0x05ac,productid=0x0267 `# apple magic keyboard` \
  \
  -vga none \
  -nographic