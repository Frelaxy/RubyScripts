def get_azure_plan_subscription(subscription_id)
    subscription = Subscription.find(subscription_id)
    reseller = subscription.reseller
    plugin_customer = Plugin::Office365::Customer.find_by(account_id: subscription.account.id)
    ms_customer_id = plugin_customer.tid
    root_azure_plan = reseller.plans.where(name: "Azure subscription based on Azure Plan").last.root
    csp_application_template = root_azure_plan.application_templates.first
    apc = Plugin::MicrosoftCspProducts::API::PartnerCenter.new(csp_application_template, reseller)
    app_template =
        reseller
          .parent
          .application_templates
          .where(origin_type: "Plugin::Office365::ApplicationTemplate").max { |a, t| a.applications.count <=> t.applications.count}.origin
    partner_center_client = Plugin::Office365::API::PartnerCenter.new(app_template, reseller)
    ms_subscriptions = partner_center_client.customer_subscriptions(ms_customer_id).fetch(:items, [])
    azure_subscriptions = ms_subscriptions.select {|subscription| subscription[:offerName] == "Azure plan"}
    azure_subscription_mapping = {}
    azure_subscriptions.each do |subscription|
      azure_entitlements =
        apc
          .azure_entitlements(
            customer_id: ms_customer_id,
            azure_plan_id: subscription[:id]
          )
      ms_subscription_id =
        azure_entitlements
          .items
          .last
          .id
      azure_subscription_mapping[ms_subscription_id] = subscription[:id]
    end
    current_subscription = ms_subscriptions.select { |s| s[:id] == azure_subscription_mapping[subscription.applications.last.origin.external_id]}
    return current_subscription
  end