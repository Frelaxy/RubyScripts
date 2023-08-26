def rename_accounts_from_csv()
  f = "/home/app/core/support/sap-18054.csv"
  table = []
  CSV.foreach(f, headers: true) do |row|
    table << row.to_hash
  end
  table.each do |item|
    account = Account.find(item["account_id"].to_i)
    p "Account to process: #{account.id}"
    old_name = account.primary_name
    new_name = item["new_name"]
    account.update(primary_name: new_name)
    account.update(name: new_name)
    p "For account #{account.id} name was changed from #{old_name} to #{new_name}"
    Note.create!(
      content: "Account name was changed from #{old_name} to #{new_name} | SAP-18054",
      noteable_id: account.id,
      noteable_type: "Account",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: account.id)
  end
end