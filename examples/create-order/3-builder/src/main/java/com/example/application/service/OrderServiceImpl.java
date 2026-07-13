package com.example.application.service;

import com.example.api.dto.CreateOrderRequest;
import com.example.api.dto.OrderResponse;
import com.example.domain.exception.CustomerNotFoundException;
import com.example.domain.model.Order;
import com.example.domain.repository.OrderRepository;
import com.example.domain.repository.CustomerRepository;
import com.example.domain.service.StockService;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderServiceImpl implements OrderService {

    private final OrderRepository orderRepository;
    private final CustomerRepository customerRepository;
    private final StockService stockService;

    public OrderServiceImpl(
            OrderRepository orderRepository,
            CustomerRepository customerRepository,
            StockService stockService) {
        this.orderRepository = orderRepository;
        this.customerRepository = customerRepository;
        this.stockService = stockService;
    }

    @Override
    @Transactional
    public OrderResponse createOrder(CreateOrderRequest request) {
        if (!customerRepository.existsById(request.customerId())) {
            throw new CustomerNotFoundException(request.customerId());
        }

        // BR-002: stock is validated before accepting the order; prices come
        // from the catalog, never from the client
        List<Order.Item> pricedItems = stockService.validateAndPrice(request.items());

        Order order = Order.create(request.customerId(), pricedItems);
        Order saved = orderRepository.save(order);

        return new OrderResponse(saved.getId(), saved.getStatus().name(), saved.getTotalCents());
    }
}
