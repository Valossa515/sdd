package com.example.api.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.api.dto.OrderResponse;
import com.example.application.service.OrderService;
import com.example.domain.exception.CustomerNotFoundException;
import com.example.domain.exception.EmptyOrderException;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(OrderController.class)
@DisplayName("POST /api/v1/orders")
class OrderControllerIT {

    private static final String VALID_BODY = """
            {
              "customerId": "c0a80101-0000-0000-0000-000000000001",
              "items": [
                { "productId": "c0a80101-0000-0000-0000-00000000000a", "quantity": 3 },
                { "productId": "c0a80101-0000-0000-0000-00000000000b", "quantity": 1 }
              ]
            }
            """;

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @Test
    @DisplayName("returns 201 with Location header when request is valid")
    void post_shouldReturn201WithLocation_whenRequestIsValid() throws Exception {
        UUID orderId = UUID.randomUUID();
        when(orderService.createOrder(any()))
                .thenReturn(new OrderResponse(orderId, "PENDING", 5500L));

        mockMvc.perform(post("/api/v1/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "/api/v1/orders/" + orderId))
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.totalCents").value(5500));
    }

    @Test
    @DisplayName("returns 404 CUSTOMER_NOT_FOUND when customer does not exist")
    void post_shouldReturn404_whenCustomerDoesNotExist() throws Exception {
        when(orderService.createOrder(any()))
                .thenThrow(new CustomerNotFoundException(
                        UUID.fromString("c0a80101-0000-0000-0000-000000000001")));

        mockMvc.perform(post("/api/v1/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(VALID_BODY))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("CUSTOMER_NOT_FOUND"));
    }

    @Test
    @DisplayName("returns 422 EMPTY_ORDER when items list is empty")
    void post_shouldReturn422_whenItemsListIsEmpty() throws Exception {
        when(orderService.createOrder(any())).thenThrow(new EmptyOrderException());

        mockMvc.perform(post("/api/v1/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "customerId": "c0a80101-0000-0000-0000-000000000001", "items": [] }
                                """))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("EMPTY_ORDER"));
    }
}
