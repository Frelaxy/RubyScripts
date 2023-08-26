# отмена списания с транзакцией и удаление рессейлерских списаний
def cancel_charge_and_transaction(charge_id)
  charge = Charge::Base.find(charge_id)
  charge.update(status: :deleted)
  transaction_id = charge.balance_transaction.id
  BalanceTransaction.find(transaction_id).destroy!
  #ResellerChargesBuilder.new(charge).call   # генерация новый ресейллерских чарджей
  ResellerCharge.where(charge_id: charge_id).delete_all
  amount = charge.amount
  account = charge.account
  account.balance = account.balance + amount
  account.save
end