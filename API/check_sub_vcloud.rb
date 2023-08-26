def get_vcloud_subscription_resource_usage(subscription_id)
  subscription = Subscription.find(subscription_id)
  subscription_resources = subscription.subscription_resources  resource_usage = subscription.applications.last.origin.fetch_resource_usage_data  mapping = {}
  subscription_resources.each do |subscription_resource|
    mapping[subscription_resource.id] = {
      "name": subscription_resource.name,
      "resource_id": subscription_resource.plan_resource.parent.resource.id    }
    resource_usage.each do |resource_usage|
      if resource_usage[:resource_id] == subscription_resource.plan_resource.parent.resource.id        mapping[subscription_resource.id]["usage"] = resource_usage[:count]
      else        next      end    end  end  return mappingend