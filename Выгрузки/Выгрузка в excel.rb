path_to_result_file = "/app/support/kiryl/notification_in_faild/notification_in_faild_#{Date.today}.xlsx"
workbook = RubyXL::Workbook.new
workbook[0].sheet_name = 'notification_in_faild'
workbook.write(path_to_result_file)
workbook = RubyXL::Parser.parse(path_to_result_file)
workbook[0].add_cell(0, 0, 'Reseller ID')
workbook[0].add_cell(0, 1, 'Reseller Name')
workbook[0].add_cell(0, 2, 'Link to notification')
row_sheet_0 = 1

notifications.each do |notification|
  reseller_id = notification.reseller_id
  reseller_name = notification.reseller.name
  link_to_notification = "https://cproot.subs.noventiq.com/admin/notification_logs/#{notification.id}?spoof_reseller_id=#{notification.reseller_id}"
  

  workbook[0].add_cell(row_sheet_0, 0, reseller_id)
  workbook[0].add_cell(row_sheet_0, 1, reseller_name)
  workbook[0].add_cell(row_sheet_0, 2, link_to_notification)
  row_sheet_0 += 1
end
workbook.write(path_to_result_file)