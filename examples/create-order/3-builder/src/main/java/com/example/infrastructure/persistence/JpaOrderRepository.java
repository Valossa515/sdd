package com.example.infrastructure.persistence;

import com.example.domain.model.Order;
import com.example.domain.repository.OrderRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface JpaOrderRepository extends JpaRepository<Order, UUID>, OrderRepository {

    @Override
    Order save(Order order);

    @Override
    Optional<Order> findById(UUID id);
}
