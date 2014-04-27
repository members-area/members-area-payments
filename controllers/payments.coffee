LoggedInController = require 'members-area/app/controllers/logged-in'
async = require 'members-area/node_modules/async'

class PaymentsController extends LoggedInController
  @before 'setActiveNagivationId'
  @before 'requireAdmin'
  @before 'saveSettings', only: ['index']

  index: (done) ->
    @req.models.Payment.find()
    .order("-id")
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

  saveSettings: (done) ->
    if @req.method is 'POST'
      @plugin.set @data, done
    else
      @data = @plugin.get()
      done()

module.exports = PaymentsController
