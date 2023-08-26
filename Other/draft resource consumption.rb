# Description: 
# There is an azure plan subscription. There's a difference between AP analitics and MPС recon.
# Steps:# -Check charges
# -Check analytic on CCP
# -Compare analytic and recon (Use formula https://docs.activeplatform.com/services-operator-guide/latest/ru/microsoft-azure-plan-rukovodstvo-operatora/upravlenie-uslugoj-microsoft-azure-plan/raschet-stoimosti-i-sebestoimosti-potrebleniya-v-ramkah-podpiski-microsoft-azure-plan)
# -Check azure_billing logs
# -Check service on azure_billing
# -Check invoice on azure_billing
# -Check final items on azure_billing
# -Check consumption periods on support server 
# -Compare finalitems with Azure portal data 
ssh sl-aws-prod-ap-mcs-01
cd /activeplatform/compose/azure_billing/ && sudo docker compose exec sidekiq bin/rails c
# you can find out an application id on UI
# billing_period_start - billing date of period
application_id = 80297
billing_period_start = Date.new(2023, 3, 1)
service = Service.where(application_id: application_id).last
invoice = service.partner.invoices.find_by!(start_date: billing_period_start)

# Final items for all periods 
final_items = FinalItem.where(subscription_id: service.external_id)
# Final items for 1 period
final_items = FinalItem.where(subscription_id: service.external_id, invoice_id: invoice.external_id)
# Check if there were all days were billed 
final_items.pluck(:usage_date).uniq
