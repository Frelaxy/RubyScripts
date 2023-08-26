origin_applications = Plugin::Office365::Application.where(service_status: %i[running stopped]).joins(core_application: :subscription).where.not(subscriptions: { status: %i[active stopped] })
CSV.open("/app/support/kiryl/SAP-19579_noventiq.csv", "wb") do |csv|
  csv << ["AP Reseller ID", "Account ID", "Account name", "Subscription ID", "Subscription Name", "Subscription status", "MS status","Application ID", "Application status", "Subscription last update"]
 
  origin_applications.each do |origin_application|
    subsciption = origin_application.subscription
    reseller = subsciption.reseller
    account = subsciption.account
    status_from_ms = get_status_from_ms(subsciption.id)

    csv << [
      reseller.id,
      account.id,
      account.name,
      subsciption.id,
      subsciption.name,
      subsciption.status,
      status_from_ms,
      origin_application.id,
      origin_application.service_status,
      subsciption.updated_at
    ]
  end
end

def get_status_from_ms(sub_id)
  begin
    status_from_ms = get_subscriptions_info_from_ms(sub_id).first[:status]
    rescue StandardError => e
      status_from_ms = e
  end
  return status_from_ms
end
def get_subscriptions_info_from_ms(subscription_id)
  p "Getting subscription information"
  subscription = Subscription.find(subscription_id)
  reseller = subscription.reseller
  if subscription.status != "deleted"
    application = subscription.applications.last
  elsif
    application = Application.where(subscription_id: subscription.id).last
  end
  origin = application.origin if application
  app_template = origin.application_template if origin
  ms_customer_id = origin.customer.tid if origin != nil && origin.customer != nil
  p "Opening session through plugin #{application.origin_type}"
  if application != nil && application.origin_type == "Plugin::MicrosoftCspProducts::Application"
    partner_center_client = Plugin::MicrosoftCspProducts::API::PartnerCenter.new(app_template, reseller)
  elsif application != nil && application.origin_type == "Plugin::Office365::Application"
    partner_center_client = Plugin::Office365::API::PartnerCenter.new(app_template, reseller)
  elsif application != nil && application.origin_type == "Plugin::ManualProvisioning::Application"
  end
  p "Getting subscriptions information from MS"
  if partner_center_client
    ms_subscriptions = partner_center_client.customer_subscriptions(ms_customer_id).fetch(:items, [])
  end
  ms_id = origin.external_id
  ms_subscriptions.select { |s| s[:id] == ms_id }
end