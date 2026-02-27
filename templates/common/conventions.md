# Project Conventions

## Naming
<!-- Auto-populated: agent must detect patterns from existing code -->
- **Classes:** [PascalCase — e.g., `OrderService`, `CreateOrderRequest`]
- **Methods:** [camelCase — e.g., `createOrder`, `findById`]
- **Tables:** [snake_case — e.g., `customer_orders`]
- **Endpoints:** [kebab-case — e.g., `/api/v1/customer-orders`]
- **Constants:** [UPPER_SNAKE — e.g., `MAX_RETRY_COUNT`]

## Folder / Package Structure
<!-- Auto-populated: agent must map actual project layout -->
```
src/
├── main/
│   ├── java/com/example/project/
│   │   ├── controller/    # REST controllers
│   │   ├── service/       # Business logic
│   │   ├── repository/    # Data access
│   │   ├── model/         # Domain entities
│   │   ├── dto/           # Request/Response objects
│   │   └── config/        # Spring configuration
│   └── resources/
│       ├── application.yml
│       └── db/migration/  # Flyway/Liquibase migrations
└── test/
    └── java/com/example/project/
        ├── controller/    # Integration tests
        └── service/       # Unit tests
```

> **Note:** Replace the tree above with the actual project structure.

## APIs
- **Versioning:** [/api/v1/ prefix — detected from routes]
- **Error format:** [Problem Details RFC 7807 / custom / Spring default]
- **Pagination:** [page/size params / cursor-based / none]
- **Auth:** [Bearer JWT / Basic / API Key / none]

## Database
- **ORM/Data access:** [JPA/Hibernate / MyBatis / Dapper / EF Core]
- **Migration tool:** [Flyway / Liquibase / EF Migrations / manual]
- **Migration naming:** [V001__description / timestamp-based]
- **Soft delete:** [yes/no — detected from entity fields]
- **Audit fields:** [createdAt, updatedAt — detected from entities]

## Testing
- **Framework:** [JUnit 5 / xUnit / NUnit / Jest]
- **Mock library:** [Mockito / Moq / NSubstitute]
- **Test naming:** [should_doSomething_when_condition / MethodName_Scenario_Expected]
- **Integration tests:** [TestContainers / H2 / SQLite in-memory]
- **Coverage tool:** [JaCoCo / Coverlet / Istanbul]

## Dependency Injection
- **Style:** [Constructor injection / field injection / method injection]
- **Container:** [Spring / .NET DI / manual]

## Error Handling
- **Strategy:** [Global exception handler / per-controller / middleware]
- **Custom exceptions:** [yes/no — list if found]
- **Logging:** [SLF4J / Serilog / console]
