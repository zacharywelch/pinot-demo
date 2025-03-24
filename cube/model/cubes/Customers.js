cube(`Customers`, {
  sql_table: `customers`,

  measures: {
    count: {
      type: `count`
    }
  },

  dimensions: {
    teamId: {
      sql: `team_id`,
      type: `number`
    },

    customerId: {
      sql: `customer_id`,
      type: `number`,
      primaryKey: true
    },

    email: {
      sql: `email`,
      type: `string`
    },

    eventAt: {
      sql: `event_at`,
      type: `time`
    }
  }
})
