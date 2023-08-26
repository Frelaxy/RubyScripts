def complete_co_and_activate_sub(order_id, ticket_id = 'SAP-19080')
  order = Order.find order_id
  ActiveRecord::Base.transaction do
    order.subscription.manual_operations.last.update(status: :declined) if order.subscription.manual_operations.last
    order.items.update(status: :completed)
    order.update(status: :completed)
    order.items.map do |i|
      sr = i.target
        if i.type == "ProvisioningItem::Downgrade"
          sr.additional -= i.operation_value.to_i
          sr.save
        end
        if i.type == "ProvisioningItem::Upgrade"
          sr.additional += i.operation_value.to_i
          sr.save
        end
    end
    order.subscription.update(status: :active)
    order.subscription.applications.update(service_status: :running)
    if order.subscription.applications.last.origin.respond_to?(:service_status)
      order.subscription.applications.last.origin.update(service_status: :running)
    end
    order.charges(&:to_blocked)
    refunded_ids = order.params.dig("refunded_charge_ids") 
    if refunded_ids
      Charge::Base.where(id: refunded_ids).map do |c|
        c.update(status: :refunded)
      end
    end
  end
  Note.create!(
    content: "Order was completed manually | #{ticket_id}",
    noteable_id: order.id,
    noteable_type: "Order",
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    account_id: order.account.id);
end