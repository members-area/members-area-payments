RoleController = require 'members-area/app/controllers/role'
cheerio = require 'members-area/node_modules/cheerio'

module.exports =
  initialize: (done) ->
    @app.addRoute 'all', '/admin/payments', 'members-area-payments#payments#index'
    @app.addRoute 'all', '/admin/payments/:id', 'members-area-payments#payments#view'

    @hook 'navigation_items', @modifyNavigationItems.bind(this)
    @hook 'models:initialize', ({models}) =>
      models.Payment.hasOne 'transaction', models.Transaction, reverse: 'payments', autoFetch: false
    @hook 'render-role-edit', @renderRoleSubscription.bind(this)
    @hook 'render-person-view', @renderPersonPayments.bind(this)

    RoleController.before @handleRoleSubscription, only: ['edit']

    done()

  modifyNavigationItems: ({addItem}) ->
    addItem 'admin',
      title: 'Payments'
      id: 'members-area-payments'
      href: '/admin/payments'
      permissions: ['admin']
      priority: 20

  renderRoleSubscription: (options) ->
    {controller, html} = options
    $ = cheerio.load(html)
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
    options.html = $.html()
    return

  renderPersonPayments: (options, done) ->
    {controller, html} = options
    return done() unless controller.loggedInUser.can 'admin'
    controller.req.models.Payment.find()
    .order("when", "DESC")
    .where(user_id: controller.user.id)
    .limit(20)
    .run (err, payments) =>
      $ = cheerio.load(html)
      $main = $(".main").eq(0)

      rows = []
      if payments?.length
        for payment in payments
          rows.push """
            <tr>
              <td>#{payment.when.toISOString().substr(0, 10)}</td>
              <td>#{payment.type}</td>
              <td>£#{(payment.amount/100).toFixed(2)}</td>
              <td>#{payment.period_from.toISOString().substr(0, 10)}</td>
              <td>#{payment.period_count}</td>
            </tr>
            """
      else
        rows.push """
          <tr>
            <td colspan="5">
              No records to display
            </td>
          </tr>
          """

      $main.append """
        <h3>Payments</h3>
        <table class="table table-striped">
          <tr>
            <th>Payment Date</th>
            <th>Type</th>
            <th>Amount</th>
            <th>From</th>
            <th>Duration (months)</th>
          </tr>
          #{rows.join("\n")}
        </table>
        """
      options.html = $.html()
      done()
      return

  handleRoleSubscription: ->
    # IMPORTANT: this method runs in the context of a RoleController instance
    if @req.method is 'POST' and !@data.action
      subscriptionRequired = !!@data.subscriptionRequired
      delete @data.subscriptionRequired
      @role.setMeta {subscriptionRequired}
