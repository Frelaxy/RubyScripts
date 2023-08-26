# Обязательно при renew POSTPAY через UI
sub_id = 41418
def break_origin(sub_id)
  subscription = Subscription.find(sub_id)
  origin = subscription.applications.last.origin
  @external_id_origin = origin.external_id
  origin.external_id = @external_id_origin + "_broken"
  @order_id_origin = origin.order_id
  origin.order_id = @order_id_origin + "_broken"
  origin.save
end


def return_origin(sub_id)
  subscription = Subscription.find(sub_id)
  origin = subscription.applications.last.origin
  origin.external_id = @external_id_origin
  origin.order_id = @order_id_origin
  origin.save
end