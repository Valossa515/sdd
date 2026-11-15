---
name: dotnet
description: Use this skill for any .NET task — APIs, services, repositories, config, tests, or refactoring. Targets .NET 10 (LTS) with C# 14, ASP.NET Core 10 and EF Core 10.
stack: dotnet
versions: ".NET 10 (LTS), ASP.NET Core 10, C# 14, EF Core 10, MediatR"
---

# .NET Agent Skill

You are an expert .NET engineer. Follow these guidelines for every task in this project.

## Stack Versions (always target these unless told otherwise)

- **.NET**: 10 (LTS, supported until November 2028), `<TargetFramework>net10.0</TargetFramework>` — .NET 8 and 9 reached end of support in November 2026
- **C#**: 14 (primary constructors, collection expressions, the `field` keyword, extension members)
- **ASP.NET Core**: 10
- **EF Core**: 10 (Npgsql provider for PostgreSQL)
- **MediatR**: 12.5 — the last Apache-licensed release (see licensing below)
- **FluentValidation**: 11+
- **xUnit**: v3

---

## .NET 10 Essentials

- **OpenAPI is built in**: `builder.Services.AddOpenApi()` + `app.MapOpenApi()` (`Microsoft.AspNetCore.OpenApi`) generates OpenAPI **3.1** by default. Swashbuckle is no longer in the templates — add a UI (Scalar or Swagger UI) only if the project wants one.
- **Minimal API validation**: `builder.Services.AddValidation()` validates DataAnnotations on Minimal API parameters (query, header and body). Controllers keep validating through `[ApiController]`; commands keep the FluentValidation pipeline below.
- **EF Core 10 named query filters**: several filters per entity, each switchable on its own:

  ```csharp
  modelBuilder.Entity<Order>()
      .HasQueryFilter("SoftDelete", o => !o.IsDeleted)
      .HasQueryFilter("Tenant", o => o.TenantId == _tenant.Id);

  // turn off only the soft-delete filter, keep tenant isolation
  var withDeleted = await db.Orders.IgnoreQueryFilters(["SoftDelete"]).ToListAsync(ct);
  ```

- **EF Core 10 LINQ**: `LeftJoin` / `RightJoin` operators replace the `GroupJoin` + `DefaultIfEmpty` pattern
- **C# 14 `field` keyword**: validate in a property setter without declaring a backing field —
  `public string Sku { get; set => field = value?.Trim() ?? throw new ArgumentNullException(nameof(value)); }`

### Library licensing

Several popular libraries moved to commercial licenses. Don't upgrade past the last free version without checking the license, and record the project's choice in Project Overrides:

| Library | Last free (Apache/MIT) | Newer versions |
|---------|------------------------|----------------|
| MediatR | 12.5.0 | 13+: RPL-1.5 or commercial license |
| AutoMapper | 14.x and earlier | 15+: commercial license |
| FluentAssertions | 7.x | 8+: commercial license (free for non-commercial use) |

Alternatives when a license doesn't fit: a small in-house `ISender`/handler dispatcher instead of MediatR, explicit mapping methods instead of AutoMapper, AwesomeAssertions (community fork of FluentAssertions 7) or Shouldly for test assertions.

---

## Architecture

Follow **Clean Architecture** (or Vertical Slice for simpler projects). Default to Clean Arch.

```
src/
├── YourApp.Api/                  ← Presentation layer (Controllers, Middleware, DI setup)
├── YourApp.Application/          ← Use cases (Commands, Queries, Handlers, Validators)
├── YourApp.Domain/               ← Entities, Value Objects, Domain Events, Interfaces
└── YourApp.Infrastructure/       ← EF Core, External services, Repos implementations
tests/
├── YourApp.UnitTests/
├── YourApp.IntegrationTests/
└── YourApp.ArchTests/            ← Optional: enforce layer dependencies with ArchUnitNET
```

**Dependency flow:** Api → Application → Domain ← Infrastructure

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Command | `{Action}{Resource}Command` | `CreateOrderCommand` |
| Command Handler | `{Action}{Resource}CommandHandler` | `CreateOrderCommandHandler` |
| Query | `Get{Resource}Query` | `GetOrderByIdQuery` |
| Query Handler | `Get{Resource}QueryHandler` | `GetOrderByIdQueryHandler` |
| Validator | `{Command/Query}Validator` | `CreateOrderCommandValidator` |
| Repository interface | `I{Resource}Repository` | `IOrderRepository` |
| EF Repository | `{Resource}Repository` | `OrderRepository` |
| DTO (response) | `{Resource}Response` | `OrderResponse` |
| Exception | `{Resource}NotFoundException` | `OrderNotFoundException` |

---

## API Controllers

Use **Minimal APIs** for simple endpoints, **Controllers** for complex scenarios. Default to Controllers.

```csharp
[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class OrdersController(ISender sender) : ControllerBase
{
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var result = await sender.Send(new GetOrderByIdQuery(id), ct);
        return Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(OrderResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Create(
        [FromBody] CreateOrderCommand command,
        CancellationToken ct)
    {
        var result = await sender.Send(command, ct);
        return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await sender.Send(new DeleteOrderCommand(id), ct);
        return NoContent();
    }
}
```

---

## CQRS with MediatR

### Command

```csharp
public record CreateOrderCommand(
    string CustomerId,
    List<OrderItemDto> Items
) : IRequest<OrderResponse>;

public class CreateOrderCommandHandler(
    IOrderRepository orderRepository,
    ICustomerRepository customerRepository
) : IRequestHandler<CreateOrderCommand, OrderResponse>
{
    public async Task<OrderResponse> Handle(
        CreateOrderCommand request,
        CancellationToken cancellationToken)
    {
        var customer = await customerRepository.GetByIdAsync(
            Guid.Parse(request.CustomerId), cancellationToken)
            ?? throw new CustomerNotFoundException(request.CustomerId);

        var order = Order.Create(customer, request.Items);
        await orderRepository.AddAsync(order, cancellationToken);

        return OrderResponse.FromDomain(order);
    }
}
```

### Validator (FluentValidation + MediatR pipeline)

```csharp
public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderCommandValidator()
    {
        RuleFor(x => x.CustomerId)
            .NotEmpty()
            .Must(id => Guid.TryParse(id, out _))
            .WithMessage("CustomerId must be a valid GUID");

        RuleFor(x => x.Items)
            .NotEmpty()
            .WithMessage("Order must have at least one item");

        RuleForEach(x => x.Items).SetValidator(new OrderItemDtoValidator());
    }
}
```

### Pipeline Behavior (register once)

```csharp
public class ValidationBehavior<TRequest, TResponse>(
    IEnumerable<IValidator<TRequest>> validators
) : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        var context = new ValidationContext<TRequest>(request);
        var failures = validators
            .Select(v => v.Validate(context))
            .SelectMany(r => r.Errors)
            .Where(f => f != null)
            .ToList();

        if (failures.Count != 0)
            throw new ValidationException(failures);

        return await next();
    }
}
```

---

## Domain Entities

Use rich domain model. No public setters. Factory methods for creation.

```csharp
public class Order : AggregateRoot
{
    public Guid Id { get; private set; }
    public string CustomerId { get; private set; }
    public OrderStatus Status { get; private set; }
    public IReadOnlyList<OrderItem> Items => _items.AsReadOnly();
    public DateTime CreatedAt { get; private set; }

    private readonly List<OrderItem> _items = [];

    private Order() { } // EF Core

    public static Order Create(Customer customer, IEnumerable<OrderItemDto> items)
    {
        ArgumentNullException.ThrowIfNull(customer);

        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = customer.Id.ToString(),
            Status = OrderStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        foreach (var item in items)
            order._items.Add(OrderItem.Create(item));

        order.AddDomainEvent(new OrderCreatedEvent(order.Id));
        return order;
    }

    public void Confirm()
    {
        if (Status != OrderStatus.Pending)
            throw new InvalidOperationException($"Cannot confirm order in status {Status}");

        Status = OrderStatus.Confirmed;
        AddDomainEvent(new OrderConfirmedEvent(Id));
    }
}
```

---

## Exception Handling Middleware

```csharp
public class GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        var (statusCode, title) = exception switch
        {
            NotFoundException => (StatusCodes.Status404NotFound, "Resource not found"),
            ValidationException => (StatusCodes.Status422UnprocessableEntity, "Validation failed"),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred")
        };

        if (statusCode == 500)
            logger.LogError(exception, "Unhandled exception");

        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = exception.Message
        };

        if (exception is ValidationException validationEx)
            problemDetails.Extensions["errors"] = validationEx.Errors
                .GroupBy(e => e.PropertyName)
                .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsJsonAsync(problemDetails);
    }
}
```

---

## Configuration

Use typed options with `IOptions<T>`.

```csharp
public class PaymentOptions
{
    public const string SectionName = "Payment";

    [Required, Url]
    public string ApiUrl { get; init; } = default!;

    [Required]
    public string ApiKey { get; init; } = default!;

    public TimeSpan Timeout { get; init; } = TimeSpan.FromSeconds(5);
    public int MaxRetries { get; init; } = 3;
}

// Registration
builder.Services.AddOptions<PaymentOptions>()
    .BindConfiguration(PaymentOptions.SectionName)
    .ValidateDataAnnotations()
    .ValidateOnStart();
```

```json
// appsettings.json
{
  "Payment": {
    "ApiUrl": "https://api.payment.com",
    "ApiKey": "from-env-or-secrets",
    "Timeout": "00:00:05",
    "MaxRetries": 3
  }
}
```

---

## DI Registration (Program.cs)

Organize with extension methods per layer.

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddPresentation()
    .AddApplication()
    .AddInfrastructure(builder.Configuration);

var app = builder.Build();
app.UseMiddleware<GlobalExceptionMiddleware>();
app.MapControllers();
app.Run();

// ApplicationServiceExtensions.cs
public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(typeof(ApplicationAssemblyMarker).Assembly);
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
        });

        services.AddValidatorsFromAssembly(typeof(ApplicationAssemblyMarker).Assembly);
        return services;
    }
}
```

---

## Testing

See `testing.md` for full guide. Quick rules:

- Unit tests: xUnit v3 + NSubstitute (no integration, no EF)
- Integration tests: `WebApplicationFactory` + Testcontainers
- **Minimum coverage**: 80% on Application and Domain layers

---

## What NOT to do

- ❌ Business logic in controllers
- ❌ `DbContext` injected directly in controllers or application handlers — use repositories
- ❌ `var result = repo.GetAll().ToList()` — always use async: `await repo.GetAllAsync(ct)`
- ❌ Returning domain entities from API — always use response DTOs
- ❌ `DateTime.Now` — always use `DateTime.UtcNow`
- ❌ Catching `Exception` silently — log and rethrow or convert to domain exception
- ❌ Public setters on domain entities
- ❌ `IEnumerable<T>` in domain — use `IReadOnlyList<T>` to signal immutability
- ❌ Adding Swashbuckle to a new project — use the built-in OpenAPI support
- ❌ Upgrading MediatR, AutoMapper or FluentAssertions past their last free version without checking the license
