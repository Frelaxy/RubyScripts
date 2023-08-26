def custom_price_for_main_resource(args = {})
  if args.has_key?(:sub_id)
    sub = Subscription.find(args[:sub_id])
    resource = sub.subscription_resource
    price_duplicate = resource.price.dup
    price_duplicate.current = false
    if args.has_key?(:new_setup_fee)
      price_duplicate.setup_fee = args[:new_setup_fee]
    end
    if args.has_key?(:new_recurring_fee)
      price_duplicate.recurring_fee = args[:new_recurring_fee]
    end
    if args.has_key?(:new_renewal_fee)
      price_duplicate.renewal_fee = args[:new_renewal_fee]
    end
    if args.has_key?(:new_overuse_fee)
      price_duplicate.overuse_fee = args[:new_overuse_fee]
    end
    price_duplicate.save
    resource.update(price_id: price_duplicate.id)
    sub_period = resource.subscription.subscription_period
    period_price_duplicate = sub_period.price.dup
    period_price_duplicate.current = false
    period_price_duplicate.save
    sub_period.price_id = period_price_duplicate.id
    sub_period.custom_price = true
    sub_period.save
  else
    puts "example: custom_price_for_main_resource(sub_id: 26363, new_setup_fee: 0, new_recurring_fee: 25.25, new_renewal_fee: 0, new_overuse_fee: 0)"    
  end
end