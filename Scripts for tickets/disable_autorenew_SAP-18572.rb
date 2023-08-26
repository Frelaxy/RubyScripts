resellers_ids = %w[419 349 337]
plan_categories_ids = PlanCategory.where(reseller_id: resellers_ids).where("key = 'microsoft_csp_annually' or key ='microsoft_csp_monthly'").ids
plans_ids = Plan.where(plan_category_id: plan_categories_ids).ids
subscriptions = Subscription.where(plan_id: plans_ids).where.not(status: :deleted).where("expiration_date > ?", Date.new(2023,2,12))
subscriptions.update(auto_renewal: false)
subscriptions.update(auto_renewal_disabled: true)