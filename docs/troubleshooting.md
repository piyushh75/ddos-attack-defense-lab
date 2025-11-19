# Troubleshooting Guide

## Quick Diagnostics Checklist

### Network Issues

**Problem: Cannot ping between VMs**
```bash
# On both VMs, check IP configuration
ip addr show

# Expected:
# Kali: 192.168.153.128/24
# Ubuntu: 192.168.153.129/24

# Check routing
ip route show

# Should only show local subnet, NO default gateway

# Test connectivity
ping -c 3 192.168.153.129  # From Kali
ping -c 3 192.168.153.128  # From Ubuntu
```

**Solution:**
```bash
# If IPs are wrong, reconfigure:
# Ubuntu
sudo nano /etc/netplan/00-installer-config.yaml
sudo netplan apply

# Kali (temporary)
sudo ifconfig eth0 192.168.153.128 netmask 255.255.255.0 up
```

---

**Problem: Can still ping internet (not isolated)**
```bash
# Test isolation
ping -c 3 8.8.8.8      # Should timeout
ping -c 3 google.com   # Should fail
```

**Solution:**
```bash
# In VMware settings for BOTH VMs:
# 1. Remove any NAT adapters
# 2. Remove any Bridged adapters
# 3. Keep ONLY Host-only adapter (VMnet1)
# 4. Restart VMs
```

---

### Apache Issues

**Problem: Cannot access Apache from Kali**
```bash
# On Ubuntu, check Apache status
sudo systemctl status apache2

# Check if listening on port 80
sudo netstat -tlnp | grep :80

# Test locally
curl http://localhost
```

**Solution:**
```bash
# If Apache not running
sudo systemctl start apache2
sudo systemctl enable apache2

# If port 80 not listening
sudo systemctl restart apache2

# Check firewall
sudo ufw status
sudo ufw allow 80/tcp  # If UFW is enabled

# Test from Ubuntu
curl http://192.168.153.129
```

---

**Problem: Apache keeps failing/crashing**
```bash
# Check error logs
sudo tail -50 /var/log/apache2/error.log

# Check system resources
free -h
df -h
top
```

**Solution:**
```bash
# Increase VM RAM if needed (4GB minimum)
# Check Apache configuration
sudo apache2ctl configtest

# If syntax errors, fix config
sudo nano /etc/apache2/apache2.conf

# Restart Apache
sudo systemctl restart apache2
```

---

### iptables Issues

**Problem: iptables rules not blocking attacks**
```bash
# Check if rules are active
sudo iptables -L INPUT -n -v --line-numbers

# Check statistics
sudo iptables -L INPUT -n -v | grep DROP
```

**Solution:**
```bash
# Reapply rules
cd ~/ddos-defense-lab/defense
sudo ./iptables-rules.sh

# Verify order matters
sudo iptables -L INPUT -n -v --line-numbers

# Rules should be in order:
# 1. Rate limit (ACCEPT)
# 2. Connection limit (DROP)
# 3. Default DROP
```

---

**Problem: iptables blocking legitimate traffic**
```bash
# Check dropped packet count
sudo iptables -L INPUT -n -v

# Test with defense temporarily disabled
sudo ./iptables-reset.sh
ab -n 100 -c 10 http://192.168.153.129/
```

**Solution:**
```bash
# Increase rate limits
sudo iptables -R INPUT 1 -p tcp --dport 80 -m state --state NEW \
    -m limit --limit 100/minute --limit-burst 50 -j ACCEPT

# Increase connection limits
sudo iptables -R INPUT 2 -p tcp --dport 80 -m connlimit \
    --connlimit-above 20 -j DROP
```

---

**Problem: iptables rules disappear after reboot**
```bash
# Check if rules persist
sudo reboot
# After reboot:
sudo iptables -L -n -v
```

**Solution:**
```bash
# Install persistence package
sudo apt-get install iptables-persistent

# Save rules
sudo netfilter-persistent save

# Or manually save
sudo iptables-save > /etc/iptables/rules.v4
```

---

### Attack Script Issues

**Problem: hping3 command not found**
```bash
# Check if installed
which hping3
hping3 --version
```

**Solution:**
```bash
# Install hping3
sudo apt update
sudo apt install -y hping3

# Verify installation
hping3 --version
```

---

**Problem: hping3 says "Permission denied"**
```bash
# hping3 requires root
sudo ./hping3-commands.sh
```

**Solution:**
```bash
# Always run with sudo
cd ~/ddos-defense-lab/attack
sudo ./hping3-commands.sh

# Or add to sudoers (not recommended for production)
```

---

**Problem: Attack not impacting target**
```bash
# Check if packets reaching target
# On Ubuntu:
sudo tcpdump -i ens33 port 80 -c 100

# Should see flood of SYN packets
```

**Solution:**
```bash
# Verify attack parameters
hping3 -S -c 10000 --flood -I u100 -p 80 192.168.153.129

# Increase intensity if needed
hping3 -S --flood -p 80 192.168.153.129  # Remove packet limit

# Check target resources
# On Ubuntu:
top  # Should show increased load
netstat -ant | grep SYN_RECV | wc -l  # Should show many
```

---

### Performance Testing Issues

**Problem: Apache Bench (ab) fails**
```bash
# Error: "apr_socket_recv: Connection reset by peer"
```

**Solution:**
```bash
# Reduce concurrency
ab -n 1000 -c 5 http://192.168.153.129/

# Increase Apache MaxRequestWorkers
sudo nano /etc/apache2/mods-available/mpm_prefork.conf
# Increase MaxRequestWorkers to 250

sudo systemctl restart apache2
```

---

**Problem: Inconsistent test results**
```bash
# Results vary significantly between runs
```

**Solution:**
```bash
# Run multiple tests and average
for i in {1..5}; do
    echo "Test $i:"
    ab -n 1000 -c 10 http://192.168.153.129/ 2>&1 | grep "Requests per second"
    sleep 5
done

# Ensure no other processes running
# On Ubuntu:
top  # Check for other heavy processes
```

---

### Script Execution Issues

**Problem: "Permission denied" on scripts**
```bash
bash: ./script.sh: Permission denied
```

**Solution:**
```bash
# Make scripts executable
chmod +x attack/*.sh
chmod +x defense/*.sh
chmod +x testing/*.sh
chmod +x setup/*.sh

# Or run with bash
bash ./script.sh
```

---

**Problem: "Command not found" errors in scripts**
```bash
# Script fails with "ab: command not found"
```

**Solution:**
```bash
# Install missing tools
sudo apt update
sudo apt install -y apache2-utils  # for ab
sudo apt install -y hping3          # for hping3
sudo apt install -y net-tools       # for netstat
```

---

### VM Performance Issues

**Problem: VMs running slow**
```bash
# Check host resources
# Windows: Task Manager
# Mac: Activity Monitor
# Linux: htop
```

**Solution:**
```bash
# Increase VM resources
# In VMware:
# 1. Shut down VM
# 2. Edit Settings
# 3. Increase RAM to 4GB+
# 4. Increase CPU to 2+ cores
# 5. Start VM

# Disable unnecessary services
# On Ubuntu:
sudo systemctl disable bluetooth
sudo systemctl disable cups
```

---

**Problem: VMs won't start**
```bash
# Error: "The virtual machine cannot be powered on"
```

**Solution:**
```bash
# Check:
# 1. Enough disk space on host
# 2. VT-x/AMD-V enabled in BIOS
# 3. No other hypervisors running
# 4. VMware services running

# Windows:
services.msc  # Check VMware services

# Try:
# - Restart host computer
# - Reinstall VMware Tools
# - Check VM file integrity
```

---

## Error Messages and Solutions

### Error: "Cannot allocate memory"
```bash
# In attack script or system logs
```

**Cause:** System running out of RAM

**Solution:**
```bash
# Free up memory
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'

# Or increase VM RAM allocation
```

---

### Error: "Connection refused"
```bash
# When testing Apache
curl: (7) Failed to connect to 192.168.153.129 port 80: Connection refused
```

**Cause:** Apache not running or firewall blocking

**Solution:**
```bash
# Start Apache
sudo systemctl start apache2

# Check firewall
sudo iptables -L -n | grep 80
sudo ufw status

# Allow port 80
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
```

---

### Error: "Address already in use"
```bash
# When starting Apache
(98)Address already in use: AH00072: make_sock: could not bind to address
```

**Cause:** Another process using port 80

**Solution:**
```bash
# Find what's using port 80
sudo lsof -i :80
sudo netstat -tlnp | grep :80

# Kill the process
sudo kill 

# Or change Apache port
sudo nano /etc/apache2/ports.conf
# Change Listen 80 to Listen 8080
```

---

### Error: "No route to host"
```bash
# When pinging or connecting
ping: connect: No route to host
```

**Cause:** Network misconfiguration

**Solution:**
```bash
# Check routing table
ip route show

# Should only show local subnet
# Add route if missing
sudo ip route add 192.168.153.0/24 dev ens33

# Check if interface is up
ip link show
sudo ip link set ens33 up
```

---

## Performance Troubleshooting

### Attack Not Effective Enough

**Expected:** 50%+ performance degradation  
**Actual:** <20% degradation

**Solutions:**
```bash
# 1. Increase packet rate
hping3 -S --flood -p 80 192.168.153.129  # Remove rate limit

# 2. Increase packet count
hping3 -S -c 100000 --flood -p 80 192.168.153.129

# 3. Target multiple ports
hping3 -S --flood -p ++1 192.168.153.129  # Increment port

# 4. Verify packets reaching target
# On Ubuntu:
sudo tcpdump -i ens33 'tcp[tcpflags] & tcp-syn != 0' -c 100
```

---

### Defense Too Aggressive

**Expected:** Some legitimate traffic  
**Actual:** All traffic blocked

**Solutions:**
```bash
# Relax rate limits
sudo iptables -R INPUT 1 -p tcp --dport 80 -m state --state NEW \
    -m limit --limit 100/minute --limit-burst 50 -j ACCEPT

# Increase connection limits
sudo iptables -R INPUT 2 -p tcp --dport 80 -m connlimit \
    --connlimit-above 30 -j DROP

# Remove default DROP temporarily
sudo iptables -D INPUT 3
```

---

### Defense Not Effective Enough

**Expected:** Service maintained  
**Actual:** Still degraded

**Solutions:**
```bash
# 1. Enable SYN cookies
sudo sysctl -w net.ipv4.tcp_syncookies=1

# 2. Reduce SYN timeout
sudo sysctl -w net.ipv4.tcp_syn_retries=1

# 3. Add more restrictive rules
sudo iptables -I INPUT 1 -p tcp --dport 80 -m state --state NEW \
    -m limit --limit 25/minute --limit-burst 10 -j ACCEPT

# 4. Block source IP entirely (last resort)
sudo iptables -I INPUT 1 -s 192.168.153.128 -j DROP
```

---

## Data Collection Issues

### Results Files Empty/Missing
```bash
# Check if directory exists
ls -la ~/ddos-defense-lab/results/
```

**Solution:**
```bash
# Create directory
mkdir -p ~/ddos-defense-lab/results

# Run test again
cd ~/ddos-defense-lab/testing
./baseline-test.sh

# Check permissions
ls -l results/
chmod 755 results/
```

---

### Can't Parse Test Results
```bash
# Script can't extract metrics
```

**Solution:**
```bash
# Manually check result file
cat results/baseline-performance.txt

# Look for these lines:
grep "Requests per second:" results/baseline-performance.txt
grep "Time per request:" results/baseline-performance.txt
grep "Transfer rate:" results/baseline-performance.txt

# If missing, ab command may have failed
# Check for errors in output
```

---

## Recovery Procedures

### Complete Reset
```bash
# Reset everything to clean state

# 1. Stop all attacks
# Press Ctrl+C in attack terminal

# 2. Reset iptables
cd ~/ddos-defense-lab/defense
sudo ./iptables-reset.sh

# 3. Restart Apache
sudo systemctl restart apache2

# 4. Clear logs
sudo truncate -s 0 /var/log/apache2/access.log
sudo truncate -s 0 /var/log/apache2/error.log

# 5. Verify baseline
cd ~/ddos-defense-lab/testing
./baseline-test.sh
```

---

### Revert to Snapshot
```bash
# VMware Workstation:
# 1. VM → Snapshot → Snapshot Manager
# 2. Select snapshot
# 3. Click "Go To"

# Or via command line:
vmrun revertToSnapshot "/path/to/vm.vmx" "snapshot-name"
```

---

### Emergency Stop
```bash
# If something goes wrong:

# 1. Stop attack immediately
killall hping3

# 2. Check system status
top
netstat -ant | wc -l

# 3. Reset firewall
sudo iptables -F
sudo iptables -P INPUT ACCEPT

# 4. Restart services
sudo systemctl restart apache2
sudo systemctl restart networking

# 5. Reboot if needed
sudo reboot
```

---

## Prevention Tips

### Before Each Test
```bash
# Checklist:
# [ ] VMs have sufficient resources
# [ ] Network isolation verified
# [ ] Services running normally
# [ ] Snapshots taken
# [ ] Baseline metrics recorded
# [ ] Monitoring tools ready
```

### Best Practices

1. **Always take snapshots before testing**
2. **Test one thing at a time**
3. **Document everything**
4. **Monitor system resources**
5. **Have recovery plan ready**
6. **Stay within authorized scope**
7. **Keep detailed logs**

---

## Getting Help

### Information to Collect

When seeking help, provide:
```bash
# 1. System information
uname -a
cat /etc/os-release

# 2. Network configuration
ip addr show
ip route show

# 3. Service status
sudo systemctl status apache2
sudo iptables -L -n -v

# 4. Error messages
sudo tail -50 /var/log/apache2/error.log
sudo tail -50 /var/log/syslog

# 5. Test results
cat resultsRetryPAContinue/*.txt
6. VM configuration
VMware: VM → Settings → Hardware
Note RAM, CPU, Network adapter settings

### Where to Get Help

**Project Resources:**
- GitHub Issues: https://github.com/yourusername/ddos-defense-lab/issues
- Documentation: All files in `docs/` directory
- README: Complete overview and quick start

**External Resources:**
- Apache Documentation: https://httpd.apache.org/docs/
- iptables Tutorial: https://www.netfilter.org/documentation/
- VMware KB: https://kb.vmware.com/
- Ubuntu Forums: https://ubuntuforums.org/
- Kali Forums: https://forums.kali.org/

**Security Communities:**
- /r/AskNetsec (Reddit)
- Security Stack Exchange
- SANS Reading Room
- OWASP Resources

---

## Advanced Troubleshooting

### Packet Capture Analysis

**Problem:** Need to see what's actually happening on the network
```bash
# On Ubuntu target, capture packets
sudo tcpdump -i ens33 -w capture.pcap port 80

# Run test for 30 seconds, then stop (Ctrl+C)

# Analyze with tcpdump
sudo tcpdump -r capture.pcap | head -50

# Or copy to Kali and use Wireshark
# On Ubuntu:
scp capture.pcap kali@192.168.153.128:/tmp/

# On Kali:
wireshark /tmp/capture.pcap
```

**What to Look For:**
- High number of SYN packets
- SYN packets without corresponding ACK
- Repeated packets from same source
- Response time patterns

---

### System Resource Analysis

**Problem:** Need to understand resource bottleneck
```bash
# Monitor in real-time
# Terminal 1: System resources
watch -n 1 'free -h && echo "---" && df -h && echo "---" && uptime'

# Terminal 2: Network connections
watch -n 1 'netstat -ant | grep :80 | wc -l'

# Terminal 3: Apache status
watch -n 1 'sudo systemctl status apache2 | head -20'

# Log to file for analysis
while true; do
    echo "$(date): $(netstat -ant | grep :80 | wc -l) connections" >> /tmp/monitoring.log
    sleep 1
done
```

**Identify Bottlenecks:**
```bash
# CPU bottleneck: top shows >90% CPU
# Memory bottleneck: free shows low available memory
# Network bottleneck: ifconfig shows high errors/drops
# Connection bottleneck: netstat shows many TIME_WAIT
```

---

### iptables Rule Debugging

**Problem:** Rules not behaving as expected
```bash
# Enable verbose logging
sudo iptables -I INPUT 1 -p tcp --dport 80 -j LOG \
    --log-prefix "DEBUG-80: " --log-level 4

# Watch logs in real-time
sudo tail -f /var/log/syslog | grep "DEBUG-80"

# Run test and observe which rules trigger

# Disable logging when done
sudo iptables -D INPUT 1
```

**Trace packet through rules:**
```bash
# Show rule numbers
sudo iptables -L INPUT -n -v --line-numbers

# Check which rule caught packet
# High packet count = rule is matching
# Zero packet count = rule never triggered

# Test specific rule
sudo iptables -I INPUT 1 -p tcp --dport 80 -j LOG
# Packet should appear in logs if it reaches this rule
```

---

### Apache Connection Pool Analysis

**Problem:** Understanding Apache connection handling
```bash
# Check Apache status
sudo apache2ctl status

# View detailed server status (if mod_status enabled)
curl http://localhost/server-status

# Count worker processes
ps aux | grep apache2 | grep -v grep | wc -l

# View Apache configuration
apache2ctl -t -D DUMP_VHOSTS
apache2ctl -t -D DUMP_MODULES
```

**Enable mod_status for detailed metrics:**
```bash
# Enable module
sudo a2enmod status

# Configure
sudo nano /etc/apache2/mods-available/status.conf

# Add:
<Location "/server-status">
    SetHandler server-status
    Require ip 192.168.153.0/24
</Location>

sudo systemctl restart apache2

# View status
curl http://192.168.153.129/server-status
```

---

### Kernel Parameter Tuning

**Problem:** System not handling connections well
```bash
# View current TCP settings
sysctl -a | grep tcp

# Key parameters for DDoS protection:
sysctl net.ipv4.tcp_syncookies          # Should be 1
sysctl net.ipv4.tcp_max_syn_backlog     # Increase from default
sysctl net.ipv4.tcp_syn_retries         # Reduce to 1 or 2
sysctl net.core.somaxconn               # Increase for high load

# Tune for better DDoS resistance
sudo sysctl -w net.ipv4.tcp_syncookies=1
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=4096
sudo sysctl -w net.ipv4.tcp_syn_retries=1
sudo sysctl -w net.ipv4.tcp_synack_retries=1
sudo sysctl -w net.core.somaxconn=1024

# Make permanent
sudo nano /etc/sysctl.conf
# Add above settings

# Apply
sudo sysctl -p
```

---

### Database of Known Issues

#### Issue #1: VMware Tools Missing

**Symptoms:**
- Sluggish VM performance
- Mouse integration not working
- Clipboard not working

**Solution:**
```bash
# Ubuntu
sudo apt install open-vm-tools

# Kali
sudo apt install open-vm-tools-desktop

# Restart VM
sudo reboot
```

---

#### Issue #2: Time Synchronization

**Symptoms:**
- Timestamps in logs incorrect
- SSL certificate errors

**Solution:**
```bash
# Install NTP (if needed in isolated environment)
sudo apt install chrony

# Or sync with host
# VMware: VM → Settings → Options → VMware Tools
# Enable: Synchronize guest time with host

# Manual sync
sudo date -s "$(date)"
```

---

#### Issue #3: Disk Space Full

**Symptoms:**
- Cannot write files
- Services failing to start
- "No space left on device" errors

**Solution:**
```bash
# Check disk usage
df -h

# Find large files
du -sh /* | sort -rh | head -10

# Clean up logs
sudo journalctl --vacuum-time=2d
sudo truncate -s 0 /var/log/apache2/*.log

# Clean package cache
sudo apt clean
sudo apt autoremove

# Increase disk size (if needed)
# VMware: VM → Settings → Hard Disk → Expand
# Then in Linux:
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
```

---

#### Issue #4: DNS Resolution Fails

**Symptoms:**
- Cannot resolve hostnames
- apt update fails

**Solution:**
```bash
# This lab should NOT have DNS (isolated network)
# But if needed for setup:

# Temporary DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Or configure static
sudo nano /etc/systemd/resolved.conf
# Add: DNS=8.8.8.8

sudo systemctl restart systemd-resolved

# Remember: Remove DNS before testing (isolation)
```

---

## Testing Validation

### How to Know Everything is Working

**Step 1: Network Validation**
```bash
# From Kali
ping -c 3 192.168.153.129          # Should succeed
ping -c 3 8.8.8.8                  # Should FAIL (timeout)
curl http://192.168.153.129        # Should show Apache page

# Expected: Local connectivity works, internet doesn't
```

**Step 2: Service Validation**
```bash
# On Ubuntu
sudo systemctl status apache2      # Should be "active (running)"
sudo netstat -tlnp | grep :80      # Should show Apache listening
curl http://localhost              # Should show Apache page

# Expected: Apache running and responding
```

**Step 3: Attack Validation**
```bash
# From Kali
sudo hping3 -S -c 100 -p 80 192.168.153.129

# On Ubuntu (while attack running)
netstat -ant | grep SYN_RECV | wc -l  # Should show > 0

# Expected: SYN packets reaching target
```

**Step 4: Defense Validation**
```bash
# On Ubuntu
sudo iptables -L INPUT -n -v --line-numbers

# Expected output:
# Chain INPUT (policy ACCEPT)
# 1  <packets>  ACCEPT  tcp -- * * 0.0.0.0/0  0.0.0.0/0  tcp dpt:80 state NEW limit: avg 50/min burst 20
# 2  <packets>  DROP    tcp -- * * 0.0.0.0/0  0.0.0.0/0  tcp dpt:80 #conn src/32 > 10
# 3  <packets>  DROP    tcp -- * * 0.0.0.0/0  0.0.0.0/0  tcp dpt:80

# Run attack and check drop counts increase
watch -n 1 'sudo iptables -L INPUT -n -v | grep DROP'

# Expected: Drop counters incrementing
```

**Step 5: Performance Validation**
```bash
# Baseline test
cd ~/ddos-defense-lab/testing
./baseline-test.sh

# Expected: ~5000-6000 req/sec, <5ms response

# Attack test
# Terminal 1: Start attack
cd ~/ddos-defense-lab/attack
sudo ./hping3-commands.sh

# Terminal 2: Test performance
cd ~/ddos-defense-lab/testing
./performance-testing.sh attack

# Expected: ~2000-3000 req/sec (degradation)

# Defense test
# Keep attack running
# Apply defense on Ubuntu
cd ~/ddos-defense-lab/defense
sudo ./iptables-rules.sh

# Test performance again
cd ~/ddos-defense-lab/testing
./performance-testing.sh defense

# Expected: ~300-500 req/sec (service maintained)
```

---

## Diagnostic Scripts

### Quick System Check

Create `check-system.sh`:
```bash
#!/bin/bash

echo "=== DDoS Lab System Check ==="
echo ""

echo "1. Network Configuration:"
ip addr show | grep "inet " | grep -v "127.0.0.1"
echo ""

echo "2. Apache Status:"
systemctl is-active apache2 && echo "✓ Running" || echo "✗ Not running"
echo ""

echo "3. Apache Port:"
netstat -tlnp 2>/dev/null | grep :80 && echo "✓ Listening" || echo "✗ Not listening"
echo ""

echo "4. iptables Rules:"
iptables -L INPUT -n | grep -q "tcp dpt:80" && echo "✓ Rules active" || echo "✗ No rules"
echo ""

echo "5. Disk Space:"
df -h / | tail -1 | awk '{print $5 " used"}'
echo ""

echo "6. Memory:"
free -h | grep Mem | awk '{print $3 "/" $2 " used"}'
echo ""

echo "7. Connectivity to Target:"
ping -c 1 -W 2 192.168.153.129 &>/dev/null && echo "✓ Can reach target" || echo "✗ Cannot reach target"
echo ""

echo "8. Internet Isolation:"
ping -c 1 -W 2 8.8.8.8 &>/dev/null && echo "✗ WARNING: Has internet" || echo "✓ Properly isolated"
```

Run with:
```bash
chmod +x check-system.sh
./check-system.sh
```

---

### Connection Monitor Script

Create `monitor-connections.sh`:
```bash
#!/bin/bash

echo "Connection Monitor - Press Ctrl+C to stop"
echo "Time,Total,ESTABLISHED,SYN_RECV,TIME_WAIT"

while true; do
    timestamp=$(date +%H:%M:%S)
    total=$(netstat -ant | grep :80 | wc -l)
    established=$(netstat -ant | grep :80 | grep ESTABLISHED | wc -l)
    syn_recv=$(netstat -ant | grep :80 | grep SYN_RECV | wc -l)
    time_wait=$(netstat -ant | grep :80 | grep TIME_WAIT | wc -l)
    
    echo "$timestamp,$total,$established,$syn_recv,$time_wait"
    sleep 1
done
```

Run with:
```bash
chmod +x monitor-connections.sh
./monitor-connections.sh | tee /tmp/connections.log
```

---

## FAQ - Frequently Asked Questions

**Q: Why is my baseline performance different from the documented 5,487 req/sec?**

A: Performance varies based on:
- Host machine CPU/RAM
- VM resource allocation
- Background processes
- Network configuration
Your baseline may be 3,000-7,000 req/sec. Use YOUR baseline for comparison.

---

**Q: Can I run this on a single VM?**

A: No. You need separate attacker and target VMs to properly simulate a real attack scenario and maintain proper network isolation.

---

**Q: Can I connect these VMs to the internet?**

A: Only during initial setup for updates. During testing, VMs MUST be isolated to prevent accidental attacks on external systems. This is a legal and ethical requirement.

---

**Q: Why does defense reduce performance by 90%?**

A: iptables processes every packet through multiple rules, which adds overhead. This is normal and acceptable - the goal is service continuity, not optimal performance during an attack.

---

**Q: Can I use this against real websites?**

A: **NO.** This is ILLEGAL without explicit written authorization. Use only in isolated lab environments. Unauthorized DDoS attacks are federal crimes.

---

**Q: How do I make the attack more effective?**

A: Increase packet rate, remove packet count limit, use multiple attack sources, combine attack vectors. However, remember this is for education - real attacks cause harm.

---

**Q: Why do test results vary between runs?**

A: Normal variation due to:
- System state (cache, buffers)
- Background processes
- Network timing
- VM resource contention
Run multiple tests and average results.

---

**Q: Should I run this on my work network?**

A: **NO.** Always use isolated lab environment. Get written authorization before any security testing on any network.

---

**Q: How do I cite this project in academic work?**

A:
Arora, P. (2024). DDoS Attack & Defense Testing Laboratory.
GitHub repository. https://github.com/yourusername/ddos-defense-lab

---

**Q: Can I modify these scripts for my own research?**

A: Yes! The project is open source (MIT License). Fork it, modify it, improve it. Just maintain ethical use standards and give credit.

---

## Emergency Contacts

**If something goes seriously wrong:**

1. **Stop everything immediately**
   - Ctrl+C all running processes
   - Power off VMs if needed

2. **Document what happened**
   - Screenshot errors
   - Save log files
   - Note what you were doing

3. **Restore from snapshot**
   - Revert to last known good state
   - Verify system functionality

4. **Seek help if needed**
   - GitHub Issues (for project problems)
   - Security forums (for technique questions)
   - Instructor/supervisor (for academic guidance)

---

## Troubleshooting Checklist

Print this and keep handy:
PRE-TEST CHECKLIST:
[ ] VMs have sufficient resources (4GB RAM, 2 CPU each)
[ ] Network isolation verified (cannot ping internet)
[ ] Both VMs can communicate (ping each other)
[ ] Apache running on Ubuntu (systemctl status apache2)
[ ] Baseline test completed successfully
[ ] Snapshots taken (can revert if needed)
[ ] Monitoring tools ready
[ ] Documentation accessible
DURING TEST:
[ ] Monitoring system resources
[ ] Logging all activities
[ ] Staying within scope
[ ] Ready to emergency stop if needed
POST-TEST:
[ ] Attack stopped
[ ] Defense reset (if applicable)
[ ] Logs saved
[ ] Results documented
[ ] System returned to clean state
[ ] Analysis completed

---

## Final Notes

**Remember:**
- **Safety First**: Always work in isolated environment
- **Document Everything**: Logs help troubleshoot and learn
- **Start Simple**: Master basics before advanced techniques
- **Ask for Help**: No shame in getting stuck
- **Stay Ethical**: Never attack systems without authorization

**When in Doubt:**
1. Stop what you're doing
2. Revert to snapshot
3. Review documentation
4. Ask for help
5. Don't try random things

---

**Good luck with your testing!** 🛡️

---

**Document Version:** 1.0  
**Last Updated:** November 2024  
**Maintained By:** DDoS Defense Lab Project

**For additional support:**
- GitHub Issues: Report bugs and problems
- Documentation: Complete guides in `docs/` folder
- README: Quick start and overview
