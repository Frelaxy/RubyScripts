subs_ids = [25151,
  33387,
  33462,
  7453,
  23525,
  7617,
  25050,
  12435,
  3128,
  24837,
  24979,
  25092,
  23527,
  25181,
  6697,
  30243,
  30244,
  25295,
  25334,
  25395,
  12390,
  25219,
  15508,
  7578,
  25100,
  7556,
  7569,
  25207,
  12356,
  24946,
  12489,
  36238,
  7574,
  39866,
  12447,
  24980,
  20933,
  12391,
  11229,
  25286,
  25273,
  7695,
  22401,
  12450,
  7724,
  3173,
  7461,
  12544,
  12470,
  7618,
  23486,
  23404,
  23477]
subs = Subscription.where(id: subs_ids).select {|sub| sub.reseller.id == 66 && sub.plan.billing_type == "csp_monthly" or sub.plan.billing_type == "monthly_commitment"}
CSV.open("/home/app/core/support/report_SAP-18617.csv", "wb") do |csv|
  csv << ["AP_Subscription_ID", "Subscription name", "Renewal_date", "sub_resource_name", "correct_recurring_fee", "quantity_from_rn", "prolong_recurring_fee", "quantity_from_last_po"]
  subs.map do |sub|
    sub_id = sub.id
    sub_name = sub.name
    rn_order_from_date = sub.orders.where(type: "RenewalOrder", status: :completed).last.details["common"]["from_date"]
    csv << [
      sub_id,
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