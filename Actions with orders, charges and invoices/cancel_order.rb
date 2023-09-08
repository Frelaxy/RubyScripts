def cancel_order(order_id, ticket_id = '')
  order = Order.find(order_id)
  order.charges.in_blocked.each(&:to_deleted)
  order.payment.update(status: :cancelled) if !order.payment.nil? && order.payment.status != "completed"
  order.items.each(&:to_closed)
  order.update(status: :cancelled)
  Note.create!(
    content: "Order cancelled manually | #{ticket_id}",
    noteable_id: order.id,
    noteable_type: "Order",
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    account_id: order.account.id
  )
end