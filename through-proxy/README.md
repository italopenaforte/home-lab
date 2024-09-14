precisa da network do proxy criada antecipadamente


docker network create proxy


Organizando o Boot das VM

```
#!/bin/bash

# IDs das VMs
VM_ID_1=101
VM_ID_2=102

# Função para verificar se a VM está rodando
is_vm_running() {
    local VM_ID=$1
    local STATUS=$(qm status $VM_ID | grep -o 'running')
    if [ "$STATUS" == "running" ]; then
        return 0  # VM está rodando
    else
        return 1  # VM não está rodando
    fi
}

# Loop até a VM 101 estar rodando
while true; do
    if is_vm_running $VM_ID_1; then
        echo "VM $VM_ID_1 está rodando. Aguardando 5 minutos para iniciar a VM $VM_ID_2..."
        sleep 300  # Aguarda 5 minutos (300 segundos)
        qm start $VM_ID_2
        echo "VM $VM_ID_2 iniciada."
        break
    else
        echo "VM $VM_ID_1 não está rodando. Verificando novamente em 30 segundos..."
        sleep 30  # Aguarda 30 segundos antes de verificar novamente
    fi
done

```

crie o script
```
nano /usr/local/bin/start_vm_after_vm.sh
```

dê as pergmisões de execução
```
chmod +x /usr/local/bin/start_vm_after_vm.sh
```


crie um serviço no systemd
```
nano /etc/systemd/system/start_vm_after_vm.service
```

cole o contéudo
```
[Unit]
Description=Inicia a VM 102 após a VM 101 estar rodando por 5 minutos
After=proxmox.service

[Service]
Type=simple
ExecStart=/usr/local/bin/start_vm_after_vm.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

arquivos criados, hora de configurar a execução
```
systemctl daemon-reload

systemctl enable start_vm_after_vm.service

systemctl start start_vm_after_vm.service
```

agora toda vez que o node do proxmox subir, irá subir a instancia da vm 101 após a execução da vm 100