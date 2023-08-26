origin_applications = Plugin::Office365::Application.where(service_status: %i[running stopped]).joins(core_application: :subscription).where.not(subscriptions: { status: %i[active stopped] })
origin_applications.each do |origin_application|
  puts "Обрабатывается подписка ID: #{origin_application.subscription.id}"
  subscription = origin_application.subscription
  status_from_ms = get_status_from_ms(subscription.id)
  puts "Обрабатывается подписка ID: #{subscription.id} | sub_AP_status: #{subscription.status} | app_status: #{origin_application.service_status} | MS_status: #{status_from_ms}"
  if status_from_ms == "deleted"
    subscription.manual_operations.update(status: :declined) if subscription.status == "waiting_for_manual_approved" 
    delete_csp_sub_in_ap(subscription.id, ticket_id = 'SAP-19579')
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

def delete_csp_sub_in_ap(sub_id, ticket_id = '')
  ActiveRecord::Base.transaction do
    sub = Subscription.find(sub_id);
    app = sub.applications.last;
    origin = sub.applications.last.origin;
        if origin.external_id == nil
            origin.update(external_id: '_broken');
            origin.update(order_id: '_broken');
        else
            origin.update(external_id: origin.external_id + '_broken');
            origin.update(order_id: origin.order_id + '_broken');
        end
    origin.update(service_status: :deleted)
    app.update(service_status: :deleted);
    sub.update(status: :deleted);
    sub.charges.in_blocked.update(status: :deleted) if sub.charges.exists?
    Note.create!(
        content: "Subscription was deleted only in AP | #{ticket_id}",
        noteable_id: sub.id,
        noteable_type: "Subscription",
        manager_id: Manager.find_by(email: 'kiryl.masliukou@activeplatform.com', reseller_id: 65).id,
        account_id: sub.account.id);
    puts " ---------------------------------------------"
    puts " #{sub.id} | #{sub.name} | #{sub.status.upcase} | APP #{sub.applications.exists?}";
    puts " ---------------------------------------------"
  end
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