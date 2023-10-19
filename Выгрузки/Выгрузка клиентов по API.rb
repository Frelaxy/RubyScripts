reseller = Reseller.find(1144)
app_template = 
  reseller
    .parent
    .application_templates
    .where(origin_type: "Plugin::Office365::ApplicationTemplate").max { |a, t| a.applications.count <=> t.applications.count}.origin
partner_center_client = Plugin::Office365::API::PartnerCenter.new(app_template, reseller)
customers_list_response = partner_center_client.customers_list
customer_list = customers_list_response.fetch(:items, [])
p "Customer list was got from MPC. There are #{customer_list.count} customers" 
account_ids = Account.where(reseller_id: reseller.id).where.not(status: :deleted).ids
ms_customers = Plugin::Office365::Customer.where(account_id: account_ids)
ms_customer_tids =  ms_customers.pluck(:tid)
p "Account list was got from AP. There are #{ms_customer_tids.count} accounts with customers" 
i = 0
CSV.open("/app/support/kiryl/SAP-20542_clients_not_in_AP.csv", "wb") do |csv|
  csv << ["Tenant name", "Tenant id", "Subscription name", "Subscription id" ]
  customer_list.each do |ms_customer|
    i += 1
    p "Customer #{i}/#{customer_list.count}"
    if ms_customer_tids.include?(ms_customer[:id])
      next 
    else
      ms_subscriptions = partner_center_client.customer_subscriptions(ms_customer[:id]).fetch(:items, [])
      ms_subscriptions.each do |ms_subscription|
        ms_subscription_name = ms_subscription[:friendlyName]
        ms_subscription_id = ms_subscription[:id]
        csv << [
          ms_customer[:companyProfile][:domain],
          ms_customer[:id],
          ms_subscription_name,
          ms_subscription_id
          ]
      end
    end
  end
end
