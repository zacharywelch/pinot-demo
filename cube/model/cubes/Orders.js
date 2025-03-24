cube(`Orders`, {
  sql_table: `orders`,

  joins: {
    Customers: {
      relationship: `belongsTo`,
      sql: `${CUBE}.customer_id = ${Customers}.customer_id`
    }
  },

  measures: {
    count: {
      type: `count`
    },

    totalRevenue: {
      sql: `order_total`,
      type: `sum`,
      title: `Total Revenue`
    }
  },

  dimensions: {
    tenantId: {
      sql: `team_id`,
      type: `number`
    },

    orderId: {
      sql: `order_id`,
      type: `string`,
      primaryKey: true
    },

    paymentMethod: {
      sql: `payment_method`,
      type: `string`
    },

    customerId: {
      sql: `customer_id`,
      type: `number`
    },

    customerEmail: {
      sql: `customer_email`,
      type: `string`
    },

    orderTotal: {
      sql: `order_total`,
      type: `number`
    },

    eventAt: {
      sql: `event_at`,
      type: `time`
    }
  }
})
