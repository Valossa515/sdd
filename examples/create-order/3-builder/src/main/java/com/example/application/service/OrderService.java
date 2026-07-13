package com.example.application.service;

import com.example.api.dto.CreateOrderRequest;
import com.example.api.dto.OrderResponse;

public interface OrderService {

    OrderResponse createOrder(CreateOrderRequest request);
}
