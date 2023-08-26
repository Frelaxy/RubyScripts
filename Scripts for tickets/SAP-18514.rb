payments = Payment.where("status = 'waiting_for_payment' and created_at > ? and created_at < ?", Date.new(2022,12,31), Date.new(2023,2,1)).where(expiration_date: nil)
payments_for_change = payments.select { |payment| payment.reseller.id == 393}
payments_for_change.map do |payment|
    payment.update(status: :cancelled)
end
