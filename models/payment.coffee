module.exports = (db, models) ->
  Payment = db.define 'payment', {
    id:
      type: 'number'
      serial: true
      primary: true

    user_id:
      type: 'number'
      required: true

    transaction_id:
      type: 'number'
      required: false

    type:
      type: 'text'
      required: true

    amount:
      type: 'number'
      required: true

    status:
      type: 'text'
      required: true

    include:
      type: 'boolean'
      required: true

    when:
      type: 'date'
      required: true

    period_from:
      type: 'date'
      required: true

    period_count:
      type: 'number'
      required: true

    meta:
      type: 'object'
      required: true
      defaultValue: {}

    createdAt:
      type: 'date'
      required: true
      time: true

    updatedAt:
      type: 'date'
      required: true
      time: true

  },
    timestamp: true
    hooks: db.applyCommonHooks {}

  Payment.modelName = 'Payment'
  return Payment
