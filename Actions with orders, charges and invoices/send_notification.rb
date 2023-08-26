def send_notification(subject, message)
  mail = NotificationTemplateMailer.with(from: 'service@cloud.softline.com', to: ['kiryl.masliukou@activeplatform.com'], template_body: message, subject: subject).prepare_mail
  smtp_settings = Reseller.first.system_setting.mail_server_setting
  mail.delivery_method.settings.merge!(smtp_settings)
  mail.deliver_now
end


def send_notification_with_file(subject, body, path_to_file = nil)
  mailer = ActionMailer::Base.new
  smtp_settings = Reseller.first.system_setting.mail_server_setting
  mailer.smtp_settings.merge!(smtp_settings)
  if path_to_file
    mailer.attachments["notification_in_faild_#{Date.today}.xlsx"] = File.read(path_to_file)
  end
  mailer.mail(
    from: 'service@cloud.softline.com',
    to: ['kiryl.masliukou@activeplatform.com'],
    subject: subject
  ) {|format| format.html {"<html><body>#{body}</body></html>"}}
  mailer.message.deliver
end