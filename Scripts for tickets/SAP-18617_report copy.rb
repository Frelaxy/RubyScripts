subs_ids = [
  37011,
  11145,
  11146,
  37013,
  50979,
  34951,
  34957
]
subs = Subscription.where(id: subs_ids).select {|sub| sub.plan.billing_type == "csp_monthly" or sub.plan.billing_type == "monthly_commitment"}
CSV.open("/home/app/core/support/report_SAP-18617_copy.csv", "wb") do |csv|
  csv << ["AP_Subscription_ID", "reseller_id", "Subscription name", "Renewal_date", "sub_resource_name", "correct_recurring_fee", "quantity_from_rn", "prolong_recurring_fee", "quantity_from_last_po"]
  subs.map do |sub|
    sub_id = sub.id
    sub_name = sub.name
    reseller_id = sub.reseller.id
    rn_order_from_date = sub.orders.where(type: "RenewalOrder", status: :completed).last.details["common"]["from_date"]
    csv << [
      sub_id,
      reseller_id,
      sub_name,
      rn_order_from_date,
      sub_resource_name = nil,
      correct_recurring_fee = nil,
      quantity_from_rn_order = nil,
      prolong_recurring_fee = nil,
      quantity_from_po_order = nil
    ]
    sub.orders.where(type: "RenewalOrder", status: :completed).last.charges.map do |charge|
      sub_resource_name = charge.subscription_resource.name
      correct_recurring_fee = charge.price.recurring_fee
      quantity_from_rn_order = charge.quantity
      csv << [
        sub_id = nil,
        reseller_id = nil,
        sub_name = nil,
        rn_order_from_date = nil,
        sub_resource_name,
        correct_recurring_fee,
        quantity_from_rn_order,
        prolong_recurring_fee = nil,
        quantity_from_po_order = nil
      ]
    end
    sub.orders.where(type: "ProlongOrder").last.charges.map do |charge|
      prolong_recurring_fee = charge.price.recurring_fee
      sub_resource_name = charge.subscription_resource.name
      quantity_from_po_order = charge.quantity
      csv << [
        sub_id = nil,
        reseller_id = nil,
        sub_name = nil,
        rn_order_from_date = nil,
        sub_resource_name,
        correct_recurring_fee = nil,
        quantity_from_rn_order = nil,
        prolong_recurring_fee,
        quantity_from_po_order
      ]
    end
  end
end