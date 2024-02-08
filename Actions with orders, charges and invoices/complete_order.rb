module SupportTeam
  module Order
    class OrderComplete
      class << self
        def call(order_id, ticket_id = '')
          @order = ::Order.find(order_id)
          @ticket_id = ticket_id.to_s

          ActiveRecord::Base.transaction do
            @order.items.update(status: :completed)
            @order.update(status: :completed, closed_at: DateTime.current)
            @order.charges.in_new.each(&:to_blocked)
            complete_scenario
            refund_charges if @order.type == ChangeOrder.name
            close_charges
            change_subscription_and_application_parameters
            change_resource_additional
            create_note
          end
        end

        def change_subscription_and_application_parameters
          subscription = @order.subscription
          billing_type = subscription.billing_type
          charge_operate_to_max = @order.charges.maximum(:operate_to)

          if @order.type == RenewalOrder.name
            next_expiration = @order.renew_item.operation_value
            next_paid_to = billing_type == 'csp_annual' ? next_expiration : charge_operate_to_max
            subscription.expiration_date = next_expiration
            subscription.paid_to = next_paid_to
            actualize_price_by_order
          elsif @order.type == ProlongOrder.name
            next_paid_to = charge_operate_to_max
            subscription.paid_to = next_paid_to
          end
          subscription.status = :active
          subscription.save!
          subscription.applications.update(service_status: :running)

          if subscription.applications.last.origin.respond_to?(:service_status)
            subscription.applications.last.origin.update(service_status: :running)
          end
        end

        def actualize_price_by_order
          uniq_resource_charges = @order.charges.uniq { |charge| charge.subscription_resource_id }
          uniq_resource_charges.map do |charge|
            new_price = charge.price
            charge.subscription_resource.update(price: new_price)
          end
        end

        def change_resource_additional
          items = @order.items.where(target_type: SubscriptionResource.name)
          items.each do |item|
            subscription_resource = SubscriptionResource.find(item.target_id)
            if item.type == ProvisioningItem::Upgrade.name
              subscription_resource.additional += item.operation_value
            elsif item.type == ProvisioningItem::Downgrade.name
              subscription_resource.additional -= item.operation_value
            end
            subscription_resource.save
          end
        end

        def refund_charges
          if !@order.refunded_charge_ids.nil?
            ::Charge::Base.where(id: @order.refunded_charge_ids).each(&:refund!)
          end
        end

        def close_charges
          if @order.subscription.billing_type == "csp_annual"
            ::ChargesManager::ManualCloser.new(subscription: @order.subscription).close
          elsif @order.subscription.billing_type == "monthly_commitment_monthly_interval"
            @order.charges.in_blocked.map do |charge|
              ChargeCloser.new(charge, charge.operate_to).call
              charge.update(close_date: charge.operate_from)
            end
          end
        end

        def complete_scenario
          scenario = Scenario.where(relation_data: {"order_id"=>@order.id}).try(:last)
          scenario.update(status: :completed, completed_at: DateTime.current) if !scenario.nil?
        end

        def create_note
          manager_id = Current.manager.nil? ? nil : Current.manager.id
          Note.create!(
            content: "Order #{@order.id} was completed manually | #{@ticket_id}",
            noteable_id: @order.subscription.id,
            noteable_type: "Subscription",
            manager_id: manager_id,
            account_id: @order.account.id
          )
        end
        puts "SupportTeam::Order::OrderComplete.call(order_id = , ticket_id = '')"
      end
    end
  end
end
