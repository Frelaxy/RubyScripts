def get_subscriptions_info_from_ms(subscription_id)
  p "Getting subscription information"
  subscription = Subscription.find(subscription_id)
  application = subscription.status != "deleted" ? subscription.applications.last : Application.where(subscription_id: subscription.id).last
  origin = application.origin if application
  application_template = origin.application_template if origin
  ms_customer_id = origin.customer.tid if origin != nil && origin.customer != nil
  p "Opening session through plugin #{application.origin_type}"
  if application != nil && application.origin_type == "Plugin::MicrosoftCspProducts::Application"
    partner_center_client = Plugin::MicrosoftCspProducts::API::PartnerCenter.new(application_template, subscription.reseller)
  else application != nil && application.origin_type == "Plugin::Office365::Application"
    partner_center_client = Plugin::Office365::API::PartnerCenter.new(application_template, subscription.reseller)
  end
  p "Getting subscriptions information from MS"
  if partner_center_client
    ms_subscriptions = partner_center_client.customer_subscriptions(ms_customer_id).fetch(:items, [])
  end
  ms_subscriptions.select { |s| s[:id] == origin.external_id }
end