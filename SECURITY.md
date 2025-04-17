# Security Policy – Lime Contracts

## Introduction
This document outlines the security practices and responsible disclosure policy for the Lime smart contracts. Our goal is to build transparent, secure, and community-driven products. We welcome contributions and responsible disclosure of vulnerabilities.

---

## Scope
This policy applies to the following components:

- All Solidity smart contracts maintained under the Lime project repositories.
- On-chain deployments verified by the Lime team.
- Infrastructure directly connected to smart contract interaction (e.g., upgraders, pools).

---

## Security Practices

We implement the following practices to ensure security:

- ✅ **Automated Testing**  
  All contracts undergo unit, integration, and fuzz testing using Hardhat.
- ✅ **Static Analysis**  
  We use tools such as Slither to detect common vulnerabilities.
- ✅ **Code Reviews**  
  Every code change is reviewed by team members before merging.
- ✅ **Upgradability Safety**  
  Contracts use the UUPS proxy pattern and follow OpenZeppelin best practices.
- ✅ **Access Control**  
  Roles and permissions are strictly limited and defined using `Ownable`.

---

## Reporting Vulnerabilities

If you discover a security vulnerability, please **do not** open a public issue. Instead, report it via:

📧 **security@lime.dev**  

We will respond within **72 hours**, and work with you on a timeline for resolution and coordinated disclosure if necessary.

---

## Rewards

Lime may offer **bug bounties** for critical vulnerabilities depending on the severity, impact, and disclosure quality.

---

## Out of Scope

- Issues on third-party dependencies unless affecting Lime contracts directly.
- Denial-of-service (DoS) that requires miner-level control.
- Frontend bugs unless affecting funds or user private keys.

---

## Disclaimer

We reserve the right to revise this policy at any time. By responsibly disclosing vulnerabilities, you agree to not exploit them for personal gain or share them with malicious actors.
