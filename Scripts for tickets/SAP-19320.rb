CSV.open("/home/app/core/support/kiryl/SAP-19320.csv", "wb") do |csv|
  csv << ['reseller_id', 'reseller_name', 'account_id', 'account_name', 'account_inn', 'csp_subscription_ids']
  Reseller.find(581).children.map do |reseller|
    plan_categories_ids = reseller.plan_categories.where("key = 'microsoft_csp_monthly' or key = 'microsoft_csp_annually' or key = 'microsoft_azure'").ids
    plans_ids = Plan.where(plan_category_id: plan_categories_ids).ids
    reseller.accounts.map do |account|
      subscriptions = account.subscriptions.where(plan_id: plans_ids).where(status: :active)
      if !subscriptions.empty?
        csv << [
          reseller.id,
          reseller.name,
          account.id,
          account.name,
          account.inn,
          subscriptions.ids
        ]
      end
    end
  end
end