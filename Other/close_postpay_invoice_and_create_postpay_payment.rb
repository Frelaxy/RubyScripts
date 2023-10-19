#close_invoice and create payment
invoice = Invoice::Base.find(invoice_id)
Scenarios::Builders::BillingProcess::PostpayInvoiceClosing.call(account_id: invoice.account.id, invoice_ids: [invoice.id], billing_date: invoice.from_date)
#create_postpay_payment