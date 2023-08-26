def change_auto_renewal()
  plan_categories_ids = Reseller.find(628).plan_categories.where("key = 'kaspersky' or key = 'kaspersky_lab'").ids
  plans = Reseller.find(628).plans.where(plan_category_id: plan_categories_ids)
  counter = 0
  plans.map do |plan|
    if plan.sku.include? 'Yearly'
      puts "Обрабатывается план #{plan.id}"
      counter += 1
      plan.update(auto_renewal_disabled: true)
      plan.update(auto_renewal: false)
      if plan.subscriptions.count != 0
        plan.subscriptions.update(auto_renewal_disabled: true)
        plan.subscriptions.update(auto_renewal: false)
      end
    end
  end
  p "Обработано #{counter} планов из #{plans.count}"
end