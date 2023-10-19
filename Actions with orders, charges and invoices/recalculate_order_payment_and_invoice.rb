def recalculate_order_payment_invoice(order_id)
  @order = Order.find(order_id)

  def update_order_details
    OrderDetailsGenerator.new(@order).generate!
    @order.recalculate_total!
    @order.recalculate_net_cost!
    puts "Order information updated"
  end

  def recalculate_payment
    charge = @order.charges.last
    if !@order.payment.nil? && @order.payment.status != ['completed', 'paid_from_balance']
      @order.payment.update(total: @order.total)
      puts "Payment for ORDER recalculated"
    else
      puts "Payment for ORDER not recalculated because it's completed or not available"
    end
  end

  def recalculate_invoice
    charge = @order.charges.where(status: :closed).last
    if charge
      invoice = charge.account.invoices.select { |invoice| invoice.charges.include? charge }.last
      if invoice
        if invoice.closed? and invoice.payments.last.try(:status) == 'waiting_for_payment' and !invoice.approval_date?
          invoice.recalculate_total!
          invoice.save!
          invoice.payments.last.update(total: invoice.total)
          puts "Invoice #{invoice.id} and payment recalculated"
        elsif invoice.approval_date?
          puts "Invoice #{invoice.id} not recalculated because Invoice is 'approved'"
        else
          puts "Invoice #{invoice.id} and payment not recalculated because invoice is not closed or payment not 'waiting_for_payment'"
          puts "Invoice status: #{invoice.status}, Payment status: #{invoice.try(:payments).try(:last).try(:status)}"
        end
      else
        puts "Invoice not found, need to check this problem"
      end
    end
  end
  
  ActiveRecord::Base.transaction do
    update_order_details
    recalculate_payment
    recalculate_invoice
  end
end