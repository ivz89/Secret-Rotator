# Secret-Rotator

This repository contains a **GitHub Actions workflow** to automatically rotate a secret for a target application in **Microsoft Entra ID (Azure AD)** and update it in a **GitHub Actions environment secret**. The workflow uses **GitHub OIDC federated credentials** for authentication, eliminating the need for storing long-lived Azure secrets.

---

## Features

- Authenticate to Entra ID using **OIDC federated credential** (branch-restricted)
- Rotate a **target app secret** in Microsoft Entra ID
- Update a **GitHub environment secret** with the new password
- Fully automated and can run on a schedule (every minute for testing)

---

## Prerequisites

1. **Microsoft Entra / Azure AD**:
   - Rotator application registered
   - Federated credential created for GitHub Actions
   - Rotator app must be **owner** of the target application

2. **GitHub repository secrets**:
   - `AZURE_CLIENT_ID` → Rotator app client ID
   - `AZURE_TENANT_ID` → Entra tenant ID
   - `TARGET_APP_OBJECT_ID` → Target app object ID
   - `GH_PAT` → Personal Access Token with `Contents: Read & Write` for this repo

3. **GitHub Actions setup**:
   - Workflow file located at `.github/workflows/rotate-secret.yml`
   - Must run on the branch that matches your federated credential (e.g., `main`)

---

## Workflow Overview

1. **Trigger**  
   The workflow runs on:
   - Push to `main`
   - Manual dispatch
   - Cron schedule (`every minute` for testing)

2. **Azure OIDC Login**  
   Uses `azure/login@v2` to authenticate via GitHub OIDC, branch-restricted to `main`.

3. **Rotate Secret**  
   - Calls Microsoft Graph API to create a new password for the target app  
   - Short expiry for testing (30 minutes)  
   - Stores the new secret in `$GITHUB_ENV`

4. **Update GitHub Secret**  
   - Uses `GH_PAT` to update a GitHub environment secret (e.g., `LOGSTASH_APP_SECRET`)  
   - Fully automatic — no manual intervention required

---

## Testing

- Cron is set to run **every minute** for testing
- Verify workflow runs in **Actions tab**
- Check logs to confirm:
  - Azure OIDC login success
  - Secret creation in Entra
  - GitHub environment secret update

> ⚠️ Do not leave the workflow running every minute in production. Adjust schedule and secret expiry for production use.

---

## File Structure
