invoices = Invoice::Base.where("from_date > ? and from_date < ?", Date.new(2022,7,30), Date.new(2023,2,5)).where(status: :closed)
def calculate_amout_from_charges(invoice_id)
    invoice = Invoice::Base.find(invoice_id)
    amount_from_charges = 0.0e1
    invoice.charges.map do |charge|
      amount_from_charges = amount_from_charges + charge.amount
    end
    return amount_from_charges
end
invoices_for_fix = invoices.select do |invoice|
    invoice.total != calculate_amout_from_charges(invoice.id)
end
invoices_for_fix_where_payment_not_completed = invoices_for_fix.select do |invoice|
    !invoice.payments.last.nil?
end
invoices_for_fix_where_payment_not_completed.map do |invoice|
    puts "To process invoice: #{invoice.id} reseller: #{invoice.reseller.id}"
    invoice.recalculate_total!
    new_total = invoice.total
    invoice.payments.last.update(total: new_total)
end


#оплаченные проблемные инвойсы (испорченные мной)
irb(main):052:0> invoices_for_fix_where_payment_completed.pluck(:id,:reseller_id)
=> [[138870, 452], [139362, 530], [142835, 530], [142725, 456], [142730, 452], [142955, 536], [145049, 456]]
invoices_for_fix_where_payment_completed = invoices_for_fix.select do |invoice|
    if !invoice.payments.last.nil?
        invoice.payments.last.status == "completed"
    end
end
invoices_for_fix_where_payment_completed.map do |invoice|
    difference = invoice.payments.last.total - calculate_amout_from_charges(invoice.id)
    puts "Inv:#{invoice.id} Res: #{invoice.reseller.id} Оплата произведена на #{invoice.payments.last.total} Сумма списаний #{calculate_amout_from_charges(invoice.id)} Разница #{difference}"
end


#Пересчитанные инвойсы
To process invoice: 139713 reseller: 536
To process invoice: 143157 reseller: 392
To process invoice: 138986 reseller: 536
To process invoice: 139191 reseller: 536
To process invoice: 138952 reseller: 393
To process invoice: 138910 reseller: 536
To process invoice: 139174 reseller: 536
To process invoice: 138979 reseller: 536
To process invoice: 139226 reseller: 393
To process invoice: 139418 reseller: 536
To process invoice: 139406 reseller: 536
To process invoice: 139662 reseller: 536
To process invoice: 139594 reseller: 536
To process invoice: 142788 reseller: 536
To process invoice: 142829 reseller: 400
To process invoice: 142792 reseller: 536
To process invoice: 139360 reseller: 393
To process invoice: 142809 reseller: 393
To process invoice: 138962 reseller: 536
To process invoice: 139474 reseller: 337
To process invoice: 139689 reseller: 392
To process invoice: 142897 reseller: 536
To process invoice: 138802 reseller: 536
To process invoice: 142750 reseller: 460
To process invoice: 142724 reseller: 393
To process invoice: 142803 reseller: 536
To process invoice: 142745 reseller: 536
To process invoice: 142928 reseller: 392
To process invoice: 143004 reseller: 460
To process invoice: 142761 reseller: 393
To process invoice: 143526 reseller: 337
To process invoice: 139238 reseller: 337
To process invoice: 143599 reseller: 392
To process invoice: 143458 reseller: 392
To process invoice: 143302 reseller: 392
To process invoice: 142937 reseller: 460
To process invoice: 143497 reseller: 536
To process invoice: 139290 reseller: 536
To process invoice: 139259 reseller: 536
To process invoice: 139326 reseller: 536
To process invoice: 139519 reseller: 536
To process invoice: 143572 reseller: 393
To process invoice: 139096 reseller: 536
To process invoice: 143164 reseller: 536
To process invoice: 143534 reseller: 392
To process invoice: 143061 reseller: 536
To process invoice: 143440 reseller: 460
To process invoice: 139710 reseller: 536
To process invoice: 139265 reseller: 392
To process invoice: 143234 reseller: 536
To process invoice: 143270 reseller: 536
To process invoice: 142395 reseller: 447
To process invoice: 143066 reseller: 536
To process invoice: 143333 reseller: 536
To process invoice: 143457 reseller: 393
To process invoice: 143285 reseller: 337
To process invoice: 142712 reseller: 536
To process invoice: 142781 reseller: 536
To process invoice: 143372 reseller: 447
To process invoice: 143373 reseller: 536
To process invoice: 143394 reseller: 392
To process invoice: 142924 reseller: 456
To process invoice: 143551 reseller: 536
To process invoice: 143151 reseller: 393
To process invoice: 143611 reseller: 392
To process invoice: 142887 reseller: 393
To process invoice: 143015 reseller: 392
To process invoice: 142663 reseller: 460
To process invoice: 143231 reseller: 460
To process invoice: 142838 reseller: 460
To process invoice: 142965 reseller: 536
To process invoice: 143369 reseller: 460
To process invoice: 142657 reseller: 536
To process invoice: 143552 reseller: 536
To process invoice: 143567 reseller: 536
To process invoice: 143190 reseller: 536
To process invoice: 142870 reseller: 536
To process invoice: 143175 reseller: 536
To process invoice: 144722 reseller: 536
To process invoice: 144960 reseller: 536
To process invoice: 144913 reseller: 536
To process invoice: 142665 reseller: 456
To process invoice: 145983 reseller: 536
To process invoice: 145174 reseller: 392
To process invoice: 146038 reseller: 393
To process invoice: 142954 reseller: 536
To process invoice: 143098 reseller: 536
To process invoice: 143548 reseller: 447
To process invoice: 143118 reseller: 536
To process invoice: 139240 reseller: 536
To process invoice: 143484 reseller: 536
To process invoice: 147930 reseller: 536
To process invoice: 148071 reseller: 393
To process invoice: 147126 reseller: 536
To process invoice: 147083 reseller: 337