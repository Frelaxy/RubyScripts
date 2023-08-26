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

def notifications_in_faild_for_the_last_day
  date_now = Date.today
  from_date = date_now - 1.day
  return NotificationLog::Base.where(status: :sending_failed, created_at: from_date..date_now).order(:created_at).reverse
end

def create_message_and_attachment
  path_to_file = "/app/support/kiryl/notification_in_faild/notification_in_faild_#{Date.today}.xlsx"
  workbook = RubyXL::Workbook.new
  workbook[0].sheet_name = 'notification_in_faild'
  workbook.write(path_to_file)
  workbook = RubyXL::Parser.parse(path_to_file)
  workbook[0].add_cell(0, 0, 'Reseller ID')
  workbook[0].add_cell(0, 1, 'Reseller Name')
  workbook[0].add_cell(0, 2, 'Created at')
  workbook[0].add_cell(0, 3, 'Link to notification')
  row_sheet_0 = 1

  subject = "#{@notifications.count} Notification(s) in sending_failed on #{Date.today}"
  notifications_table = ""
  @notifications.each do |notification|
    link_to_notification = "https://cproot.subs.noventiq.com/admin/notification_logs/#{notification.id}?spoof_reseller_id=#{notification.reseller_id}"
    notifications_table.concat(
      <<-EOF
      <tr>
        <th>#{notification.reseller_id}</th>
        <th>#{notification.reseller.name}</th>
        <th>#{notification.created_at}</th>
        <th>#{link_to_notification}</th>
      </tr> 
      EOF
    )
    workbook[0].add_cell(row_sheet_0, 0, notification.reseller_id)
    workbook[0].add_cell(row_sheet_0, 1, notification.reseller.name)
    workbook[0].add_cell(row_sheet_0, 2, notification.created_at.to_s)
    workbook[0].add_cell(row_sheet_0, 3, link_to_notification)
    row_sheet_0 += 1
  end
  workbook.write(path_to_file)
  notifications_table.prepend(
    <<-EOF
    <!doctype html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>#{subject}</title>
        <style>
          table, th, td {
            border: 1px solid black;
            border-collapse: collapse;
            padding: 15px;
          }
        </style>
      </head>
      <body>
        <table>
          <tr style="font-size:20px">
            <th>Reseller ID</th>
            <th>Reseller Name</th>
            <th>Created at</th>
            <th>Link to Notification</th>
          </tr>           
    EOF
  )
  notifications_table.concat(
    <<-EOF
    </table>
    </body>
    </html>
    EOF
  )
  return {:subject => subject, :body => notifications_table, :attachment => path_to_file}
end

@notifications = notifications_in_faild_for_the_last_day
return if @notifications.empty?
message = create_message_and_attachment
send_notification_with_file(message[:subject], message[:body], message[:attachment])