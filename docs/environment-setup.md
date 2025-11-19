# Complete Environment Setup Guide

## Prerequisites

### Hardware Requirements
- **Host System:** 8GB RAM minimum (16GB recommended)
- **Disk Space:** 50GB free minimum
- **CPU:** Multi-core processor with VT-x/AMD-V enabled

### Software Requirements
- VMware Workstation 17+ (Windows/Linux) or VMware Fusion 13+ (Mac)
- [Kali Linux 2025.2 ISO](https://www.kali.org/get-kali/)
- [Ubuntu Server 24.04 ISO](https://ubuntu.com/download/server)

## Step 1: VMware Network Configuration

### Configure Host-Only Network

1. **Open Virtual Network Editor**
   - VMware Workstation: Edit → Virtual Network Editor
   - VMware Fusion: VMware Fusion → Preferences → Network

2. **Configure VMnet1**
````
   Network Name: VMnet1
   Type: Host-only
   Subnet IP: 192.168.153.0
   Subnet Mask: 255.255.255.0
   DHCP: Disabled

Apply Settings

Step 2: Create Ubuntu Target Server
VM Creation

Create New Virtual Machine

Configuration: Custom
Guest OS: Linux → Ubuntu 64-bit
Name: DDoS-Lab-Target


Configure Resources

Memory: 4GB (4096 MB)
Processors: 2 cores
Hard Disk: 20GB
Network: Host-only (VMnet1)


Install Ubuntu Server 24.04

Minimal installation
Install OpenSSH server
Username: student (or your choice)



Ubuntu Configuration
1. Update System
bashsudo apt update && sudo apt upgrade -y
2. Install Apache and Tools
bashsudo apt install -y apache2 apache2-utils net-tools iptables-persistent
3. Configure Static IP
Edit netplan configuration:
bashsudo nano /etc/netplan/00-installer-config.yaml
Add:
yamlnetwork:
  version: 2
  renderer: networkd
  ethernets:
    ens33:  # Use 'ip a' to find your interface name
      addresses:
        - 192.168.153.129/24
      dhcp4: no
Apply:
bashsudo netplan apply
4. Enable Apache
bashsudo systemctl enable apache2
sudo systemctl start apache2
sudo systemctl status apache2
5. Test Apache
bashcurl http://localhost
Step 3: Create Kali Attack System
VM Creation

Create New Virtual Machine

Configuration: Custom
Guest OS: Linux → Debian 10.x 64-bit
Name: DDoS-Lab-Attacker


Configure Resources

Memory: 4GB (4096 MB)
Processors: 2 cores
Hard Disk: 20GB
Network: Host-only (VMnet1)


Install Kali Linux 2025.2

Graphical install
Default desktop environment
Username: kali



Kali Configuration
1. Update System
bashsudo apt update && sudo apt upgrade -y
2. Install/Verify Tools
bashsudo apt install -y hping3 apache2-utils curl
3. Verify hping3
bashhping3 --version
4. Configure Static IP
Temporary:
bashsudo ifconfig eth0 192.168.153.128 netmask 255.255.255.0 up
Persistent:
bashsudo nano /etc/network/interfaces
````

Add:
````
auto eth0
iface eth0 inet static
    address 192.168.153.128
    netmask 255.255.255.0
5. Test Connectivity
bashping -c 3 192.168.153.129
curl http://192.168.153.129
Step 4: Clone Repository
On Both VMs
bash# Install git
sudo apt install -y git

# Clone repository
cd ~
git clone https://github.com/yourusername/ddos-defense-lab.git
cd ddos-defense-lab

# Make scripts executable
chmod +x attack/*.sh
chmod +x defense/*.sh
chmod +x testing/*.sh
chmod +x setup/*.sh
Step 5: Verify Setup
Network Connectivity Test
From Kali to Ubuntu:
bashping -c 3 192.168.153.129
curl http://192.168.153.129
From Ubuntu to Kali:
bashping -c 3 192.168.153.128
Isolation Test
From either VM (should FAIL):
bashping -c 3 8.8.8.8  # Should timeout
ping -c 3 google.com  # Should fail
✅ If external pings fail, network is properly isolated
Apache Test
From Kali:
bashab -n 10 -c 1 http://192.168.153.129/
Should show successful requests.
Step 6: Baseline Testing
On Kali System
bashcd ~/ddos-defense-lab/testing
./baseline-test.sh
Expected results:

Throughput: ~5000-6000 req/sec
Response time: <5ms
0 failed requests

Save these baseline metrics for comparison!
Step 7: Run Attack Test
Terminal 1 (Kali - Monitor)
bashcd ~/ddos-defense-lab/testing
./performance-testing.sh attack
Terminal 2 (Kali - Attack)
bashcd ~/ddos-defense-lab/attack
sudo ./hping3-commands.sh
Expected: Performance degradation on Terminal 1
Step 8: Implement Defense
On Ubuntu Target
bashcd ~/ddos-defense-lab/defense
sudo ./iptables-rules.sh
Test Defense Effectiveness
On Kali:
bashcd ~/ddos-defense-lab/testing
./performance-testing.sh defense
With attack still running from Terminal 2
Expected: Service maintained despite attack
Troubleshooting
Issue: VMs can't communicate
Solution:
bash# Ubuntu - Allow all traffic temporarily
sudo ufw disable

# Check IP addresses
ip addr show

# Verify both on 192.168.153.0/24 subnet
Issue: Apache not responding
Solution:
bash# Check Apache status
sudo systemctl status apache2

# Restart Apache
sudo systemctl restart apache2

# Check port 80
sudo netstat -tlnp | grep :80
Issue: hping3 command not found
Solution:
bash# Reinstall hping3
sudo apt update
sudo apt install -y hping3

# Verify installation
which hping3
hping3 --version
Issue: Permission denied on scripts
Solution:
bash# Make all scripts executable
cd ~/ddos-defense-lab
chmod +x attack/*.sh defense/*.sh testing/*.sh setup/*.sh
````

## VM Snapshots (Recommended)

### Create Snapshots for Quick Recovery

**Ubuntu Target:**
1. After initial setup: `Clean-Install`
2. After baseline test: `Baseline-Established`
3. With defense active: `Defense-Configured`

**Kali Attacker:**
1. After initial setup: `Clean-Install`
2. Before attacks: `Ready-to-Attack`

## Complete Setup Checklist

- [ ] VMware host-only network configured (192.168.153.0/24)
- [ ] Ubuntu VM created with 4GB RAM, 2 CPU
- [ ] Ubuntu has static IP: 192.168.153.129
- [ ] Apache2 installed and running on Ubuntu
- [ ] Kali VM created with 4GB RAM, 2 CPU
- [ ] Kali has static IP: 192.168.153.128
- [ ] hping3 installed and verified on Kali
- [ ] Both VMs can ping each other
- [ ] Neither VM can ping internet (isolated)
- [ ] Kali can access Apache on Ubuntu
- [ ] Repository cloned on both systems
- [ ] Baseline test completed successfully
- [ ] VM snapshots created

## Next Steps

Once setup is complete:

1. Review [attack documentation](../attack/attack-documentation.md)
2. Review [defense documentation](../defense/defense-documentation.md)
3. Read [MITRE ATT&CK mapping](mitre-attack-mapping.md)
4. Run controlled tests following the test plan

## Safety Reminders

⚠️ **Before starting any attacks:**
- Verify network isolation (no internet)
- Ensure written authorization
- Document testing scope
- Have incident response plan ready
- Monitor for unintended impact

---
