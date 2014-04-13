Controller = require 'members-area/app/controller'
async = require 'members-area/node_modules/async'

class PaymentsController extends Controller
  @before 'setActiveNagivationId'
  @before 'requireAdmin'

  index: (done) ->
    @req.models.Payment.find()
    .order("id", "ASC")
    .all (err, @payments) =>
      done(err)

  view: (done) ->
    @req.models.Payment.get @req.params.id, (err, @payment) =>
      done(err)

  requireAdmin: (done) ->
    unless @req.user and @req.user.can('admin')
      err = new Error "Permission denied"
      err.status = 403
      return done err
    else
      done()

  setActiveNagivationId: ->
    @activeNavigationId = 'members-area-payments'

module.exports = PaymentsController

