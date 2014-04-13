module.exports =
  initialize: (done) ->
    @app.addRoute 'all', '/admin/payments', 'members-area-payments#payments#index'
    @app.addRoute 'all', '/admin/payments/:id', 'members-area-payments#payments#view'

    @hook 'navigation_items', @modifyNavigationItems.bind(this)
    @hook 'models:initialize', ({models}) =>
      models.Payment.hasOne 'transaction', models.Transaction, reverse: 'payments', autoFetch: false

    done()

  modifyNavigationItems: ({addItem}) ->
    addItem 'admin',
      title: 'Payments'
      id: 'members-area-payments-payments-index'
      href: '/admin/payments'
      permissions: ['admin']
      priority: 20
