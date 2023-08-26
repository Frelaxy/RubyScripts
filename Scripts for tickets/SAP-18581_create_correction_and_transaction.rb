def create_correction_and_transaction(invoice_id)
  invoice = Invoice::Base.find(invoice_id)
  sum_for_correction = calculate_amout_from_charges(invoice.id) - invoice.total
  correction = Correction.create!(
    account_id: invoice.account.id,
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    total: sum_for_correction,
    comment: "SAP-18581",
    status: "approved",
    is_included_in_invoice: false,
    period_from: nil,
    period_to: nil,
    approved_at: Date.today,
    subscription_id: nil
  )
  balance_transaction = BalanceTransaction.create!(
    account_id: correction.account.id,
    total: correction.total,
    balance: correction.account.balance + correction.total,
    transactionable_id: correction.id,
    transactionable_type: "Correction"
  )
  account = invoice.account
  account.balance = account.balance + balance_transaction.total
  account.save!
  Note.create!(
    content: "Balance has been corrected by the #{sum_for_correction} | SAP-18581",
    noteable_id: account.id,
    noteable_type: "Account",
    manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
    account_id: account.id
  )
end
invoice_for_fix.map do |invoice|
  create_correction_and_transaction(invoice.id)
  invoice.account.update(status: :active)
end