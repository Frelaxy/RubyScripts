reseller_id = 536
 
#Modern
plan_categories_keys = %w[
  csp_p1m_monthly_nce
  csp_p1y_monthly_nce
  csp_p1y_annual_nce
  perpetual_licenses
  microsoft_azure_plan
]
 
plan_categories_ids =
  PlanCategory
    .where(reseller_id: reseller_id)
    .where(key: plan_categories_keys)
    .ids
 
plans_ids =
  Plan
    .where(reseller_id: reseller_id)
    .where(plan_category_id: plan_categories_ids)
    .ids
 
subscriptions_ids =
  Subscription
    .where(plan_id: plans_ids)
    .where(payment_model: "postpay")
    .ids
 
mapping = InvoiceSubscription.where(subscription_id: subscriptions_ids)
all_invoices_ids = mapping.pluck(:invoice_id).uniq
 
invoices =
  all_invoices_ids
    .map {|invoice_id| Invoice::Postpay.find(invoice_id)}
    .select {|i| i.to_date == Date.new(2023, 4, 1)}
    .select {|i| i.status == 'closed'}
    .pluck(:id)

# 2 step Получение списаний
    def send_request(reseller_id, method, params = {})
      base_url = 'https://cproot.subs.noventiq.com/api/v3/resellers/'
      uri = URI(base_url + reseller_id.to_s + '/' + method)
      uri.query = URI.encode_www_form(params)
      puts "request: #{uri}"
      req = Net::HTTP::Get.new(uri)
      req['accept'] = 'application/vnd.api+json'
      req['content-type'] = 'application/vnd.api+json'
      req['X-Api-Token'] = 'KIzywl4TR7oWtYeiYkGvqQ'
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(req)
      puts res.code
      return JSON.parse(res.body)
    end
     
    def get_reseller_charges_by_invoice(reseller_id, invoice_id)
      params = {include: 'charges'}
      puts params
      res = send_request(reseller_id, "invoices/#{invoice_id}", params)
      account_id = res['data']["attributes"]["account_id"]
      payment_id = res["data"]["relationships"]["payments"]["data"][0]["id"]
      charges = []
      res["included"].map do |c|
        charges << {"PaymentID" => payment_id, "InvoiceID" => invoice_id}.merge(c)
      end
      return charges
    end
     
    # invoices - variable with invoices' ids
     
    all_charges = []
    invoices.map do |i|
      res = get_reseller_charges_by_invoice(reseller_id, i)
      all_charges.concat(res)
    end


#LAST STEP
    CSV.open("/app/support/kiryl/charges_col_#{Date.today.to_s}.csv", "wb") do |csv|
      csv << ["TenantID", "TenantName", "ApSubscriptionName", "ApSubscriptionID", "SubscriptionID", "ContainerSubscriptionID", "ApplicationTemplateKey","AddionalParameter","attribute_type","OfferID","InvoiceID","PaymentID","ChargeID", "DateFrom", "DateTO", "DateAPClosed", "Quantity", "Duration", "NetCost", "UnitPrice", "Amount", "Description", "Currency", "BillingDate", "AccountID", "Country"]
      all_charges.map do |charge|
        puts "exporting charge #{charge["id"]}"
        tenant_id = if !charge["attributes"]["additional_params"].empty?
            charge["attributes"]["additional_params"][0]['tenant_id']
        else
            'None'
        end
        tenant_name = if !charge["attributes"]["additional_params"].empty?
            charge["attributes"]["additional_params"][0]['tenant_name']
        else
            'None'
        end
        order_id = if !charge["attributes"]["additional_params"].empty?
            charge["attributes"]["additional_params"][0]['order_id']
        else
            'None'
        end
        subscription_id = charge["attributes"]["subscription_id"]
        subscription_name = Subscription.find(subscription_id).name
        azure_plan_id = if !charge["attributes"]["additional_params"].empty?
          charge["attributes"]["additional_params"][0]['azure_plan_id'] || 'None'
        else
          'None'
        end
        ms_subscription_id = if !charge["attributes"]["additional_params"].empty?
          charge["attributes"]["additional_params"][0]['subscription_id'] || 'None'
        else
          'None'
        end
        additional_parameter = if !charge["attributes"]["additional_params"].empty?
          charge["attributes"]["additional_params"][0]["sku_id"] || 'None'
        else
          'None'
        end
        attribute_type = if !charge["attributes"]["additional_params"].empty?
            charge["attributes"]["additional_params"][0]["attribute_type"] || ''
        else
            'None'
        end
        product_id = if !charge["attributes"]["additional_params"].empty?
            charge["attributes"]["additional_params"][0]['product_id'] || 'None'
        else
            'None'
        end
        term_duration = if !charge["attributes"]["additional_params"].empty?
            charge["attributes"]["additional_params"][0]['term_duration'] || 'None'
        else
            'None'
        end
        billing_cycle = if !charge["attributes"]["additional_params"].empty?
            charge["attributes"]["additional_params"][0]['billing_cycle'] || 'None'
        else
            'None'
        end
        offer_id = if !charge["attributes"]["additional_params"].empty?
            [product_id, additional_parameter, term_duration, billing_cycle].join(':')
        else
            'None'
        end
        discount = charge["relationships"]["discount"]["data"]["id"] if charge["relationships"]["discount"]["data"]
        csv << [
        tenant_id,
        tenant_name,
        subscription_name,
        subscription_id,
        ms_subscription_id,
        azure_plan_id,
        charge["attributes"]["application_template_key"],
        additional_parameter,
        attribute_type,
        offer_id,
        charge["InvoiceID"],
        charge["PaymentID"],
        charge["id"],
        charge["attributes"]["operate_from"],
        charge["attributes"]["operate_to"],
        charge["attributes"]["close_date"],
        charge["attributes"]["quantity"],
        charge["attributes"]["duration"],
        charge["attributes"]["net_cost"],
        charge["attributes"]["unit_price"],
        charge["attributes"]["amount"],
        charge["attributes"]["description"],
        charge["attributes"]["currency_unit"],
        charge["attributes"]["billing_date"],
        charge["relationships"]["account"]["data"]["id"],
        'Colombia'
        ]
      end
    end