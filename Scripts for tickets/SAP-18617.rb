def find_subs_where_not_actual_price()
  begin
    @subs_id_where_not_actual_price = []
    counter = 0
    accounts_ids = Account.where(status: :active).ids
    subs_ids = Subscription.where(account_id: accounts_ids).where("updated_at > ?", Date.new(2021,1,4)).where.not(status: [:deleted, :deleting, :deletion_failed, :installation_failed, :installing]).ids
    subs_ids.map do |sub_id|
      counter = counter + 1
      puts "Обрабатывается #{counter} подписка из #{subs_ids.count} id:#{sub_id}"
      sub = Subscription.find(sub_id)
      order = sub.orders.where(type: "RenewalOrder", status: :completed).last
      if !order.nil?
        uniq_resource_charges = order.charges.uniq { |c| c.subscription_resource_id }
        uniq_resource_charges.map do |c|
          new_price = c.price
          subscription_resource = c.subscription_resource
          if !subscription_resource.nil? && subscription_resource.price.recurring_fee != new_price.recurring_fee
            @subs_id_where_not_actual_price << c.subscription.id
            @subs_id_where_not_actual_price.uniq!
          end
        end
      end
    end
  rescue => e
    p e
  end
end