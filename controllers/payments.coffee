LoggedInController = require 'members-area/app/controllers/logged-in'
async = require 'members-area/node_modules/async'

class PaymentsController extends LoggedInController
  @before 'setActiveNagivationId'
  @before 'requireAdmin'
  @before 'saveSettings', only: ['index']
  @before 'getPayment', only: ['view']
  @before 'updatePayment', only: ['view']

  index: (done) ->
    @req.models.Payment.find({}, {autoFetch: true})
    .order("-id")
    .all (err, @payments) =>
      done(err)

  view: ->

  getPayment: (done) ->
    @req.models.Payment.get @req.params.id, autoFetch: true, (err, @payment) =>
      done(err)

  updatePayment: (done) ->
    return done() unless @req.method is 'POST' and @req.body.period_count
    periodCount = parseInt(@req.body.period_count, 10)
    diff = periodCount - @payment.period_count
    return done() if diff is 0
    payment = @payment
    payment.period_count = periodCount
    payment.save (err) =>
      return done err if err
      paidUntil = new Date +payment.user.paidUntil
      paidUntil.setMonth(paidUntil.getMonth() + diff)
      payment.user.paidUntil = paidUntil
      payment.user.save (err) =>
        return done err if err
        midnight = new Date +payment.period_from
        midnight.setHours(0)
        midnight.setMinutes(0)
        midnight.setSeconds(0)
        @req.models.Payment.find()
          .where("id <> ? AND user_id = ? AND period_from >= ? AND include = ?", [payment.id, payment.user_id, midnight, true])
          .all (err, paymentsToRewrite) =>
            return done err if err
            rewrite = (p, done) ->
              from = new Date +p.period_from
              from.setMonth(from.getMonth() + diff)
              p.period_from = from
              p.save done
            async.eachSeries paymentsToRewrite, rewrite, ->
              console.log "Changed #{payment.user.fullname}'s paid until by #{diff} month(s) at admin's request"
              done null, payment

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
