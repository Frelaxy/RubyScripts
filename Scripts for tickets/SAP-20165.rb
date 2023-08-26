def fix_subs_resources()
  Subscription.where(id: [45136]).each do |subscription|
    subscription.subscription_resources.each do |subscription_resource|
      if subscription_resource.plan_resource.status == 'deleted'
        subscription_resource.update(status: :deleted)
        SubscriptionResource.create!(
          application_id: subscription.applications.last.id,
          plan_resource_id: 1318030,
          additional: subscription_resource.additional,
          used: subscription_resource.used,
          measurable: subscription_resource.measurable,
          unit_of_measure: "unit",
          subscription_id: subscription.id,
          status: "active",
          denominated: subscription_resource.denominated,
          custom_price: subscription_resource.custom_price,
          price_id: PlanResource.find(1318030).price.id,
          start_plan_price_id: subscription_resource.start_plan_price_id
        )
      end
    end
  end
end


@subs_with_problem = []
def fix_subs_resources(plan_id)
  plan = Plan.find(plan_id)
  plan.subscriptions.where.not(status: :deleted).each do |subscription|
    subscription.subscription_resources.each do |subscription_resource|
      if subscription_resource.plan_resource.status == 'deleted'
        @subs_with_problem << subscription
      end
    end
  end
end


irb(main):167:0> @subs_with_problem.pluck(:id)
=> [45136, 37796]