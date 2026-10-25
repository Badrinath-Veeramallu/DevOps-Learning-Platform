# DevOps Learning Platform — Mobile Documentation Index

Welcome to the official developer and learner documentation for the **DevOps Learning Platform Flutter Android Application**.

This documentation series accompanies the step-by-step engineering of our mobile application. Every document teaches Flutter and Dart fundamentals from first principles while detailing real production code, real API integrations, and real architectural decisions.

---

## Recommended Reading Order

| Step | Document | Focus Area | Status |
|:---:|---|---|:---:|
| **00** | [00_PROJECT_OVERVIEW.md](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/docs/00_PROJECT_OVERVIEW.md) | Full-stack architecture, existing backend & web audit, API contracts, Dart basics, network & emulator rules | **Completed (Phase 0)** |
| **01** | [01_FLUTTER_AND_DART_FUNDAMENTALS.md](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/docs/01_FLUTTER_AND_DART_FUNDAMENTALS.md) | Deep dive into Flutter widgets, Dart OOP, widget trees, `StatelessWidget` vs `StatefulWidget`, `BuildContext` | **Completed (Phase 1)** |
| **02** | [02_PROJECT_SETUP_AND_DESIGN_SYSTEM.md](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/docs/02_PROJECT_SETUP_AND_DESIGN_SYSTEM.md) | Cyber Midnight dark theme, reusable components, buttons, text fields, cards, routing with `go_router` | **Completed (Phase 1)** |
| **03** | [03_AUTHENTICATION_AND_API_INTEGRATION.md](file:///Users/badrinathveeramallu/Desktop/DevOps-Learning-Platform/mobile/docs/03_AUTHENTICATION_AND_API_INTEGRATION.md) | Dio HTTP client, secure token storage, registration, OTP email verification, login, session restoration | **Completed (Phase 2)** |
| **04** | `04_DASHBOARD_AND_DATA_FLOW.md` | Command center dashboard, learning paths, authenticated profile rendering, logout lifecycle | *Upcoming (Phase 3)* |
| **05** | `05_TESTING_AND_DEBUGGING.md` | Unit testing, widget testing, mock API responses, edge cases, session resilience, Android QA | *Upcoming (Phase 4)* |

---

## Architectural Principles

1. **Shared Single Identity Authority**: The existing Express backend and MongoDB database remain the sole authority for accounts and authentication.
2. **Web Application Invariance**: The existing React web application is protected and remains 100% operational.
3. **No Phantom Code**: No fake data presented as real; no phantom endpoints or mocked persistence where real backend operations exist.
4. **Zero-Knowledge Teaching**: Every concept, syntax token, and architectural pattern is explained in clear terms for beginners before implementation.
