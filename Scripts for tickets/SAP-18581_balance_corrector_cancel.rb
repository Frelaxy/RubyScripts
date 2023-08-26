def balance_corrector_cancell(acc_id, amount)
  account = Account.find(acc_id)
  account.balance = account.balance - amount
  account.save!
  note = Note.where(account_id: acc_id).last
  note.delete
end