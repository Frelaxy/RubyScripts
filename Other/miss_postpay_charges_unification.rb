# Объединить списания, когда уже поздняк метаться
def miss_postpay_charges_unification(sub_id, date, ticket)
    subscription = Subscription.find(sub_id)
    charges = subscription.charges.where(operate_to: date)
    last_charge = charges.order(created_at: :desc).first
    charge = Charge::ExternalResource.new
    charge.subscription = subscription
    charge.account = subscription.account
    charge.reseller = subscription.reseller
    charge.additional_params = last_charge.additional_params
    charge.price = last_charge.price
    charge.operate_from = charges.order(operate_from: :asc).first.operate_from
    charge.operate_to = charges.order(operate_to: :desc).first.operate_to
    charge.currency_rate = Currencies::PlanCurrencyRateFinder.new(subscription.plan).call
    charge.currency = charge.currency_rate.to
    charge.quantity = 1
    charge.amount = charges.sum(&:amount)
    charge.duration = charges.sum(&:duration)
    charge.close_date = charges.order(close_date: :desc).first.close_date
    charge.discount_amount = charges.sum(&:discount_amount)
    charge.status = :blocked
    charges.update_all(status: :deleted)
    charge.save!
    charge.reload;
    ChargeCloser.new(charge).call
    Note.create!(
      content: "#{date.strftime("%B")} charges unification | SAP-#{ticket}",
      noteable_id: subscription.id,
      noteable_type: "Subscription",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: subscription.account.id
    );
    puts " ---------------------------------------------"
    puts " Charge ID #{charge.id} was created and closed";
    puts " ---------------------------------------------"
  end
  # Вызов на примере Azure Plan в РБ
  plan_classes = PlanClass.where(key: :microsoft_azure).where(reseller_id: 458)
  plans = Plan.where(plan_class_id: plan_classes.ids)
  subscriptions = plans.last.subscriptions.where.not(status: "deleted")
  [12273, 12022, 8013, 12021, 12401]
  date = Date.new(2022,8,28)
  miss_postpay_charges_unification(12021, date, 17828)
  miss_postpay_charges_unification(12401, date, 17828)