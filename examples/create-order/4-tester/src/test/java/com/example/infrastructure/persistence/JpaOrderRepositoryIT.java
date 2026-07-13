package com.example.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.example.domain.model.Order;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
@DisplayName("JpaOrderRepository")
class JpaOrderRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired
    private JpaOrderRepository repository;

    @Test
    @DisplayName("save then findById returns the order with its items intact")
    void saveAndFindById_shouldReturnOrderWithItems_whenOrderIsPersisted() {
        // Arrange
        Order order = Order.create(UUID.randomUUID(), List.of(
                new Order.Item(UUID.randomUUID(), 3, 1000L),
                new Order.Item(UUID.randomUUID(), 1, 2500L)));

        // Act
        repository.save(order);
        Optional<Order> found = repository.findById(order.getId());

        // Assert
        assertThat(found).isPresent();
        assertThat(found.get().getStatus()).isEqualTo(Order.Status.PENDING);
        assertThat(found.get().getTotalCents()).isEqualTo(5500L);
        assertThat(found.get().getItems()).hasSize(2);
    }
}
