resellers_ids = Reseller.ids
def unpublic_plans(reseller_id)
  reseller = Reseller.find(reseller_id)
  plan_category_ids = reseller.plan_categories.where("key = 'microsoft_csp_monthly' or key = 'microsoft_csp_annually'").ids
  product_categories_ids = reseller.product_categories.where("key = 'office_365_academic'").ids
  products_ids = reseller.products.where(product_category: product_categories_ids).ids
  plans = reseller.plans.where(plan_category: plan_category_ids, public: true).where.not(product_id: products_ids)
  plans.update(public: false)
end
resellers_ids.each do |reseller_id|
  puts "Обрабатывается Reseller #{reseller_id}"
  unpublic_plans(reseller_id)
end