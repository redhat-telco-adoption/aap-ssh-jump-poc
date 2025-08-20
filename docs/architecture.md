# Architecture Overview

## Network Design

This project creates a 3-tier network architecture:

```
Internet → ALB (HTTPS) → AAP Controller
    ↓
[Public Subnet]
Bastion Host
    ↓
[AAP Private Subnet] 
AAP Controller + Execution Node + Jump Host
    ↓
[Managed Private Subnet]
Target Servers
```

## Security Model

- **Network Segmentation**: Private subnets with no direct internet access
- **Jump Host Architecture**: Secure bridge between AAP and managed environments
- **SSH Key Authentication**: No password authentication allowed
- **Security Groups**: Least-privilege firewall rules
- **SSL/TLS**: HTTPS access with valid certificates

## Component Roles

- **Bastion**: Administrative access point from internet
- **AAP Controller**: Web interface and API
- **Execution Node**: Job execution environment
- **Jump Host**: Network bridge with dual interfaces
- **Managed Nodes**: Automation targets
