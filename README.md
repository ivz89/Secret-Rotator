# Secret-Rotator

This repository contains a **GitHub Actions workflow** to automatically rotate a secret for a target application in **Microsoft Entra ID (Azure AD)** and update it in a **Key Vault** and **Logstash Keystore**. This was developed because Microsoft's official Logstash Sentinel plugin does not support Managed Identity authentication to Log Analytics Workspace at the time of this writing. Consequently, a secret rotation is necessary to mitigate availability disruptions to short secret validitiy.

The workflow uses **GitHub OIDC federated credentials** for authentication, eliminating the need for storing long-lived Azure secrets.

---

## Architecture Overview

```mermaid
flowchart TD
    A[GitHub Actions (OIDC)] --> B[Entra ID App (rotate secret)]
    B --> C[Key Vault (update secret)]
    B --> D[VM (update Logstash keystore)]
```

---

## Repository Structure

```text
github/workflows/
  rotate-secret.yml

scripts/
  01-rotate-secret.ps1   # creates new secret
  02-update-kv.ps1       # updates Key Vault
  03-update-vm.ps1       # updates VM Logstash keystore
```

---

## ⏱ Rotation Policy

- **Secret lifetime:** 90 days  
- **Rotation window:** ≤ 30 days before expiry  
- **Schedule:** Weekly (Sunday 02:00 UTC)  
- **VM update:** Only if running  

---

## 🔐 Required Azure Permissions

- **Entra ID:** `Application.ReadWrite.All`  
- **Key Vault:** Secrets Officer on the vault  
- **VM Resource Group:** Virtual Machine Contributor  

---

## 🔁 Workflow Steps

1. Checks Key Vault secret expiry  
2. Creates new secret if ≤30 days left (valid 90 days)  
3. Updates Key Vault  
4. If VM is running:
   - Updates Logstash keystore entry `client_secret`  
   - Restarts Logstash

