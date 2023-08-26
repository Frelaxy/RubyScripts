def cancel_transaction_and_refund_money(charge_id)
  charge = Charge::Base.find(charge_id)
  ResellerCharge.where(charge_id: charge.id).delete_all
  charge.balance_transaction.delete
  account = charge.account
  account.balance = account.balance + charge.amount
  account.save
  charge.update(status: :blocked)
end