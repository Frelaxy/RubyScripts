account_id = 30177;

billing_date = Date.new(2023,3,1);

subscriptions = SubscriptionsForPostpayInvoice.call(account_id, billing_date);

platform_subscription_ids = subscriptions.ids;

external_subscription_ids = []

Scenarios::Builders::BillingProcess::PostpayInvoiceCreating.new(account_id: account_id, platform_subscription_ids: platform_subscription_ids, external_subscription_ids: external_subscription_ids, billing_date:billing_date).call