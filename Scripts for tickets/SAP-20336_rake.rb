
task restarting_failed_rn_orders_google_SAP_20336 :environment do
  plan_cat_ids = PlanCategory.where(key: :google_cloud).ids
  plan_ids = Plan.where(plan_category: plan_cat_ids).ids
  subscriptions = Subscription.where(plan_id: plan_ids).where(status: :renewal_failed)
  if !subscription.empty?
    rn_in_failed = []
    subscriptions.each do |subscription|
      rn_in_failed << subscription.orders.where(type: "RenewalOrder", status: "provisioning_failed").last
    end
    rn_in_failed.each(&to_provisioning)
  end
end

