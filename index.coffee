module.exports =
  initialize: (done) ->
    @hook 'models:initialize', ({models}) =>
      models.Payment.hasOne 'transaction', models.Transaction, reverse: 'payments', autoFetch: false

    done()
