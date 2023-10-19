reseller_ids = %w[392 393 452 456 447 460 536 400 419 337 530 892 848 1094 1099 349 398 397 1136]
reseller_ids = 1144
plan_classes_ids = PlanClass.where(key: :microsoft_azure_plan).ids
plans_ids = Plan.where(plan_class_id: plan_classes_ids).ids

subs = Reseller.where(id: reseller_ids).map {|r| r.subscriptions.where(plan_id: plans_ids, status: [:active, :waiting_for_manual_approve])}.flatten.compact;

CSV.open("/app/support/kiryl/SAP-20542_azure.csv", "wb") do |csv|
  csv << ["AP Reseller ID", "Account ID", "Subscription ID", "Subscription Name", "Account name", "Subscription status", "MS Subscription ID" , "MS Tenant ID", "MS Tenant Name", "Azure Plan ID", "Tax ID", "AP Account owner email"]
  
  subs.map do |sub|
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
      sub.status,
      ms_sub_id,
      ms_tenant_id,
      ms_tenant_name,
      azure_plan_id,
      tax_id,
      sub.account.owner.email
    ]
  end
end