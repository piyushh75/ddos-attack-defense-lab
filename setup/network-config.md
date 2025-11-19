# Network Configuration Guide

## VMware Network Setup

### Host-Only Network Configuration

1. **Open VMware Virtual Network Editor**
   - Windows: Edit > Virtual Network Editor
   - Mac: VMware Fusion > Preferences > Network

2. **Configure VMnet1 (Host-Only)**
```
   Network: VMnet1
   Type: Host-only
   Subnet IP: 192.168.153.0
   Subnet Mask: 255.255.255.0
```

3. **Disable DHCP**
   - Uncheck "Use local DHCP service"
   - We'll use static IPs

## Ubuntu Target Server Network Config

### Method 1: Netplan (Ubuntu 24.04)

Edit `/etc/netplan/00-installer-config.yaml`:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:  # Your interface name - check with 'ip a'
      addresses:
        - 192.168.153.129/24
      dhcp4: no
      dhcp6: no
```

Apply configuration:
```bash
sudo netplan apply
```

### Method 2: Manual Configuration
```bash
sudo ip addr add 192.168.153.129/24 dev ens33
sudo ip link set ens33 up
```

### Verify Configuration
```bash
ip addr show
ping 192.168.153.128  # Ping Kali system
```

## Kali Attack System Network Config

### Temporary Configuration
```bash
sudo ifconfig eth0 192.168.153.128 netmask 255.255.255.0 up
```

### Persistent Configuration

Edit `/etc/network/interfaces`:
```
auto eth0
iface eth0 inet static
    address 192.168.153.128
    netmask 255.255.255.0
```

Restart networking:
```bash
sudo systemctl restart networking
```

### Verify Configuration
```bash
ip addr show
ping 192.168.153.129  # Ping UbuntuRetryPAContinuebashcurl http://192.168.153.129  # Test Apache
Network Isolation Verification
Critical: Ensure No Internet Access
Why: Prevent accidental attacks on external systems
Test isolation:
bash# These should FAIL (no internet)
ping 8.8.8.8
ping google.com
curl http://example.com
````

**If you have internet access:**
- Disconnect default network adapter in VM settings
- Use only host-only network
- Verify isolation before testing

## VM Network Adapter Settings

### Ubuntu Target Server
````
Network Adapter 1: Host-only (VMnet1)
Connected: ✓
Connect at power on: ✓
````

### Kali Attack System
````
Network Adapter 1: Host-only (VMnet1)
Connected: ✓
Connect at power on: ✓
Connectivity Testing Matrix
TestCommandExpected ResultKali → Ubuntu (ping)ping 192.168.153.129SuccessUbuntu → Kali (ping)ping 192.168.153.128SuccessKali → Ubuntu (HTTP)curl http://192.168.153.129Apache pageEither → Internetping 8.8.8.8FAIL (isolated)
Troubleshooting
Issue: Cannot ping between VMs
Check:

Both VMs on same VMnet (VMnet1)
Both VMs have correct static IPs
Firewall not blocking ICMP

bash   # Temporarily disable Ubuntu firewall
   sudo ufw disable
````

### Issue: Can't access Apache from Kali

**Check:**
1. Apache is running: `sudo systemctl status apache2`
2. Apache listening on port 80: `sudo netstat -tlnp | grep :80`
3. Firewall allows HTTP: `sudo ufw allow 80/tcp`

### Issue: Still have internet access

**Fix:**
1. Remove NAT adapter from VM settings
2. Remove bridged adapter from VM settings
3. Keep only Host-only adapter
4. Restart VMs

## Network Diagram
````
┌─────────────────────────────────────────────────┐
│           Host Machine                          │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │      VMware Host-Only Network (VMnet1)    │  │
│  │      Network: 192.168.153.0/24            │  │
│  │                                           │  │
│  │  ┌─────────────────┐  ┌─────────────────┐│  │
│  │  │  Kali Linux     │  │  Ubuntu Server  ││  │
│  │  │  .128           │  │  .129           ││  │
│  │  │  (Attacker)     │  │  (Target)       ││  │
│  │  └─────────────────┘  └─────────────────┘│  │
│  │                                           │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ❌ No Internet Connection                      │
│  ❌ No External Network Access                  │
└─────────────────────────────────────────────────┘
````

## Security Checklist

Before starting attacks:

- [ ] Both VMs on host-only network
- [ ] Static IPs configured correctly
- [ ] No NAT or bridged adapters
- [ ] Cannot ping external IPs
- [ ] Apache accessible from Kali
- [ ] Network isolated from production systems
- [ ] Written authorization obtained
- [ ] Testing scope documented
````
