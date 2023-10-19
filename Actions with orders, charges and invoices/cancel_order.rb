def cancel_order(order_id, ticket_id = '')
  order = Order.find(order_id)
  ActiveRecord::Base.transaction do
    order.charges.each do |charge|
      charge.update(status: :deleted)
      ResellerCharge.where(charge_id: charge.id).delete_all if charge.closed?
      puts "требуется удалить транзакцию и проверить баланс | списание: #{charge.id}" if charge.balance_transaction
    end
    invoice = order.charges.last.account.invoices.select { |invoice| invoice.charges.include? order.charges.last }.last
    puts "требуется пересчитать инвойс: #{invoice.id}" if invoice && invoice.closed?
    order.payment.update(status: :cancelled) if order.payment && !order.payment.completed?
    order.items.update(status: :cancelled)
    order.update(status: :cancelled)
    scenario = Scenario.where(relation_data: {"order_id"=>order_id}).try(:last)
    scenario.update(status: :failed) if scenario && !scenario.completed?
    Note.create!(
      content: "Order cancelled manually | #{ticket_id}",
      noteable_id: order.id,
      noteable_type: "Order",
      manager_id: Current.manager.nil? ? nil : Current.manager.id,
      account_id: order.account.id
    )
  end
end