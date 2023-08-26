# в данном примере был клиент у него было 5 подписок. Был создан еще один клиент с идентичными настройками 
# создание дупликата через ui 
# удаление подписок с помощью метода 
def delete_nce_sub_in_ap(sub_id, ticket_id) #ticket_id without SAP-
    sub = Subscription.find(sub_id);
    app = sub.applications.last;
    origin = sub.applications.last.origin;
        if origin.external_id == nil
            origin.update(external_id: '_broken');
            origin.update(microsoft_order_id: '_broken');
        else
            origin.update(external_id: origin.external_id + '_broken');
            origin.update(microsoft_order_id: origin.microsoft_order_id + '_broken');
        end
    app.update(service_status: :deleted);
    sub.update(status: :deleted);
    sub.charges.in_blocked.update(status: :deleted) if sub.charges.exists?
    s = Subscription.find(sub_id);
    ticket = ticket_id.to_s;
    Note.create!(
        content: 'Subscription was deleted only in AP | SAP-' + ticket,
        noteable_id: s.id,
        noteable_type: "Subscription",
        manager_id: Manager.find_by(email: 'raman.hryntsevich@activeplatform.com', reseller_id: 65).id,
        account_id: s.account.id);
    puts " ---------------------------------------------"
    puts " #{s.id} | #{s.name} | #{s.status.upcase} | APP #{s.applications.exists?}";
    puts " ---------------------------------------------"
  end
  # через раздел миграция NCE подписок через ui добавили клиентк tenant id и name и сделали миграцию 
  # сломать взаимодействие подписки и MS
  sub = Subscription.find(45903)
  origin = sub.applications.last.origin
  origin.update(external_id: origin.external_id + '_broken');
  origin.update(microsoft_order_id: origin.microsoft_order_id + '_broken');
  # через ui создать RN (заказ на продление)
  # завершить заказ вручную и иправить даты на нужные 
  # починить взаимодействие подписки и MS
  # переделать списания 
  # сгенерировать акт и платеж постпэй для нового аккаунта 
  #create_invoice, billing_date  =  previous billing date 2020-05-01
  # очень много методов у которых нужно править значения!!!
  account_id = 23767;
  billing_date = Date.new(2022,7,1);
  subscriptions = SubscriptionsForPostpayInvoice.call(account_id, billing_date);
  platform_subscription_ids = subscriptions.ids;
  external_subscription_ids = []
  #!!! уже другие методы
  ActivePlatform::Interface::ScenarioBuilder::BillingProcess::PostpayInvoiceCreating.new(account_id: account_id, platform_subscription_ids: platform_subscription_ids, external_subscription_ids: external_subscription_ids, billing_date:billing_date).call
  #close_invoice
  ActivePlatform::Interface::ScenarioBuilder::BillingProcess::PostpayInvoiceClosing.new(account_id: account_id, invoice_ids: [138114], billing_date:'2022-07-01').call
  #create_postpay_payment
  module BillingProcesses
    class CreatePostpayPayments
      def invoices
    @invoices = account.invoices.where(id: 138114)
      end
    end
  end
  BillingProcesses::CreatePostpayPayments.new(account_id).run
  # после этого проверить попадание всех списаний в инвойс и платеж 
  # перевод списаний из прошлого аккаунта в статус удалены 
  # пересчет инвойса 
  # пересчет или отмена платежа 
  #!!!!DONE!!!!