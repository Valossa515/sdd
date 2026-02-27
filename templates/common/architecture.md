# Architecture

## Overview
- **Style:** [Layered / Hexagonal / Clean Architecture / MVC — detected from folder structure]
- **Packaging strategy:** [by layer / by feature / hybrid]
- **Base package:** [e.g., `com.example.orders`]

## Layers and Responsibilities

| Layer | Package/Folder | Responsibility |
|-------|---------------|----------------|
| API / Presentation | `controller/`, `resource/`, `api/` | HTTP entry points, request validation, response mapping |
| Application | `service/`, `usecase/` | Business orchestration, transaction boundaries |
| Domain | `model/`, `domain/`, `entity/` | Business entities, value objects, domain rules |
| Infrastructure | `repository/`, `config/`, `client/` | Persistence, external service clients, configuration |

## Module & Class Map
<!-- Auto-populated: agent must scan the source tree and fill this section -->

### Controllers / Entry Points
| Class | Path | Responsibility |
|-------|------|----------------|
| `OrderController` | `src/.../controller/OrderController.java` | Handles CRUD operations for orders |

### Services / Use Cases
| Class | Path | Responsibility |
|-------|------|----------------|
| `OrderService` | `src/.../service/OrderService.java` | Orchestrates order creation, validation, and stock checks |

### Entities / Domain Models
| Class | Path | Responsibility |
|-------|------|----------------|
| `Order` | `src/.../model/Order.java` | Represents a customer order with items and status |

### Repositories / Data Access
| Class | Path | Responsibility |
|-------|------|----------------|
| `OrderRepository` | `src/.../repository/OrderRepository.java` | Persistence operations for Order entity |

### Configuration & Cross-cutting
| Class | Path | Responsibility |
|-------|------|----------------|
| `SecurityConfig` | `src/.../config/SecurityConfig.java` | Authentication and authorization setup |

### DTOs / Request-Response Objects
| Class | Path | Responsibility |
|-------|------|----------------|
| `CreateOrderRequest` | `src/.../dto/CreateOrderRequest.java` | Input payload for order creation endpoint |

> **Note:** The agent must replace the examples above with the actual classes found in the project. Remove categories that don't apply.

## Domain Boundaries
- [Bounded context 1]
- [Bounded context 2]

## C4 Summary
- **Context:** [systems and actors that interact with this system]
- **Containers:** [apps, databases, message queues, caches]
- **Components:** [key modules and their interactions]

## External Integrations

| System | Protocol | Purpose |
|--------|----------|---------|
| PostgreSQL | JDBC | Primary data store |
| [External API] | HTTP/REST | [purpose] |

## Key Design Decisions
<!-- Reference ADRs from decisions.md -->
- Database: [chosen DB and why]
- ORM: [chosen ORM]
- Auth: [authentication/authorization strategy]
- Messaging: [if applicable]
