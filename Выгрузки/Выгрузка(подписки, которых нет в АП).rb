reseller = Reseller.find(397)
accounts = reseller.accounts.where(status: [:active, :credit_hold])
progressbar = ProgressBar.create(total: accounts.count, format: 'Processed: %P%% (%c out of %C) |%B|')

CSV.open("/app/SAP-20672.csv", "wb") do |csv|
  csv << ["Account ID", "AP subscription ID", "MS subscription ID", "Not in AP", "AP resource count", "MS resource count", "AP Status", "MS Status"]
  
  accounts.map do |account|
    !Plugin::Office365::Customer.find_by(account_id: account.id).nil? ? ms_customer_id = Plugin::Office365::Customer.find_by(account_id: account.id).tid : next
    app_template = reseller.parent.application_templates.where(origin_type: "Plugin::Office365::ApplicationTemplate").max { |a, t| a.applications.count <=> t.applications.count}.origin
    ap_subscriptions = account.subscriptions
    ap_external_ids = account.subscriptions.reduce([]) { |result, subscription| result << subscription.applications.try(:last).try(:origin).try(:external_id) }
    partner_center_client = Plugin::Office365::API::PartnerCenter.new(app_template, reseller)
    ms_subscriptions = partner_center_client.customer_subscriptions(ms_customer_id).fetch(:items, [])
    ms_subscriptions.each do |ms_subscription|
      if ms_subscription.dig(:status) == "active"
        if ap_external_ids.include? ms_subscription.dig(:id)
          ap_subscriptions.each do |ap_subscription|
            if ms_subscription.dig(:id) == ap_subscription.applications.try(:last).try(:origin).try(:external_id) && ms_subscription.dig(:quantity) != ap_subscription.subscription_resource.additional
              account_id = account.id
              ap_subscription_id = ap_subscription.id
              ms_subscription_id = ms_subscription.dig(:id)
              not_in_AP = "no"
              ap_resource_count = ap_subscription.subscription_resource.additional
              ms_resource_count = ms_subscription.dig(:quantity)
              ms_status = ms_subscription.dig(:status)
              ap_status = ap_subscription.status
            else
              next
            end
            csv << [
              account_id,
              ap_subscription_id,
              ms_subscription_id,
              not_in_AP,
              ap_resource_count,
              ms_resource_count,
              ap_status,
              ms_status
            ]
          end
        else
          account_id = account.id
          ap_subscription_id = nil
          ms_subscription_id = ms_subscription.dig(:id)
          not_in_AP = "yes"
          ap_resource_count = nil
          ms_resource_count = ms_subscription.dig(:quantity)
          ms_status = ms_subscription.dig(:status)
          ap_status = nil
          csv << [
            account_id,
            ap_subscription_id,
            ms_subscription_id,
            not_in_AP,
            ap_resource_count,
            ms_resource_count,
            ap_status,
            ms_status
          ]
        end
      end
    end
    progressbar.increment
  end
end