package com.parasoft.bookstore;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
/**
 * Parasoft Jtest UTA: Test class for CartManager
 *
 * @see com.parasoft.bookstore.CartManager
 * @author sv-jenkins
 */
public class CartManagerTest
{

    /**
     * Parasoft Jtest UTA: Test for addNewItemToCart(Order)
     *
     * @see com.parasoft.bookstore.CartManager#addNewItemToCart(Order)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testAddNewItemToCart_EmptyCart() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        Order order = mock(Order.class);
        underTest.addNewItemToCart(order);

        // Then - assertions for this instance of CartManager
        assertEquals(0, underTest.getCartId());
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for getCart()
     *
     * @see com.parasoft.bookstore.CartManager#getCart()
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCart_EmptyCart() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        Map<Integer, List<Order>> result = underTest.getCart();

        // Then - assertions for result of method getCart()
        assertNotNull(result);
        assertEquals(0, result.size());

        // Then - assertions for this instance of CartManager
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for getCartId()
     *
     * @see com.parasoft.bookstore.CartManager#getCartId()
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCartId_DefaultValue() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        int result = underTest.getCartId();

        // Then - assertions for result of method getCartId()
        assertEquals(0, result);

        // Then - assertions for this instance of CartManager
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for getCartSize()
     *
     * @see com.parasoft.bookstore.CartManager#getCartSize()
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCartSize_EmptyCart() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        int result = underTest.getCartSize();

        // Then - assertions for result of method getCartSize()
        assertEquals(0, result);

        // Then - assertions for this instance of CartManager
        assertEquals(0, underTest.getCartId());
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for getItem()
     *
     * @see com.parasoft.bookstore.CartManager#getItem()
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetItem_NoItems() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        List<Order> result = underTest.getItem();

        // Then - assertions for result of method getItem()
        assertNull(result);

        // Then - assertions for this instance of CartManager
        assertEquals(0, underTest.getCartId());

    }

    /**
     * Parasoft Jtest UTA: Test for getStaticCart_Id()
     *
     * @see com.parasoft.bookstore.CartManager#getStaticCart_Id()
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetStaticCart_Id_Id_DefaultValue() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        int result = underTest.getStaticCart_Id();

        // Then - assertions for result of method getStaticCart_Id()
        assertEquals(0, result);

        // Then - assertions for this instance of CartManager
        assertEquals(0, underTest.getCartId());
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for performAction()
     *
     * @see com.parasoft.bookstore.CartManager#performAction()
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testPerformAction_WithOneItem() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();
        List<Order> list = new ArrayList<Order>(); // UTA: default value
        Order item = mock(Order.class);
        list.add(item);
        underTest.setItem(list);

        // When
        int result = underTest.performAction();

        // Then - assertions for result of method performAction()
        assertEquals(1, result);

        // Then - assertions for this instance of CartManager
        assertEquals(0, underTest.getCartId());
        assertNotNull(underTest.getItem());
        assertEquals(1, underTest.getItem().size());

    }

    /**
     * Parasoft Jtest UTA: Test for removeEmptyMappings()
     *
     * @see com.parasoft.bookstore.CartManager#removeEmptyMappings()
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testRemoveEmptyMappings_NoEffect() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        underTest.removeEmptyMappings();

        // Then - assertions for this instance of CartManager
        assertEquals(0, underTest.getCartId());
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for removeOrder(int)
     *
     * @see com.parasoft.bookstore.CartManager#removeOrder(int)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testRemoveOrder_NonExistentOrder() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        int cartId = 101; // UTA: LLM default value
        boolean result = underTest.removeOrder(cartId);

        // Then - assertions for result of method removeOrder(int)
        assertFalse(result);

        // Then - assertions for this instance of CartManager
        assertEquals(0, underTest.getCartId());
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for setCartId(int)
     *
     * @see com.parasoft.bookstore.CartManager#setCartId(int)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testSetCartId_ValidId() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        int cartId = 101; // UTA: LLM default value
        underTest.setCartId(cartId);

        // Then - assertions for this instance of CartManager
        assertEquals(101, underTest.getCartId());
        assertNull(underTest.getItem());

    }

    /**
     * Parasoft Jtest UTA: Test for updateExistingItem(int, int, int)
     *
     * @see com.parasoft.bookstore.CartManager#updateExistingItem(int, int, int)
     * @author sv-jenkins
     */
    @Test(timeout = 5000, expected = Exception.class)
    public void testUpdateExistingItem_ExceptionThrown() throws Throwable
    {
        // Given
        CartManager underTest = new CartManager();

        // When
        int cartId = 101; // UTA: LLM default value
        int itemId = 202; // UTA: LLM default value
        int quantity = 3; // UTA: LLM default value
        underTest.updateExistingItem(cartId, itemId, quantity);

    }

}
