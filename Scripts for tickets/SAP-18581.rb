def balance_corrector(acc_id, amount)
    account = Account.find(acc_id)
    account.balance = account.balance + amount
    account.save
    account.update(status: :active)
    Note.create!(
        content: "Balance has been corrected by the #{amount} | SAP-18581",
        noteable_id: account.id,
        noteable_type: "Account",
        manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
        account_id: account.id
      );
end