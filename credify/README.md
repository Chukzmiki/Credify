# Credify

**Credify** is a decentralized freelancer marketplace smart contract built on the Clarity language for the Stacks blockchain. It enables freelancers to create verifiable profiles, showcase projects, display client testimonials, and form professional networks — all while preserving privacy and ownership over their data.

## 🚀 Features

- **Freelancer Profiles**  
  - Create and update profiles with skills and bios.
  - Set visibility levels (Public, Network Members, Private).
  - Profiles can be verified by contract admin.

- **Project Portfolio**
  - Add projects with start/end dates, descriptions, and client info.
  - Support for privacy-level settings on a per-project basis.

- **Skill Certifications**
  - Record professional certifications with optional expiration.
  - Certifications can be verified by contract admin.

- **Client Testimonials**
  - Clients can leave public or private testimonials for freelancers on specific skills.
  - Prevents duplicate endorsements from the same client.

- **Professional Networking**
  - Send and accept connection requests.
  - "Network Members" can access semi-private data based on privacy level.

## 🔐 Privacy Levels

- `0`: Public (everyone can view)
- `1`: Network Members Only
- `2`: Private (owner only)

## 📑 Contract Structure

- Maps:
  - `freelancer-profiles`: Core profile data.
  - `project-portfolio`: Projects tied to freelancers.
  - `skill-certifications`: Verifiable skill certifications.
  - `client-testimonials`: Endorsements from clients.
  - `professional-connections`: Peer-to-peer networking.

- Variables:
  - `project-id-counter`, `certification-id-counter`: Unique ID generators.
  - `contract-owner`: Authorized entity for verification.

## 🔧 Admin Functions

- `verify-freelancer-profile`: Verify freelancer profiles.
- `verify-skill-certification`: Approve certifications.
- `set-contract-owner`: Transfer contract ownership.

## 🔎 Privacy & Access Control

Read-only functions like `get-freelancer-profile`, `get-project-portfolio`, and `get-skill-certification` respect each record’s privacy level, and utilize professional connections to manage conditional access.

## 📜 Error Codes

| Code | Meaning |
|------|---------|
| `u100` | Not authorized |
| `u101` | Freelancer not found |
| `u102` | Already endorsed |
| `u103` | Invalid privacy level |
| `u104` | Certification not found |

## 📈 Use Cases

- Portfolio-driven freelance networks
- Skill-based hiring verification
- Professional networking DApps
- Talent credibility tracking in decentralized environments
