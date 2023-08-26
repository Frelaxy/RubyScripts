  # Manual
  subscription = Subscription.find(35281)
  reseller = subscription.reseller
  app_template = subscription.applications.last.application_template
  partner_center_client = Plugin::Office365::API::PartnerCenter.new(app_template, reseller)
  #Account tenant ID
  ms_customer_id = subscription.applications.last.origin.customer.tid
  # Application MS ID
  subs = partner_center_client.customer_subscriptions(ms_customer_id).fetch(:items, [])
  # Application MS ID
  ms_id = subscription.applications.last.origin.external_id
  subs.select { |s| s[:id] == ms_id }