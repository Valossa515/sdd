---
name: dotnet-testing
description: Testing guide for .NET projects. Unit tests with xUnit + NSubstitute, integration tests with WebApplicationFactory and Testcontainers.
stack: dotnet
versions: ".NET 8/9, xUnit, NSubstitute, Testcontainers"
---

# .NET Testing

## Dependencies

```xml
<!-- Unit test project -->
<PackageReference Include="xunit" Version="2.*" />
<PackageReference Include="xunit.runner.visualstudio" Version="2.*" />
<PackageReference Include="NSubstitute" Version="5.*" />
<PackageReference Include="FluentAssertions" Version="6.*" />
<PackageReference Include="AutoFixture.Xunit2" Version="4.*" />

<!-- Integration test project -->
<PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.*" />
<PackageReference Include="Testcontainers.PostgreSql" Version="3.*" />
<PackageReference Include="Respawn" Version="6.*" />
```

---

## Unit Tests — Application Handlers

No real infrastructure. Use NSubstitute for mocks.

```csharp
public class CreateOrderCommandHandlerTests
{
    private readonly IOrderRepository _orderRepository = Substitute.For<IOrderRepository>();
    private readonly ICustomerRepository _customerRepository = Substitute.For<ICustomerRepository>();
    private readonly CreateOrderCommandHandler _sut;

    public CreateOrderCommandHandlerTests()
    {
        _sut = new CreateOrderCommandHandler(_orderRepository, _customerRepository);
    }

    [Fact]
    public async Task Handle_ShouldCreateOrder_WhenCustomerExists()
    {
        // Arrange
        var customer = CustomerFixture.AnyCustomer();
        var command = new CreateOrderCommand(customer.Id.ToString(), [
            new OrderItemDto("product-1", 2)
        ]);

        _customerRepository.GetByIdAsync(customer.Id, Arg.Any<CancellationToken>())
            .Returns(customer);

        _orderRepository.AddAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);

        // Act
        var result = await _sut.Handle(command, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.CustomerId.Should().Be(customer.Id.ToString());
        await _orderRepository.Received(1).AddAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_ShouldThrow_WhenCustomerNotFound()
    {
        var command = new CreateOrderCommand(Guid.NewGuid().ToString(), []);
        _customerRepository.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns((Customer?)null);

        Func<Task> act = () => _sut.Handle(command, CancellationToken.None);

        await act.Should().ThrowAsync<CustomerNotFoundException>();
    }
}
```

---

## Integration Tests — WebApplicationFactory + Testcontainers

```csharp
public class OrdersIntegrationTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;
    private readonly ApiFactory _factory;

    public OrdersIntegrationTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateOrder_ShouldReturn201_WithValidRequest()
    {
        // Arrange
        var request = new CreateOrderCommand("customer-test", [
            new OrderItemDto("product-1", 2)
        ]);

        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/orders", request);
        var body = await response.Content.ReadFromJsonAsync<OrderResponse>();

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        body!.Id.Should().NotBeEmpty();

        // Verify in DB
        var saved = await _factory.FindOrderAsync(body.Id);
        saved.Should().NotBeNull();
    }
}

// ApiFactory.cs
public class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .Build();

    private Respawner _respawner = default!;

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Replace real DB with test container
            services.RemoveAll<DbContextOptions<AppDbContext>>();
            services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(_postgres.GetConnectionString()));
        });
    }

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();

        // Run migrations
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.MigrateAsync();

        _respawner = await Respawner.CreateAsync(_postgres.GetConnectionString(),
            new RespawnerOptions { DbAdapter = DbAdapter.Postgres });
    }

    public async Task ResetDatabaseAsync() => await _respawner.ResetAsync(_postgres.GetConnectionString());

    async Task IAsyncLifetime.DisposeAsync() => await _postgres.StopAsync();
}
```

---

## Domain Unit Tests

```csharp
public class OrderTests
{
    [Fact]
    public void Create_ShouldCreatePendingOrder_WithItems()
    {
        var customer = CustomerFixture.AnyCustomer();
        var items = new List<OrderItemDto> { new("product-1", 2) };

        var order = Order.Create(customer, items);

        order.Status.Should().Be(OrderStatus.Pending);
        order.Items.Should().HaveCount(1);
        order.DomainEvents.Should().ContainSingle(e => e is OrderCreatedEvent);
    }

    [Fact]
    public void Confirm_ShouldThrow_WhenAlreadyConfirmed()
    {
        var order = OrderFixture.ConfirmedOrder();

        var act = () => order.Confirm();

        act.Should().Throw<InvalidOperationException>();
    }
}
```

---

## Test Fixtures

```csharp
public static class OrderFixture
{
    public static Order AnyPendingOrder() =>
        Order.Create(CustomerFixture.AnyCustomer(), [new OrderItemDto("product-test", 1)]);

    public static Order ConfirmedOrder()
    {
        var order = AnyPendingOrder();
        order.Confirm();
        return order;
    }
}

public static class CustomerFixture
{
    public static Customer AnyCustomer() =>
        Customer.Create("Test User", "test@example.com");
}
```

---

## Naming Convention

```
MethodName_ShouldExpectedBehavior_WhenCondition

Examples:
  Handle_ShouldCreateOrder_WhenCustomerExists
  Handle_ShouldThrow_WhenCustomerNotFound
  Confirm_ShouldChangeStatus_WhenPending
  CreateOrder_ShouldReturn201_WithValidRequest
```

---

## Collection Fixture for Integration Tests

When multiple test classes share the same `ApiFactory` (to avoid spinning up multiple containers):

```csharp
[CollectionDefinition(nameof(IntegrationTestCollection))]
public class IntegrationTestCollection : ICollectionFixture<ApiFactory> { }

[Collection(nameof(IntegrationTestCollection))]
public class OrdersIntegrationTests
{
    // factory is shared across all tests in this collection
}
```
