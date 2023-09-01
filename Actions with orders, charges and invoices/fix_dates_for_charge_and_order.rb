# Метод для исправления заказа и всех его сущностей на другие даты:
# Обратить внимание на даты закрытия списания при csp annual. Они закрываются датой закрытия, а не через год!
def fix_charge_dates_and_recalulate(charge_id, date_from = nil, date_to = nil, new_dates = true)
  @charge = Charge::Base.find(charge_id)
  ActiveRecord::Base.transaction do
    set_new_dates(date_from, date_to) if whithout_new_dates
    recalculate_charge
    regenerate_reseller_charges
    update_order_details
    recalculate_payment_and_invoice
    puts "Order ID: {@charge.order.id}"
  end

  def set_new_dates(date_from, date_to)
    @charge.operate_from = date_from
    @charge.operate_to = date_to
    if @charge.subscription.billing_type == 'csp_annual'
      p "You have to ckeck a close date for this charge. It's #{@charge.close_date} now"
    elsif
      @charge.close_date = date_to
    end
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
end

# __________________________________________________________________________________________
charge_id = 1002724
date_from = Date.new(2023,8,11)
date_to = Date.new(2023,9,1)
fix_charge_dates_and_recalulate(charge_id, date_from, date_to)

fix_charge_dates_and_recalulate(charge_id, new_dates = false) # if just recalculate charge and related objects

charges_ids = [990911, 990910, 990909, 990908]
charges_ids.each {|charge_id| fix_charge_dates_and_recalulate(charge_id, date_from, date_to)}