def fix_priority_for_plans()
  plan_cat_ids = PlanCategory.where.not(key: ["microsoft_azure_plan", "microsoft_azure"]).ids
  plans_ids = Plan.where(plan_category_id: plan_cat_ids).ids
  progressbar = ProgressBar.create(total: PlanResource.where(plan_id: plans_ids, name: ["Лицензия", "Users"]).where.not(priority: 100).count, format: 'Processed: %P%% (%c out of %C) |%B|');
  PlanResource.where(plan_id: plans_ids, name: ["Лицензия", "Users"]).where.not(priority: 100).find_each do |resource|
    resource.update(priority: 100)
    progressbar.increment
  end
end