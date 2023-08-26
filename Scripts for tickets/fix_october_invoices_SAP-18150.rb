module BillingProcesses
  class CreatePostpayPayments
    def invoices
      @invoices = account.invoices.postpay.in_closed.with_close_type(:platform).where(to_date: Date.new(2022,11,1))
    end
  end
end
def fix_october_invoices()
  @log_payment = []
  plan_cat_ids = PlanCategory.where("key = ?", "csp_p1y_monthly_nce").ids
  plans_ids = Plan.where(plan_category_id: plan_cat_ids).ids
  subs_ids = Subscription.where(plan_id: plans_ids).ids
  charges = Charge::Base.where(subscription_id: subs_ids).where("operate_from > ? and operate_from < ?", Date.new(2022,10,1), Date.new(2022,11,1)).where("close_date > ?", Date.new(2022,11,1))
  charges.map do |charge|
    p "Charge #{charge.id} to process. Subscription #{charge.subscription.id}"
    old_close_date = charge.close_date
    invoice = charge.account.invoices.where("from_date = ? and to_date = ? and close_type = ?", Date.new(2022,10,1), Date.new(2022,11,1), "platform").last
    subscription = charge.subscription
    if InvoiceSubscription.where(invoice_id: invoice.id, subscription_id: subscription.id).empty?
      invoice_subscription = InvoiceSubscription.create!(
      invoice_id: invoice.id,
      subscription_id: subscription.id
      )
      invoice_subscription.save!
    end
    charge.update(close_date: Date.new(2022,11,1))
    invoice.recalculate_total!
    payment = invoice.payments.last
    account = charge.account
    if payment == nil
      BillingProcesses::CreatePostpayPayments.new(account.id).run
      p "Payment for Invoice #{invoice.id} was created"
    elsif payment.status == "waiting_for_payment"
      payment.update(total: invoice.total)
    else
      @log_payment << payment
    end
    Note.create!(
      content: "Close_date for charge #{charge.id} was changed form #{old_close_date} on #{charge.close_date}",
      noteable_id: subscription.id,
      noteable_type: "Subscription",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: subscription.account_id)
  end
  if !@log_payment.empty?
    p "Платежи которые не были пересчитаны #{@log_payment.pluck(:id)}"
  end
end
