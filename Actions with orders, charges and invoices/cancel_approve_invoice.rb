def cancel_approve_invoice(invoice_id)
  invoice = Invoice::Postpay.find(invoice_id)
  activity = invoice.activities.select {|activity| activity.parameters["document_id"] != nil}.last
  old_document_id = activity.parameters["document_id"][0]
  ActiveRecord::Base.transaction do
    invoice.update(approval_date: nil)
    ExternalInvoice.where(invoice_id: invoice.id).last.delete
    invoice.update(document_id: old_document_id)
    invoice.payments.update_all(expiration_date: nil, external_total: nil, external_currency: nil)
  end
end