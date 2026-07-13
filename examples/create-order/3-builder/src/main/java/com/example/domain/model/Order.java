package com.example.domain.model;

import com.example.domain.exception.EmptyOrderException;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Embeddable;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "orders")
public class Order {

    public enum Status { PENDING, CONFIRMED, CANCELLED }

    @Id
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    @Column(name = "total_cents", nullable = false)
    private long totalCents;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "order_items", joinColumns = @JoinColumn(name = "order_id"))
    private List<Item> items;

    protected Order() {
        // JPA only
    }

    private Order(UUID id, UUID customerId, Status status, long totalCents, List<Item> items) {
        this.id = id;
        this.customerId = customerId;
        this.status = status;
        this.totalCents = totalCents;
        this.items = items;
    }

    public static Order create(UUID customerId, List<Item> items) {
        if (items == null || items.isEmpty()) {
            throw new EmptyOrderException();
        }
        // BR-001: total is always recalculated from item prices × quantities
        long total = items.stream()
                .mapToLong(item -> item.priceCents() * item.quantity())
                .sum();
        return new Order(UUID.randomUUID(), customerId, Status.PENDING, total, List.copyOf(items));
    }

    @Embeddable
    public record Item(
            @Column(name = "product_id", nullable = false) UUID productId,
            @Column(nullable = false) int quantity,
            @Column(name = "price_cents", nullable = false) long priceCents) {
    }

    public UUID getId() {
        return id;
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public Status getStatus() {
        return status;
    }

    public long getTotalCents() {
        return totalCents;
    }

    public List<Item> getItems() {
        return items;
    }
}
