task сhecking_invoices_for_closing: :environment do
  def send_notification(subject, message)
    h = {:from=>'service@cloud.softline.ru',
      :to=>['kiryl.masliukou@activeplatform.com'],
      :subject=>subject,
      :body=>message}
    mail = NotificationMailer.send_notification(h)
    mail.delivery_method.settings = {:address=>"10.128.0.25",
      :port=>"25",
      :domain=>"cloud.softline.ru",
      :enable_starttls_auto=>true,
      :openssl_verify_mode=>"none",
      :ssl=>false,
      :tls=>false}
      mail.deliver_now
  end
  date_now = Date.today
  from_date = date_now - 1.month - 2.day
  dates_for_azure_plan = Date.new(2022,12,9)..Date.new(2022,12,15)
  dates_for_azure_plan_next_year = Date.new(2023,1,9)..Date.new(2023,1,15)
  invoices = []
  invoices_azure_plan = []
  if dates_for_azure_plan.include? date_now
    invoices_azure_plan = Invoice::Base.where(to_date: Date.new(2022,12,1)).where(close_type: "external").where.not(status: :closed)
  elsif dates_for_azure_plan_next_year.include? date_now
    invoices_azure_plan = Invoice::Base.where(to_date: Date.new(2023,1,1)).where(close_type: "external").where.not(status: :closed)
  else
    invoices = Invoice::Base.where("from_date > ? and from_date < ? and to_date < ?", from_date, date_now, date_now).where.not(status: :closed).where(close_type: "platform")
  end
  if !invoices.empty?
    subject = "Незакрытые акты(не включая Azure Plan) RU инсталляции на дату #{Date.today}"
    message = invoices.pluck(:id, :reseller_id)
    send_notification(subject, message)
  end
  if !invoices_azure_plan.empty?
    subject = "Незакрытые акты по Azure Plan RU инсталляции на дату #{Date.today}"
    message = invoices_azure_plan.pluck(:id, :reseller_id)
    send_notification(subject, message)
  end
end