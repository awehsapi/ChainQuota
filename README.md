

# ChainQuota - Resource Allocation Smart Contract

A Clarity-based smart contract for managing and allocating limited resources in a controlled, role-based, and auditable manner. This contract is designed for use cases like resource distribution systems, decentralized infrastructure credits, or quota-based services in a trustless environment.

---

## 🚀 Features

- **Role-Based Access Control**: Users are assigned roles like `ADMIN`, `PREMIUM`, `BUSINESS`, `VERIFIED`, or `USER`, each with corresponding priority levels.
- **Resource Registration & Management**: Admins can register new resource types with supply, pricing, and access control policies.
- **Request-Based Allocation**: Users can submit resource allocation requests with reasons and expiry.
- **Transfer Support**: Allows resource transfer between users under access and balance checks.
- **System Controls**: Admins can initialize the system, enable maintenance, freeze/unfreeze individual resources, and block/unblock users.
- **Emergency & Maintenance Modes**: Temporarily halt operations during upgrades or emergencies.
- **Audit-Friendly**: All allocations, requests, and updates are logged, supporting traceability.

---

## 📚 Data Structures

### 🔐 Constants
| Name | Description |
|------|-------------|
| `CONTRACT_ADMINISTRATOR` | The admin (deployer) of the contract. |
| `ERROR_...` | Well-defined error codes for various invalid actions. |

### 🧩 Data Variables
- `is-contract-initialized`, `is-system-frozen`, `is-maintenance-active`
- `pending-request-counter`
- `global-allocation-limit`, `backup-admin-address`

### 📦 Maps
| Map | Description |
|-----|-------------|
| `available-resource-types` | Registered resources with supply, access level, and pricing metadata. |
| `user-resource-balances` | Tracks each user’s balance for a resource. |
| `allocation-requests` | Tracks submitted requests with expiration and status. |
| `user-allocation-history` | Stores a user’s recent allocation history. |
| `resource-price-history` | Stores price updates per resource. |
| `user-access-levels` | Maps users to their access level. |
| `blocked-accounts` | Denotes blocked users. |
| `resource-dependencies` | Optional dependencies between resource types. |

---

## ⚙️ Core Functions

### 🛠 System Management
- `initialize-system`: Initializes the contract.
- `update-system-parameters`: Update global limits and backup admin.

### 📦 Resource Management
- `register-resource-type`: Admins register a new resource.
- `update-resource-price`: Update resource pricing and history.

### 👥 Account Management
- `update-user-role`: Assign roles to users.
- `block-user` / `unblock-user`: Control user access.

### 📨 Allocation Functions
- `request-resource-allocation`: Submit a new resource request.
- `transfer-resources`: Transfer allocated resources between users.

### 🚨 Emergency Management
- `enable-maintenance-mode` / `disable-maintenance-mode`: Pause or resume contract functions.
- `freeze-resource` / `unfreeze-resource`: Temporarily disable a specific resource.

---

## 🔍 Read-Only Queries

- `get-user-balance`
- `get-resource-info`
- `get-request-details`
- `get-user-allocation-history`
- `get-resource-price-history`
- `get-system-status`

---

## 🛡️ Role Priorities

| Role      | Priority |
|-----------|----------|
| ADMIN     | 5        |
| PREMIUM   | 4        |
| BUSINESS  | 3        |
| VERIFIED  | 2        |
| USER      | 1        |

---
