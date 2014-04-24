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

  Payment.getUserPaidUntil = (user, suggestedDate = new Date()) ->
    # Start with the date of the transaction / today.
    nextPaymentDate = suggestedDate

    # If they have a role that requires subscription then go to that's start date instead.
    for roleUser in user.activeRoleUsers ? []
      if roleUser.role?.meta?.subscriptionRequired
        if +roleUser.approved < +nextPaymentDate
          nextPaymentDate = roleUser.approved

    # Finally if they've already got a paidUntil ahead of this then use that.
    # NOTE: we don't just use paidUntil in case there was a break in membership/PAYG/etc.
    if +user.meta.paidUntil > +nextPaymentDate
      nextPaymentDate = user.meta.paidUntil

    return nextPaymentDate

  Payment.modelName = 'Payment'
  return Payment
