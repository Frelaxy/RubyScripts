def find_subs_without_so()
  progressbar = ProgressBar.create(total: Subscription.where.not(status: :deleted).count, format: 'Processed: %P%% (%c out of %C) |%B|');
  @subs_without_so = []
  Subscription.where.not(status: :deleted).find_each do |subscription|
    progressbar.increment
    if subscription.sales_orders.empty?
      p "Найдена подписка без SO id: #{subscription.id}"
      @subs_without_so << subscription
    end
  end
  @subs_without_so.pluck(:id)
end






CSV.open("/app/support/kiryl/SAP-20126_subs_without_so_SOFTLINE.csv", "wb") do |csv|
  csv << ["AP Reseller ID", "Account ID", "Subscription ID", "Subscription Name", "Subscription status"]
  
  @subs_without_so.map do |sub|
    reseller_id = sub.account.reseller.id
    app = sub.applications.last
    plugin_app = app.origin if app
    if plugin_app
      if plugin_app.model_name.name == "Plugin::MicrosoftCspProducts::Application" || plugin_app.model_name.name == "Plugin::Office365::Application"
        customer = plugin_app.customer
      end
    end
    ms_sub_id = nil
    ms_tenant_id = nil
    ms_tenant_name = nil
    azure_plan_id = nil
    if plugin_app
      if plugin_app.model_name.name == "Plugin::MicrosoftCspProducts::Application" || plugin_app.model_name.name == "Plugin::Office365::Application"
        ms_sub_id = plugin_app.external_id
      end
    end
    ms_tenant_id = customer.tid if customer
    ms_tenant_name = customer.domain if customer
    azure_plan_id = customer.azure_plan_subscription_id if customer
    if CustomAttribute.where(key: "tax_id", reseller_id: reseller_id, applied_to: "account").first
      ca = CustomAttribute.where(key: "tax_id", reseller_id: reseller_id, applied_to: "account").first
    elsif CustomAttribute.where(key: "inn", reseller_id: reseller_id, applied_to: "account").first
      ca = CustomAttribute.where(key: "inn", reseller_id: reseller_id, applied_to: "account").first
    end
    ca_id = ca.id if ca
    cav = CustomAttributeValue.where(attributable_id: sub.account.id, custom_attribute_id: ca_id).first if ca_id
    tax_id = cav.value if cav

    csv << [
      reseller_id,
      sub.account.id,
      sub.id,
      sub.name,
      sub.account.name,
      sub.status
    ]
  end
end
