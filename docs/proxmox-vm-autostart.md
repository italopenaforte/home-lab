# Proxmox VM Auto-Start

Auto-start VMs/LXC containers after Proxmox boots, with a delay between them.

## 1. Create the startup script

```bash
sudo nano /usr/local/bin/start_vm.sh
```

Paste the following content:

```bash
#!/bin/bash

# VM IDs — adjust to your environment
VM_ID_1=100
VM_ID_2=101

is_vm_running() {
    local VM_ID=$1
    local STATUS
    STATUS=$(qm status "$VM_ID" | grep -o 'running')
    if [ "$STATUS" == "running" ]; then
        return 0
    else
        return 1
    fi
}

# Wait until VM_ID_1 is running, then start VM_ID_2 after 5 minutes
while true; do
    if is_vm_running "$VM_ID_1"; then
        echo "VM $VM_ID_1 is running. Waiting 5 minutes before starting VM $VM_ID_2..."
        sleep 300
        qm start "$VM_ID_2"
        echo "VM $VM_ID_2 started."
        break
    else
        echo "VM $VM_ID_1 is not running. Retrying in 30 seconds..."
        sleep 30
    fi
done
```

## 2. Make it executable

```bash
chmod +x /usr/local/bin/start_vm.sh
```

## 3. Create a systemd service

```bash
sudo nano /etc/systemd/system/start_vm.service
```

```ini
[Unit]
Description=Start VM 101 after VM 100 has been running for 5 minutes
After=proxmox.service

[Service]
Type=simple
ExecStart=/usr/local/bin/start_vm.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## 4. Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable start_vm.service
sudo systemctl start start_vm.service
```

After this, every time the Proxmox node boots, VM 101 will start automatically after VM 100 is running for 5 minutes.
