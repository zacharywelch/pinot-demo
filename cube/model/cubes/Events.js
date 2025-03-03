cube(`Events`, {
  sql: `select * from events`,

  measures: {
    count: {
      type: `count`,
      title: `Number of Events`
    },

    avgValue: {
      sql: `value`,
      type: `avg`,
      title: `Average Value`
    }
  },

  dimensions: {
    id: {
      sql: `id`,
      type: `number`,
      primaryKey: true
    },

    message: {
      sql: `message`,
      type: `string`
    },

    value: {
      sql: `value`,
      type: `number`
    },

    timestamp: {
      sql: `timestamp`,
      type: `time`
    }
  }
})
