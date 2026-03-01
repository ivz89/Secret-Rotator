# Secret-Rotator

This repository contains a **GitHub Actions workflow** to automatically rotate a secret for a target application in **Microsoft Entra ID (Azure AD)** and update it in a **Key Vault** and **Logstash Keystore**. This was developed as Microsoft's Logstash Sentinel plugin does not support passwordless authenitcation to Log Analytics Workspace at the time of this writing. 

The workflow uses **GitHub OIDC federated credentials** for authentication, eliminating the need for storing long-lived Azure secrets.

---

GitHub Actions (OIDC)
│
▼
Entra ID App (rotate secret)
│
├──> Key Vault (update secret)
│
└──> VM (update Logstash's keystore)

---

github/workflows/
rotate-secret.yml

scripts/
01-rotate-secret.ps1 # creates new secret
02-update-kv.ps1 # updates Key Vault
03-update-vm.ps1 # updates VM Logstash keystore

---

## ⏱ Rotation Policy

- Secret lifetime: 90 days  
- Rotation window: ≤ 30 days before expiry  
- Schedule: Weekly (Sunday 02:00 UTC)  
- VM update: Only if running  


## 🔐 Required Azure Permissions

- **Entra ID:** `Application.ReadWrite.All`  
- **Key Vault:** Secrets Officer on the vault  
- **VM Resource Group:** Virtual Machine Contributor  

---

## 🔁 Workflow

1. Checks Key Vault secret expiry  
2. Creates new secret if ≤30 days left (valid 90 days)  
3. Updates Key Vault  
4. If VM is running:
   - Updates Logstash keystore entry `client_secret`  
   - Restarts Logstash  
