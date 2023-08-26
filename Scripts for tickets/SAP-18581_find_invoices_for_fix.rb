def calculate_amout_from_charges(invoice_id)
  invoice = Invoice::Base.find(invoice_id)
  amount_from_charges = 0.0e1
  invoice.charges.map do |charge|
    amount_from_charges = amount_from_charges + charge.amount
  end
  return amount_from_charges
end
invoices_october = Invoice::Base.where("from_date > ? and from_date < ?", Date.new(2022,8,30), Date.new(2022,12,1))
invoices_for_fix_with_payment_completed = invoices_october.select do |invoice|
  invoice.total != calculate_amout_from_charges(invoice.id) && !invoice.payments.empty? && invoice.payments.last.status == "completed"
end
invoices_for_fix = invoices_for_fix_with_payment_completed.reject do |invoice|
  if !invoice.account.corrections.empty?
    invoice.account.corrections.select do |correction|
      correction.total == calculate_amout_from_charges(invoice.id) - invoice.total
    end
  end
end
invoices_for_fix.map do |invoice|
  sum_for_correction =  calculate_amout_from_charges(invoice.id) - invoice.total
  puts "invoice_id:#{invoice.id} reseller_id:#{invoice.reseller_id} account_id:#{invoice.account.id} account_balance:#{invoice.account.balance} sum_for_correction:#{sum_for_correction}"
end