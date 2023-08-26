def complete_order(order_id, ticket_id = '')
  order = Order.find(order_id)
  subscription = order.subscription

  if order.type == "RenewalOrder"
    next_expiration = order.renew_item.operation_value
    if subscription.billing_type == "csp_annual"
      next_paid_to = next_expiration
    else
      next_paid_to = order.charges.last.operate_to
    end
  elsif order.type == "ProlongOrder"
    next_paid_to = order.charges.last.operate_to
  end

  def actualize_price_by_order(order)
    uniq_resource_charges = order.charges.uniq { |c| c.subscription_resource_id }
    uniq_resource_charges.map do |c|
      new_price = c.price
      c.subscription_resource.update(price: new_price)
    end
  end

  items = order.items.where(target_type: "SubscriptionResource")

  def change_resource_additional(item)
    subscription_resource = SubscriptionResource.find(item.target_id)
    if item.type == "ProvisioningItem::Upgrade"
      subscription_resource.additional += item.operation_value
    elsif item.type == "ProvisioningItem::Downgrade"
      subscription_resource.additional -= item.operation_value
    end
    subscription_resource.save
  end

  def refund(order)
    refunded_ids = order.params.dig("refunded_charge_ids")
      if refunded_ids
        Charge::Base.where(id: refunded_ids).map do |c|
          c.update(status: :refunded)
        end
      end
  end

  def close_charges(order)
    if order.subscription.billing_type == "csp_annual"
      ::ChargesManager::ManualCloser.new(subscription: order.subscription).close
    elsif order.subscription.billing_type == "monthly_commitment_monthly_interval"
      order.charges.in_blocked.map do |c|
        ChargeCloser.new(c).call
        c.update(close_date: order.operate_from)
      end
    end
  end

  ActiveRecord::Base.transaction do
    order.items.update(status: :completed)
    order.update(status: :completed)
    order.charges.in_new.each {|c| c.update(status: :blocked)}

    if order.type == "ChangeOrder"
      refund(order)
    end

    close_charges(order)

    if order.type == "RenewalOrder"
      actualize_price_by_order(order)
      subscription.expiration_date = next_expiration
      subscription.paid_to = next_paid_to
    elsif order.type == "ProlongOrder"
      subscription.paid_to = next_paid_to
    end
    subscription.status = :active
    subscription.save
    subscription.applications.update(service_status: :running)
    if subscription.applications.last.origin.respond_to?(:service_status)
      subscription.applications.last.origin.update(service_status: :running)
    end

    items.each { |item| change_resource_additional(item) }

    Note.create!(
      content: "Order was completed manually | #{ticket_id}",
      noteable_id: order.id,
      noteable_type: "Order",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: order.account.id
    );
  end
end

def cancel_order(order_id, ticket_id = '')
  order = Order.find(order_id)
  order.charges.update(status: :deleted)
  order.payment.update(status: :cancelled) if !order.payment.nil? && order.payment.status != "completed"
  order.items.update(status: :cancelled)
  order.update(status: :cancelled)
  Note.create!(
    content: "Order cancelled manually | #{ticket_id}",
    noteable_id: order.id,
    noteable_type: "Order",
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    account_id: order.account.id
  )
end

def get_subscriptions_info_from_ms(subscription_id)
  p "Getting subscription information"
  subscription = Subscription.find(subscription_id)
  reseller = subscription.reseller
  if subscription.status != "deleted"
    application = subscription.applications.last
  elsif
    application = Application.where(subscription_id: subscription.id).last
  end
  origin = application.origin if application
  app_template = origin.application_template if origin
  ms_customer_id = origin.customer.tid if origin != nil && origin.customer != nil
  p "Opening session through plugin #{application.origin_type}"
  if application != nil && application.origin_type == "Plugin::MicrosoftCspProducts::Application"
    partner_center_client = Plugin::MicrosoftCspProducts::API::PartnerCenter.new(app_template, reseller)
  elsif application != nil && application.origin_type == "Plugin::Office365::Application"
    partner_center_client = Plugin::Office365::API::PartnerCenter.new(app_template, reseller)
  elsif application != nil && application.origin_type == "Plugin::ManualProvisioning::Application"
  end
  p "Getting subscriptions information from MS"
  if partner_center_client
    ms_subscriptions = partner_center_client.customer_subscriptions(ms_customer_id).fetch(:items, [])
  end
  ms_id = subscription.applications.last.origin.external_id
  ms_subscriptions.select { |s| s[:id] == ms_id }
end

def recalculate_charge_with_actual_price(charge_id)
  charge = Charge::Base.find(charge_id)
  new_price = charge.subscription_resource.price
  charge.price = new_price
  charge.recalculate_amount!
  charge.save
end

def cancel_external_erp_approve(invoice_id)
  invoice = Invoice::Postpay.find(invoice_id)
  activity = invoice.activities.select {|activity| activity.parameters["document_id"] != nil}.last
  old_document_id = activity.parameters["document_id"][0]
  ActiveRecord::Base.transaction do
    invoice.update(approval_date: nil)
    ExternalInvoice.where(invoice_id: invoice.id).last.delete
    invoice.update(document_id: old_document_id)
    invoice.payments.update_all(expiration_date: nil, external_total: nil, external_currency: nil)
  end
end



##  load '/home/app/core/support/kiryl/load_scripts.rb'