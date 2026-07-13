package com.example.application.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.api.dto.CreateOrderRequest;
import com.example.api.dto.OrderResponse;
import com.example.domain.exception.CustomerNotFoundException;
import com.example.domain.exception.EmptyOrderException;
import com.example.domain.model.Order;
import com.example.domain.repository.CustomerRepository;
import com.example.domain.repository.OrderRepository;
import com.example.domain.service.StockService;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderServiceImpl")
class OrderServiceImplTest {

    private static final UUID CUSTOMER_ID = UUID.fromString("c0a80101-0000-0000-0000-000000000001");
    private static final UUID PRODUCT_A = UUID.fromString("c0a80101-0000-0000-0000-00000000000a");
    private static final UUID PRODUCT_B = UUID.fromString("c0a80101-0000-0000-0000-00000000000b");

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private StockService stockService;

    @InjectMocks
    private OrderServiceImpl service;

    private CreateOrderRequest validRequest() {
        return new CreateOrderRequest(CUSTOMER_ID, List.of(
                new CreateOrderRequest.Item(PRODUCT_A, 3),
                new CreateOrderRequest.Item(PRODUCT_B, 1)));
    }

    private List<Order.Item> pricedItems() {
        return List.of(
                new Order.Item(PRODUCT_A, 3, 1000L),
                new Order.Item(PRODUCT_B, 1, 2500L));
    }

    @Test
    @DisplayName("createOrder should return PENDING order with id when input is valid")
    void createOrder_shouldReturnPendingOrderWithId_whenInputIsValid() {
        // Arrange
        when(customerRepository.existsById(CUSTOMER_ID)).thenReturn(true);
        when(stockService.validateAndPrice(any())).thenReturn(pricedItems());
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        // Act
        OrderResponse response = service.createOrder(validRequest());

        // Assert
        assertThat(response.id()).isNotNull();
        assertThat(response.status()).isEqualTo("PENDING");
    }

    @Test
    @DisplayName("createOrder should throw CustomerNotFoundException when customer does not exist")
    void createOrder_shouldThrowCustomerNotFound_whenCustomerDoesNotExist() {
        // Arrange
        when(customerRepository.existsById(CUSTOMER_ID)).thenReturn(false);

        // Act / Assert
        assertThatThrownBy(() -> service.createOrder(validRequest()))
                .isInstanceOf(CustomerNotFoundException.class);
        verify(orderRepository, never()).save(any());
    }

    @Test
    @DisplayName("createOrder should throw EmptyOrderException when priced items are empty")
    void createOrder_shouldThrowEmptyOrder_whenItemsAreEmpty() {
        // Arrange
        when(customerRepository.existsById(CUSTOMER_ID)).thenReturn(true);
        when(stockService.validateAndPrice(any())).thenReturn(List.of());

        // Act / Assert
        assertThatThrownBy(() -> service.createOrder(validRequest()))
                .isInstanceOf(EmptyOrderException.class);
        verify(orderRepository, never()).save(any());
    }

    @Test
    @DisplayName("createOrder should calculate total from prices times quantities (BR-001)")
    void createOrder_shouldCalculateTotalFromPricesTimesQuantities_whenOrderIsCreated() {
        // Arrange
        when(customerRepository.existsById(CUSTOMER_ID)).thenReturn(true);
        when(stockService.validateAndPrice(any())).thenReturn(pricedItems());
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        // Act
        OrderResponse response = service.createOrder(validRequest());

        // Assert: 3 × 1000 + 1 × 2500 = 5500
        assertThat(response.totalCents()).isEqualTo(5500L);
    }
}
