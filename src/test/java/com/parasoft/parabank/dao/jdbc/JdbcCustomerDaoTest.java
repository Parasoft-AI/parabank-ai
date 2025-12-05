package com.parasoft.parabank.dao.jdbc;

import java.lang.reflect.Field;

import org.junit.Test;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcDaoSupport;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.support.JdbcDaoSupport;
import org.springframework.test.util.ReflectionTestUtils;

import com.parasoft.parabank.dao.CustomerDao;
import com.parasoft.parabank.domain.Address;
import com.parasoft.parabank.domain.Customer;
import com.parasoft.parabank.test.util.AbstractParaBankDataSourceTest;

import jakarta.annotation.Resource;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
/**
 * @req PAR-13
 *
 */
public class JdbcCustomerDaoTest extends AbstractParaBankDataSourceTest
{
    private static final String FIRST_NAME = "Steve";

    private static final String LAST_NAME = "Jobs";

    private static final String STREET = "1 Infinite Loop";

    private static final String CITY = "Cupertino";

    private static final String STATE = "CA";

    private static final String ZIP_CODE = "95014";

    private static final String PHONE_NUMBER = "1-800-MY-APPLE";

    private static final String SSN = "666-66-6666";

    private static final String USERNAME = "steve";

    private static final String PASSWORD = "jobs";

    @Resource(name = "customerDao")
    private CustomerDao customerDao;

    private Customer customer;

    private void defaultCustomerTest(final Customer customer)
    {
        assertEquals(12212, customer.getId());
        assertEquals("John", customer.getFirstName());
        assertEquals("Smith", customer.getLastName());
        assertEquals("1431 Main St", customer.getAddress().getStreet());
        assertEquals("Beverly Hills", customer.getAddress().getCity());
        assertEquals("CA", customer.getAddress().getState());
        assertEquals("90210", customer.getAddress().getZipCode());
        assertEquals("310-447-4121", customer.getPhoneNumber());
        assertEquals("622-11-9999", customer.getSsn());
        assertEquals("john", customer.getUsername());
        assertEquals("demo", customer.getPassword());
    }

    @Override
    public void onSetUp() throws Exception
    {
        super.onSetUp();
        customer = new Customer();
        customer.setFirstName(FIRST_NAME);
        customer.setLastName(LAST_NAME);
        final Address address = new Address();
        address.setStreet(STREET);
        address.setCity(CITY);
        address.setState(STATE);
        address.setZipCode(ZIP_CODE);
        customer.setAddress(address);
        customer.setPhoneNumber(PHONE_NUMBER);
        customer.setSsn(SSN);
        customer.setUsername(USERNAME);
        customer.setPassword(PASSWORD);
    }

    public void setCustomerDao(final CustomerDao customerDao)
    {
        this.customerDao = customerDao;
    }

    @Test
    public void testCreateCustomer()
    {
        final int id = customerDao.createCustomer(customer);
        assertEquals("wrong expected id?", 12434, id);

        final Customer customer = customerDao.getCustomer(id);
        assertFalse(this.customer == customer);
        assertEquals(this.customer, customer);
    }

    @Test
    public void testGetCustomer()
    {
        Customer customer = customerDao.getCustomer(12212);
        defaultCustomerTest(customer);

        try {
            customer = customerDao.getCustomer(-1);
            fail("did not throw expected DataAccessException");
        } catch (final DataAccessException e) {
        }
    }

    @Test
    public void testGetCustomerBySSN()
    {
        final Customer customer = customerDao.getCustomer("622-11-9999");
        defaultCustomerTest(customer);

        assertNull(customerDao.getCustomer(null));
        assertNull(customerDao.getCustomer("foo"));
        assertNull(customerDao.getCustomer("111-11-1111"));
    }

    @Test
    public void testGetCustomerByUsername()
    {
        final Customer customer = customerDao.getCustomer("john", "demo");
        defaultCustomerTest(customer);

        assertNull(customerDao.getCustomer(null, null));
        assertNull(customerDao.getCustomer("john", null));
        assertNull(customerDao.getCustomer(null, "demo"));
        assertNull(customerDao.getCustomer("john", "foo"));
        assertNull(customerDao.getCustomer("foo", "demo"));
        assertNull(customerDao.getCustomer("foo", "bar"));
    }

    @Test
    public void testUpdateCustomer()
    {
        final int id = customerDao.createCustomer(customer);

        final Customer customer = customerDao.getCustomer(id);
        assertFalse(this.customer == customer);
        assertEquals(this.customer, customer);

        customer.setFirstName(customer.getFirstName() + "*");
        customer.setLastName(customer.getLastName() + "*");
        final Address address = new Address();
        address.setStreet(customer.getAddress().getStreet() + "*");
        address.setCity(customer.getAddress().getCity() + "*");
        address.setState(customer.getAddress().getState() + "*");
        address.setZipCode(customer.getAddress().getZipCode() + "*");
        customer.setAddress(address);
        customer.setPhoneNumber(customer.getPhoneNumber() + "*");
        customer.setSsn(customer.getSsn() + "*");
        customer.setUsername(customer.getUsername() + "*");
        customer.setPassword(customer.getPassword() + "*");

        customerDao.updateCustomer(customer);

        final Customer updatedCustomer = customerDao.getCustomer(id);
        assertFalse(customer == updatedCustomer);
        assertFalse(this.customer.equals(updatedCustomer));
        assertEquals(customer, updatedCustomer);
    }

    /**
     * Parasoft Jtest UTA: Test for createCustomer(Customer)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#createCustomer(Customer)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testCreateCustomer_WithNamedParameterJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        NamedParameterJdbcTemplate namedParameterJdbcTemplateValue = mock(NamedParameterJdbcTemplate.class);
        ReflectionTestUtils.setField(underTest, "namedParameterJdbcTemplate", namedParameterJdbcTemplateValue);
        JdbcSequenceDao sequenceDao = mock(JdbcSequenceDao.class);
        underTest.setSequenceDao(sequenceDao);

        // When
        Customer customer2 = mockCustomer();
        int result = underTest.createCustomer(customer2);

    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of Customer
     */
    private static Customer mockCustomer() throws Throwable
    {
        Customer customer2 = mock(Customer.class);
        int getIdResult = 0; // UTA: configured value
        when(customer2.getId()).thenReturn(getIdResult);
        return customer2;
    }

    /**
     * Parasoft Jtest UTA: Test for createCustomer(Customer)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#createCustomer(Customer)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testCreateCustomer_WithJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        JdbcTemplate jdbcTemplateValue = mockJdbcTemplate();
        ReflectionTestUtils.setField(underTest, "jdbcTemplate", jdbcTemplateValue);

        // When
        Customer customer2 = mockCustomer2();
        int result = underTest.createCustomer(customer2);

    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of JdbcTemplate
     */
    private static JdbcTemplate mockJdbcTemplate() throws Throwable
    {
        JdbcTemplate jdbcTemplateValue = mock(JdbcTemplate.class);
        Object queryForObjectResult = new Object(); // UTA: default value
        when(jdbcTemplateValue.queryForObject(nullable(String.class), (RowMapper) any(), nullable(Object[].class))).thenReturn(queryForObjectResult);
        return jdbcTemplateValue;
    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of Customer
     */
    private static Customer mockCustomer2() throws Throwable
    {
        Customer customer2 = mock(Customer.class);
        int getIdResult = 1; // UTA: configured value
        when(customer2.getId()).thenReturn(getIdResult);

        String getSsnResult = "123-45-6789"; // UTA: LLM default value
        when(customer2.getSsn()).thenReturn(getSsnResult);
        return customer2;
    }

    /**
     * Parasoft Jtest UTA: Test for createCustomer(Customer)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#createCustomer(Customer)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testCreateCustomer_WithJdbcTemplateAndNamedParameterJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        JdbcTemplate jdbcTemplateValue = mockJdbcTemplate2();
        ReflectionTestUtils.setField(underTest, "jdbcTemplate", jdbcTemplateValue);
        NamedParameterJdbcTemplate namedParameterJdbcTemplateValue = mock(NamedParameterJdbcTemplate.class);
        ReflectionTestUtils.setField(underTest, "namedParameterJdbcTemplate", namedParameterJdbcTemplateValue);
        JdbcSequenceDao sequenceDao = mock(JdbcSequenceDao.class);
        underTest.setSequenceDao(sequenceDao);

        // When
        Customer customer2 = mockCustomer3();
        int result = underTest.createCustomer(customer2);

    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of JdbcTemplate
     */
    private static JdbcTemplate mockJdbcTemplate2() throws Throwable
    {
        JdbcTemplate jdbcTemplateValue = mock(JdbcTemplate.class);
        Object queryForObjectResult = null; // UTA: configured value
        when(jdbcTemplateValue.queryForObject(nullable(String.class), (RowMapper) any(), nullable(Object[].class))).thenReturn(queryForObjectResult);
        return jdbcTemplateValue;
    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of Customer
     */
    private static Customer mockCustomer3() throws Throwable
    {
        Customer customer2 = mock(Customer.class);
        int getIdResult = 1; // UTA: configured value
        when(customer2.getId()).thenReturn(getIdResult);

        String getSsnResult = "123-45-6789"; // UTA: LLM default value
        when(customer2.getSsn()).thenReturn(getSsnResult);
        return customer2;
    }

    /**
     * Parasoft Jtest UTA: Test for createCustomer(Customer)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#createCustomer(Customer)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testCreateCustomer_WithMultipleMockTemplates() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        JdbcTemplate jdbcTemplateValue = mockJdbcTemplate3();
        ReflectionTestUtils.setField(underTest, "jdbcTemplate", jdbcTemplateValue);
        NamedParameterJdbcTemplate namedParameterJdbcTemplateValue = mock(NamedParameterJdbcTemplate.class);
        ReflectionTestUtils.setField(underTest, "namedParameterJdbcTemplate", namedParameterJdbcTemplateValue);
        JdbcSequenceDao sequenceDao = mock(JdbcSequenceDao.class);
        underTest.setSequenceDao(sequenceDao);

        // When
        Customer customer2 = mockCustomer4();
        int result = underTest.createCustomer(customer2);

    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of JdbcTemplate
     */
    private static JdbcTemplate mockJdbcTemplate3() throws Throwable
    {
        JdbcTemplate jdbcTemplateValue = mock(JdbcTemplate.class);
        DataAccessException exception = mock(DataAccessException.class);
        when(jdbcTemplateValue.queryForObject(nullable(String.class), (RowMapper) any(), nullable(Object[].class))).thenThrow(exception);
        return jdbcTemplateValue;
    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of Customer
     */
    private static Customer mockCustomer4() throws Throwable
    {
        Customer customer2 = mock(Customer.class);
        int getIdResult = 1; // UTA: configured value
        when(customer2.getId()).thenReturn(getIdResult);

        String getSsnResult = "123-45-6789"; // UTA: LLM default value
        when(customer2.getSsn()).thenReturn(getSsnResult);
        return customer2;
    }

    /**
     * Parasoft Jtest UTA: Test for getCustomer(int)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#getCustomer(int)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCustomer_ById() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        JdbcTemplate jdbcTemplateValue = mock(JdbcTemplate.class);
        ReflectionTestUtils.setField(underTest, "jdbcTemplate", jdbcTemplateValue);

        // When
        int id = 101; // UTA: LLM default value
        Customer result = underTest.getCustomer(id);

    }

    /**
     * Parasoft Jtest UTA: Test for getCustomer(String)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#getCustomer(String)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCustomer_BySSN_WithJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        JdbcTemplate jdbcTemplateValue = mock(JdbcTemplate.class);
        ReflectionTestUtils.setField(underTest, "jdbcTemplate", jdbcTemplateValue);

        // When
        String ssn = "123-45-6789"; // UTA: LLM default value
        Customer result = underTest.getCustomer(ssn);

    }

    /**
     * Parasoft Jtest UTA: Test for getCustomer(String)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#getCustomer(String)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCustomer_BySSN_WithoutJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();

        // When
        String ssn = "123-45-6789"; // UTA: LLM default value
        Customer result = underTest.getCustomer(ssn);

    }

    /**
     * Parasoft Jtest UTA: Test for getCustomer(String, String)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#getCustomer(String, String)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCustomer_ByUsernameAndPassword_WithJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        JdbcTemplate jdbcTemplateValue = mock(JdbcTemplate.class);
        ReflectionTestUtils.setField(underTest, "jdbcTemplate", jdbcTemplateValue);

        // When
        String username = "john_doe"; // UTA: LLM default value
        String password = "securePass123"; // UTA: LLM default value
        Customer result = underTest.getCustomer(username, password);

    }

    /**
     * Parasoft Jtest UTA: Test for getCustomer(String, String)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#getCustomer(String, String)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testGetCustomer_ByUsernameAndPassword_WithoutJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();

        // When
        String username = "john_doe"; // UTA: LLM default value
        String password = "securePass123"; // UTA: LLM default value
        Customer result = underTest.getCustomer(username, password);

    }

    /**
     * Parasoft Jtest UTA: Test for setSequenceDao(JdbcSequenceDao)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#setSequenceDao(JdbcSequenceDao)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testSetSequenceDao_WithMock() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();

        // When
        JdbcSequenceDao sequenceDao = mock(JdbcSequenceDao.class);
        underTest.setSequenceDao(sequenceDao);

    }

    /**
     * Parasoft Jtest UTA: Test for updateCustomer(Customer)
     *
     * @see com.parasoft.parabank.dao.jdbc.JdbcCustomerDao#updateCustomer(Customer)
     * @author sv-jenkins
     */
    @Test(timeout = 5000)
    public void testUpdateCustomer_WithNamedParameterJdbcTemplate() throws Throwable
    {
        // Given
        JdbcCustomerDao underTest = new JdbcCustomerDao();
        NamedParameterJdbcTemplate namedParameterJdbcTemplateValue = mock(NamedParameterJdbcTemplate.class);
        ReflectionTestUtils.setField(underTest, "namedParameterJdbcTemplate", namedParameterJdbcTemplateValue);

        // When
        Customer customer2 = mockCustomer5();
        underTest.updateCustomer(customer2);

    }

    /**
     * Parasoft Jtest UTA: Helper method to generate and configure mock of Customer
     */
    private static Customer mockCustomer5() throws Throwable
    {
        Customer customer2 = mock(Customer.class);
        String getFirstNameResult = "John"; // UTA: LLM default value
        when(customer2.getFirstName()).thenReturn(getFirstNameResult);
        return customer2;
    }
}
