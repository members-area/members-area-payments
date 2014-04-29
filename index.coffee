RoleController = require 'members-area/app/controllers/role'

module.exports =
  initialize: (done) ->
    @app.addRoute 'all', '/admin/payments', 'members-area-payments#payments#index'
    @app.addRoute 'all', '/admin/payments/:id', 'members-area-payments#payments#view'
    @app.addRoute 'all', '/subscription', 'members-area-payments#subscription#view'

    @hook 'navigation_items', @modifyNavigationItems.bind(this)
    @hook 'models:initialize', ({models}) =>
      models.Payment.hasOne 'transaction', models.Transaction, reverse: 'payments', autoFetch: false
      models.Payment.hasOne 'user', models.User, reverse: 'payments', autoFetch: true
    @hook 'render-role-edit', @renderRoleSubscription.bind(this)
    @hook 'render-person-view', @renderPersonPayments.bind(this)

    RoleController.before @handleRoleSubscription, only: ['edit']

    done()

  modifyNavigationItems: ({addItem}) ->
    addItem 'user',
      title: 'Subscription'
      id: 'members-area-payments-subscription-view'
      href: '/subscription'
      permissions: []
      priority: 42
    addItem 'admin',
      title: 'Payments'
      id: 'members-area-payments'
      href: '/admin/payments'
      permissions: ['admin']
      priority: 20

  renderRoleSubscription: (options) ->
    {controller, $} = options
    $topNode = $('.control-group').eq(0)
    checked = if !!controller.role.meta.subscriptionRequired then " checked='checked'" else ""
    $newNode = $ """
      <div class="control-group">
        <label for="name" class="control-label">Subscription required</label>
        <div class="controls">
          <input type="checkbox" name="subscriptionRequired"#{checked}> Check this if a subscription is required from people with this role.
        </div>
      </div>
      """
    $topNode.after $newNode
    return

  renderPersonPayments: (options, done) ->
    {controller, $} = options
    return done() unless controller.loggedInUser.can 'admin'
    controller.req.models.Payment.find()
    .order("-when")
    .where(user_id: controller.user.id)
    .limit(20)
    .run (err, payments) =>
      $main = $(".main").eq(0)

      rows = []
      if payments?.length
        for payment in payments
          rows.push """
            <tr class="#{if payment.include then "" else "text-error"}">
              <td>#{payment.when.toISOString().substr(0, 10)}</td>
              <td>#{payment.type}</td>
              <td>£#{(payment.amount/100).toFixed(2)}</td>
              <td>#{payment.period_from.toISOString().substr(0, 10)}</td>
              <td>#{payment.period_count}</td>
              <td>#{if payment.include then "✔" else "✘"}</td>
            </tr>
            """
      else
        rows.push """
          <tr>
            <td colspan="6">
              No records to display
            </td>
          </tr>
          """

      paidUntil = controller.user.paidUntil

      midnightThisMorning = new Date()
      midnightThisMorning.setHours(0)
      midnightThisMorning.setMinutes(0)
      midnightThisMorning.setSeconds(0)

      midnightAMonthAgo = new Date +midnightThisMorning
      midnightAMonthAgo.setMonth(midnightAMonthAgo.getMonth()-1)

      overdueDays = (midnightThisMorning - paidUntil)/(24*60*60*1000)

      statusText =
        if +paidUntil > +midnightThisMorning
          "<p class='text-success'>Payments up to date (next due: #{paidUntil.toISOString().substr(0,10)})</p>"
        else if +paidUntil > midnightAMonthAgo
          "<p class='text-warning'>Payments #{overdueDays} days overdue</p>"
        else
          "<p class='text-error'>Payments #{Math.floor overdueDays/7} weeks overdue</p>"

      $main.append """
        <h3>Payments</h3>
        #{statusText}
        <table class="table table-striped">
          <tr>
            <th>Payment Date</th>
            <th>Type</th>
            <th>Amount</th>
            <th>From</th>
            <th>Duration (months)</th>
            <th>Worked?</th>
          </tr>
          #{rows.join("\n")}
        </table>
        """
      done()
      return

  handleRoleSubscription: ->
    # IMPORTANT: this method runs in the context of a RoleController instance
    if @req.method is 'POST' and !@data.action
      subscriptionRequired = !!@data.subscriptionRequired
      delete @data.subscriptionRequired
      @role.setMeta {subscriptionRequired}
