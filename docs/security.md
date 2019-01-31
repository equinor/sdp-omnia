# Security considerations
This document describes some of the security considerations that have gone into SDP's AKS deployment.  
We have identified four main levels of concern that are, to a degree, unique to the AKS/Kubernetes technologies: 
- The Azure Portal
- The AKS Nodes
- Kubernetes and Cluster Supporting Services
- Pods and Applications.  

For each of these levels we will describe the main threats, and the most important security measures to remedy these threats.  
The CIS(Center for Internet Security) Benchmarks have been used as a guideline for this work. Primarily the "CIS Benchmark for Ubuntu Linux 16.04 LTS", the "CIS Benchmark for Containers", and the "CIS Benchmark for Kubernetes".

## Azure Portal
### Threats
* Accidental deletion/misconfiguration of resources or entire cluster
* Unauthorized access to Azure resources
### Measures
* Own Azure subscription for SDP admins.
  * TODO: Limit user in the "SDP Tools" subscriptions, or get own subscriptions. 
* Equinor security standard for Azure Portal/az CLI login (Equinor organization + Two-factor authentication(2FA))

## AKS Nodes
### Threats
* Not hardened from Azure by default
  * Not restarted by default to get latest security patches
  * Missing minimum security settings/features
* If somebody get access to the VNET the default security is not sufficient
  * Big attack surface


### Measures
* !TODO: Disabled/uninstalled all unnecessary services
* !Confirm: Removed unnecessary users
* The K8s cluster runs in a virtual network protected by a Azure Network Security Group firewall. This firewall only allows ports 80 and 443 inbound.
* Automatic security patches from Azure.
  * !TODO: Update manually packages that are not upated by Azure.
  * Automatically reboots if nessecary to apply security updates.
* !TODO: local Firewall
* !TODO: Filter and monitor audit logs. Log events that modify date&time, user&groups, AppArmor, login&logout, access rights, unsuccessful authorization, docker files
* !TODO: Ensure file permissions. Eg. /etc/passwd, /etc/shadow, /etc/crontab
* !Confirm: Restrict traffic between containers (Docker daemon)
* !Investigate: Enforce AppArmor

## Kubernetes and Cluster Supporting Services

Services: Helm, flux, puppet, github, ark, kured, sealed secrets, azure dns, azure container registry, azure AD

### Threats
* Access to GitHub repo - flux and puppet
* Access to Azure container registry
* Compromised cluster access keys
* Compromised private key for sealed secrets
* Vulnerabilities in Kubernetes and services

### Measures
* Master nodes w/cluster services in AKS is fully managed by Azure.  
* TODO: RBAC - Look into service account improvements
* Keep up-to-date
* !Consider: NetworkPolicies
* TODO: Don't allow dangerous runtime options. This include mounting the docker socket, using priviliged flag, --pid=host, --network=host, --device. This can be done with PodSecurityPolicy
* TODO: Ensure kubelet configuration files permissions
* Consider: NetworkPolicies

## Pods and Applications
### Threats
* 
### Measures
* Secrets stored as SealedSecrets in Github
* TODO: Don't use latest tags
* Consider: Pod Security (Is this the same as docker run's --security-opt where you can specify an AppArmor profile?)
* !TODO: Set resource limits for all pods
* Untrusted Images
* Vulnerability scanned images
* Untrusted HelmCharts




## BOYH CIS Ubuntu ##
Link til doc: https://neprisstore.blob.core.windows.net/sessiondocs/doc_8ac75a77-40a4-4e08-a6c0-93b39b92abd8.pdf

# Burde gjøres
- 1.1.1 - DIsable unused filesystems (Scored)
- 1.1.2 Ensure separate partition exist for /tmp (Scored)
- 1.1.21 Disable Automounting (Scored)

- 1.3.1 Ensure AIDE is installed (Scored)
- 1.3.2 Ensure filesystem integrity is regularly checked (Scored)

- 1.4.1 Ensure permissions on bootloader config are configured (Scored)

- 1.5.4 Ensure prelink is disabled (Scored)

- 1.7.1 Command Line Warning Banners

- 1.8 Ensure updates, patches, and additional security software are installed (Not Scored)

- 2.1.1 Ensure chargen services are not enabled (Scored)
- 2.1.2 Ensure daytime services are not enabled (Scored)
- 2.1.3 Ensure discard services are not enabled (Scored)
- 2.1.4 Ensure echo services are not enabled (Scored)
- 2.1.5 Ensure time services are not enabled (Scored)
- 2.1.6 Ensure rsh server is not enabled (Scored)
- 2.1.7 Ensure talk server is not enabled (Scored)
- 2.1.8 Ensure telnet server is not enabled (Scored)
- 2.1.9 Ensure tftp server is not enabled (Scored)

- 2.2.1.1 Ensure time synchronization is in use (Not Scored)
- 2.2.1.2 Ensure ntp is configured (Scored)
- 2.2.2 Ensure X Window System is not installed (Scored)
- 2.2.3 Ensure Avahi Server is not enabled (Scored)
- 2.2.4 Ensure CUPS is not enabled (Scored)
- 2.2.5 Ensure DHCP Server is not enabled (Scored)
- 2.2.6 Ensure LDAP server is not enabled (Scored)
- 2.2.8 Ensure DNS Server is not enabled (Scored)
- 2.2.9 Ensure FTP Server is not enabled (Scored)
- 2.2.10 Ensure HTTP server is not enabled (Scored)
- 2.2.11 Ensure IMAP and POP3 server is not enabled (Scored)
- 2.2.12 Ensure Samba is not enabled (Scored)
- 2.2.13 Ensure HTTP Proxy Server is not enabled (Scored)
- 2.2.14 Ensure SNMP Server is not enabled (Scored)
- 2.2.15 Ensure mail transfer agent is configured for local-only mode (Scored)
- 2.2.16 Ensure rsync service is not enabled (Scored)
- 2.2.17 Ensure NIS Server is not enabled (Scored)

- 2.3.1 Ensure NIS Client is not installed (Scored)
- 2.3.2 Ensure rsh client is not installed (Scored)
- 2.3.3 Ensure talk client is not installed (Scored)
- 2.3.4 Ensure telnet client is not installed (Scored)
- 2.3.5 Ensure LDAP client is not installed (Scored)

- 3.2.2 Ensure ICMP redirects are not accepted (Scored)
- 3.2.3 Ensure secure ICMP redirects are not accepted (Scored)
- 3.2.4 Ensure suspicious packets are logged (Scored)
- 3.2.5 Ensure broadcast ICMP requests are ignored (Scored)
- 3.2.6 Ensure bogus ICMP responses are ignored (Scored)
- 3.2.8 Ensure TCP SYN Cookies is enabled (Scored)

- 3.3.1 Ensure IPv6 router advertisements are not accepted (Not Scored)
- 3.3.2 Ensure IPv6 redirects are not accepted (Not Scored)

- 3.5 Uncommon Network Protocols

- 3.6 Firewall Configuration

- 4.1.1.1 Ensure audit log storage size is configured (Not Scored)
- 4.1.2 Ensure auditd service is enabled (Scored)
- 4.1.4 Ensure events that modify date and time information are collected (Scored)
- 4.1.5 Ensure events that modify user/group information are collected (Scored)
- 4.1.6 Ensure events that modify the system's network environment are collected (Scored)
- 4.1.7 Ensure events that modify the system's Mandatory Access Controls are collected (Scored)
- 4.1.8 Ensure login and logout events are collected (Scored)
- 4.1.11 Ensure unsuccessful unauthorized file access attempts are collected (Scored)
- 4.1.12 Ensure use of privileged commands is collected (Scored)
- 4.1.14 Ensure file deletion events by users are collected (Scored)
- 4.1.15 Ensure changes to system administration scope (sudoers) is collected (Scored)
- 4.1.16 Ensure system administrator actions (sudolog) are collected (Scored)
- 4.1.17 Ensure kernel module loading and unloading is collected (Scored)

- 4.2.4 Ensure permissions on all logfiles are configured (Scored)

- 4.3 Ensure logrotate is configured (Not Scored)

- 5.1 Configure cron

- 5.2 Configure SSH

- 5.4.2 Ensure system accounts are non-login (Scored)
- 5.4.3 Ensure default group for the root account is GID 0 (Scored)
- 5.4.4 Ensure default user umask is 027 or more restrictive (Scored)

- 6.1.2 Ensure permissions on /etc/passwd are configured (Scored)
- 6.1.3 Ensure permissions on /etc/shadow are configured (Scored)
- 6.1.4 Ensure permissions on /etc/group are configured (Scored)
- 6.1.5 Ensure permissions on /etc/gshadow are configured (Scored)
- 6.1.6 Ensure permissions on /etc/passwd- are configured (Scored)
- 6.1.7 Ensure permissions on /etc/shadow- are configured (Scored)
- 6.1.8 Ensure permissions on /etc/group- are configured (Scored)
- 6.1.9 Ensure permissions on /etc/gshadow- are configured (Scored)

- 6.2.5 Ensure root is the only UID 0 account (Scored)
- 6.2.6 Ensure root PATH Integrity (Scored)
- 6.2.7 Ensure all users' home directories exist (Scored)
- 6.2.8 Ensure users' home directories permissions are 750 or more restrictive (Scored)
- 6.2.9 Ensure users own their home directories (Scored)
- 6.2.10 Ensure users' dot files are not group or world writable (Scored)
- 6.2.11 Ensure no users have .forward files (Scored)
- 6.2.12 Ensure no users have .netrc files (Scored)
- 6.2.13 Ensure users' .netrc Files are not group or world accessible (Scored)
- 6.2.14 Ensure no users have .rhosts files (Scored)
- 6.2.15 Ensure all groups in /etc/passwd exist in /etc/group (Scored)

# Kan gjøres / Bør vurderes
- 1.1.3 Ensure nodev option set on /tmp partition (Scored)
- 1.1.4 Ensure nosuid option set on /tmp partition (Scored)
- 1.1.10 Ensure separate partition exists for /var/log (Scored)
- 1.1.11 Ensure separate partition exists for /var/log/audit (Scored)
- 1.1.12 Ensure separate partition exists for /home (Scored)
- 1.1.13 Ensure nodev option set on /home partition (Scored)
- 1.1.14 Ensure nodev option set on /dev/shm partition (Scored)
- 1.1.15 Ensure nosuid option set on /dev/shm partition (Scored)
- 1.1.16 Ensure noexec option set on /dev/shm partition (Scored)
- 1.1.20 Ensure sticky bit is set on all world-writable directories (Scored)

- 1.2.1 Ensure package manager repositories are configured (Not Scored)
- 1.2.2 Ensure GPG keys are configured (Not Scored)

- 1.4.3 Ensure authentication required for single user mode (Scored)

- 1.5.1 Ensure core dumps are restricted (Scored)
- 1.5.3 Ensure address space layout randomization (ASLR) is enabled (Scored)

- 1.6.1 Configure SELinux
- 1.6.2 Configure AppArmor

- 2.1.10 Ensure xinetd is not enabled (Scored)

- 2.2.7 Ensure NFS and RPC are not enabled (Scored)

- 3.1.2 Ensure packet redirect sending is disabled (Scored)

- 3.2.1 Ensure source routed packets are not accepted (Scored)
- 3.2.7 Ensure Reverse Path Filtering is enabled (Scored)

- 3.3.3 Ensure IPv6 is disabled (Not Scored)

- 3.4 TCP Wrappers

- 3.7 Ensure wireless interfaces are disabled (Not Scored)

- 4.1.1.2 Ensure system is disabled when audit logs are full (Scored)
- 4.1.1.3 Ensure audit logs are not automatically deleted (Scored)
- 4.1.3 Ensure auditing for processes that start prior to auditd is enabled (Scored)
- 4.1.9 Ensure session initiation information is collected (Scored)
- 4.1.10 Ensure discretionary access control permission modification events are collected (Scored)
- 4.1.13 Ensure successful file system mounts are collected (Scored)
- 4.1.18 Ensure the audit configuration is immutable (Scored)

- 4.2.1 Configure rsyslog
- 4.2.2 Configure syslog-ng
- 4.2.3 Ensure rsyslog or syslog-ng is installed (Scored)

- 5.3.1 Ensure password creation requirements are configured (Scored)
- 5.3.2 Ensure lockout for failed password attempts is configured (Not Scored)
- 5.3.3 Ensure password reuse is limited (Scored)
- 5.3.4 Ensure password hashing algorithm is SHA-512 (Scored)

- 5.4.1 Set Shadow Password Suite Parameters

- 5.5 Ensure root login is restricted to system console (Not Scored)

- 5.6 Ensure access to the su command is restricted (Scored)

- 6.1.1 Audit system file permissions (Not Scored)
- 6.1.10 Ensure no world writable files exist (Scored)
- 6.1.11 Ensure no unowned files or directories exist (Scored)
- 6.1.12 Ensure no ungrouped files or directories exist (Scored)
- 6.1.13 Audit SUID executables (Not Scored)
- 6.1.14 Audit SGID executables (Not Scored)

- 6.2.1 Ensure password fields are not empty (Scored)
- 6.2.2 Ensure no legacy "+" entries exist in /etc/passwd (Scored)
- 6.2.4 Ensure no legacy "+" entries exist in /etc/group (Scored)
- 6.2.16 Ensure no duplicate UIDs exist (Scored)
- 6.2.17 Ensure no duplicate GIDs exist (Scored)
- 6.2.18 Ensure no duplicate user names exist (Scored)
- 6.2.19 Ensure no duplicate group names exist (Scored)
- 6.2.20 Ensure shadow group is empty (Scored)

# Irrelevant / Vanskelig å gjennomføre
- 1.1.5 Ensure separate partition exists for /var (Scored)
- 1.1.6 Ensure separate partition exists for /var/tmp (Scored)
- 1.1.7 Ensure nodev option set on /var/tmp partition (Scored)
- 1.1.8 Ensure nosuid option set on /var/tmp partition (Scored)
- 1.1.9 Ensure noexec option set on /var/tmp partition (Scored)
- 1.1.17 Ensure nodev option set on removable media partitions (Not Scored)
- 1.1.18 Ensure nosuid option set on removable media partitions (Not Scored)
- 1.1.19 Ensure noexec option set on removable media partitions (Not Scored)

- 1.4.2 Ensure bootloader password is set (Scored)

- 1.5.2 Ensure XD/NX support is enabled (Not Scored)

- 1.7.2 Ensure GDM login banner is configured (Scored)

- 2.2.1.3 Ensure chrony is configured (Scored)

- 3.1.1 Ensure IP forwarding is disabled (Scored)
