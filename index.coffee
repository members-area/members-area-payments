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

  handleRoleSubscription: ->
    # IMPORTANT: this method runs in the context of a RoleController instance
    if @req.method is 'POST' and !@data.action
      subscriptionRequired = !!@data.subscriptionRequired
      delete @data.subscriptionRequired
      @role.setMeta {subscriptionRequired}
