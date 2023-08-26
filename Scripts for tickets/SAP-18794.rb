manager_id = Manager.where(reseller_id: 458).find_by(name: "Sergey Rogozhin").id
corrections = Correction.where(manager_id: manager_id)
CSV.open("/home/app/core/support/kiryl/SAP-18794.csv", "wb") do |csv|
  csv << ["correction_id", "account_id", "account_inn", "correction_total", "created_at", "approved_at"]
  corrections.map do |correction|
    correction_id = correction.id
    account_id = correction.account.id
    account_inn = correction.account.inn
    correction_total = correction.total
    created_at = correction.created_at
    approved_at = correction.approved_at
    csv <<  [
      correction_id,
      account_id,
      account_inn,
      correction_total,
      created_at,
      approved_at
    ]
  end
end