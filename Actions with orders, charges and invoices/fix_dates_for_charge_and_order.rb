# Метод для исправления заказа и всех его сущностей на другие даты:
# Обратить внимание на даты закрытия списания при csp annual. Они закрываются датой завершения заказа, а не через год!
def fix_charge_dates_and_recalulate(charge_id, date_from = nil, date_to = nil)
  @charge = Charge::Base.find(charge_id)

  def set_new_dates(date_from, date_to)
    @charge.operate_from = date_from
    @charge.operate_to = date_to
    @charge.close_date = @charge.subscription.billing_type == 'csp_annual' ? @charge.order.closed_at.to_date : date_to if !@charge.new?
  end
  
  def recalculate_charge
    @charge.recalculate_duration!
    @charge.recalculate_amount!
    @charge.save!
    puts "Charge recalculated and saved"
  end
  
  def regenerate_reseller_charges
    if @charge.status == 'closed'
      ResellerCharge.where(charge_id: @charge.id).delete_all
      ResellerChargesBuilder.new(@charge).call
      puts "Reseller charges regenerated"
    else
      puts "Charge is not closed, no need to regenerate Reseller charges"
    end
  end

  ActiveRecord::Base.transaction do
    set_new_dates(date_from, date_to)
    recalculate_charge
    regenerate_reseller_charges
    puts "Order ID: #{@charge.order.id}"
  end
end

# __________________________________________________________________________________________
charge_id = 1019419
date_from = Date.new(2023,10,10)
date_to = Date.new(2024,10,10)
fix_charge_dates_and_recalulate(charge_id, date_from, date_to)


charges_ids = [1019599, 1019600]
charges_ids.each {|charge_id| fix_charge_dates_and_recalulate(charge_id, new_dates = nil)}