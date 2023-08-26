def rename_subscription(client, subscription)
  p "subscription to process: #{subscription.id}"
  application = subscription.applications.last
  origin = application.origin if application
  ms_customer_id = origin.customer.tid if origin != nil
  ms_subscription_id = subscription.applications.last.origin.external_id if origin
  root_azure_id = origin.customer.azure_plan_subscription_id
  begin
    sub_info = client.get_subscription(ms_customer_id, ms_subscription_id)
  rescue Plugin::Office365::API::Exceptions::ClientErrorException => e
    puts "#{subscription.id}, #{ms_subscription_id} not found, trying root"
    sub_info = client.get_subscription(ms_customer_id, root_azure_id)
  end
  if sub_info
    sub_name_from_pc = sub_info[:friendlyName]
    unless sub_name_from_pc == "Microsoft Azure" || sub_name_from_pc == "Azure plan"
      old_name = subscription.name
      p "Subscription #{subscription.id} name changed #{old_name} -> #{sub_name_from_pc}"
      subscription.update(name: sub_name_from_pc)
      Note.create!(
      content: "Subscription name was changed from #{old_name} to #{sub_name_from_pc}",
      noteable_id: subscription.id,
      noteable_type: "Subscription",
      manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
      account_id: subscription.account_id);
    end
  end
end
def rename_azure_plan_subs_for_reseller(reseller_id)
  reseller = Reseller.find reseller_id
  plan_cat_ids = reseller.plan_categories.where(key: "microsoft_azure_plan").ids;
  plans_ids = Plan.where(plan_category_id: plan_cat_ids).ids;
  subs = reseller.subscriptions.where(plan_id: plans_ids).where.not(status: [:deleted, :installation_failed]);
  app_template = Plan.find(plans_ids.first).root.application_templates.first;
  mpc_client = Plugin::MicrosoftCspProducts::API::PartnerCenter.new(app_template, reseller);
  subs.map do |sub|
    rename_subscription(mpc_client, sub)
  end
end