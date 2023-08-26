Определить MigrationFileCreator - создает XLS-файл аккаунта.
_____________________________________________________________________________
# Копируем в консоль
# False после require -это значит, что гем уже был добавлен по дефолту, True после require - добавился 

require 'csv'
require 'ruby-progressbar'
class CSVMatrixWriter
  PROGRESSBAR_FORMAT = 'Processed: %P%% (%c out of %C) |%B|'.freeze
  def self.write(matrix:, file_path:, rewrite: true)
    file_path = File.expand_path(file_path)
    progressbar = ProgressBar.create(total: matrix.length, format: PROGRESSBAR_FORMAT)
    matrix = matrix[1..-1] unless rewrite
    CSV.open(file_path, rewrite ? 'w' : 'a', quote_char: '"', force_quotes: true) do |csv|
      matrix.each do |row|
        csv.add_row(row)
        progressbar.increment
      end
    end
    return file_path
  end
end

require 'ruby-progressbar'
require 'rubyXL'
require 'rubyXL/convenience_methods'

if Gem::Dependency.new('', '~> 3.3.0').match?('', Gem.loaded_specs['rubyXL'].version.to_s)
  module RubyXL
    module WorkbookConvenienceMethods
      def modify_alignment(style_index, &block)
        xf = cell_xfs[style_index || 0].dup
        xf.alignment = xf.alignment&.dup || RubyXL::Alignment.new
        yield(xf.alignment)
        xf.apply_alignment = true
        register_new_xf(xf)
      end
    end
  end
end
class XLSXMatrixWriter
  PROGRESSBAR_FORMAT = 'Processed: %P%% (%c out of %C) |%B|'.freeze
  def self.write(matrix:, file_path:, sheet: 'Sheet1', rewrite: true)
    file_path = File.expand_path(file_path)
    sheet = sheet[0..30]
    File.delete(file_path) if rewrite && File.exists?(file_path)
    workbook = FastExcel.open(file_path)
    progressbar = ProgressBar.create(total: matrix.size, format: PROGRESSBAR_FORMAT)
    worksheet = workbook.add_worksheet(sheet)
    i = 0
    loop do
      row = matrix[i]
      break unless row
      worksheet.write_row(i, row)
      progressbar.increment
      i += 1
    end
    workbook.read_string
    file_path
  end
end

class MigrationFileCreator
  CUSTOMER_DATA = {
    account_type:  :account_type__key,
    account_class: :account_class__key,
    balance:       :usable_balance,
    fiz_street:    :location__street,
    fiz_office:    :location__office,
    fiz_building:  :location__building,
    tid:           lambda { |account, manual_value| manual_value || Plugin::Office365::Customer.find_by(account: account)&.tid || raise('no customer') },
    ca_position:   nil,
    ca_fax:        nil,
    ca_office:     nil,
    ca_building:   nil,
    ca_street:     :location__street,
    ca_city:       :location__city,
    ca_region:     :location__region,
    ca_country:    lambda { |account, manual_value| manual_value || ISO3166::Country[account.location.country].translations[account.location.country.downcase] },
    ca_zip:        :location__zip,
    ca_ogrn:       nil,
    ca_kpp:        nil,
    ca_inn:        nil,
    ca_tid:        nil,
    email:         :email
  }.freeze
  HEADER_MAPPING = {
    ca_tid: :ca_tenant_id,
  }.freeze
  WRITER_CLASS = {
    xlsx: XLSXMatrixWriter,
    csv: CSVMatrixWriter
  }.freeze
  CUSTOMERS_SHEET_NAME = 'Customers'.freeze
  class << self
    def xlsx(account_id, options = {})
      options[:result_type] = :xlsx
      create(account_id, options)
    end
    def csv(account_id, options = {})
      options[:result_type] = :csv
      create(account_id, options)
    end
    private
    def create(account_id, options)
      migration_file_path(*migration_matrix(account_id, options))
    end
    def migration_file_path(matrix, account_id, options)
      original_file_path = options[:file_path]
      result_type = options[:result_type]
      writer_kwargs = {
        matrix: matrix,
        file_path: original_file_path && File.expand_path(original_file_path) || "/home/app/core/support/migration_#{account_id}.#{result_type}"
      }
      writer_kwargs.merge!(sheet: CUSTOMERS_SHEET_NAME) if result_type == :xlsx
      WRITER_CLASS[result_type].write(**writer_kwargs)
    end
    def migration_matrix(account_id, options)
      account = Account.find(account_id)
      manual_values_mapping = {}
      manual_values_mapping[:tid] = options[:manual_tid]
      manual_values_mapping[:ca_tid] = options[:manual_tid]
      custom_attributes = account.custom_attributes.map { |attribute| [attribute.key, attribute.value] }.to_h
      matrix = []
      matrix.push(CUSTOMER_DATA.keys.map(&:to_s))
      row = []
      CUSTOMER_DATA.each do |header, value|
        row.push(
          case value
          when Symbol
            value.to_s.split('__').inject(account) { |field_value, field| field_value = field_value.try(field) }
          when Proc
            value.call(account, manual_values_mapping[header])
          else
            custom_header = HEADER_MAPPING[header] || header
            manual_values_mapping[header] || custom_attributes[custom_header.to_s[/^ca_(.+)$/, 1]]
          end
        )
      end
      matrix.push(row)
      [matrix, account_id, options]
    end
  end
end

_____________________________________________________________________________

вызов создания файла
__________________________________________

MigrationFileCreator.xlsx(29851) # account id 

#  Если клиента нет no customer, то можно проверить это с помощью: Plugin::Office365::Customer.where(account_id: 29851)
# Если нет, то создать можно с помощью 
=begin
Plugin::Office365::Customer.create!(
  tid: "1e9461ec-5362-4329-ae46-61fa3e91c6d2",
  domain: "cadt.edu.kh",
  user_name: "admin@cadt.edu.kh",
  password: nil,
  object_type: "Customer",
  account_id: 29851,
  azure_plan_subscription_id: nil)
=end
# Получить всю инфу можно через MPC или API:     partner_center_client.get_customer(ms_customer_id)
#
_____________________________________________________________

#наш сгенерированный файл с одной страницей пропускаем через генератор,
#который создаст вторую страницу с ресурсами подписок клиента
#файлик можно найти в контейнере support-spring-core-1

file_path = "/home/app/core/support/migration_29851.xlsx" #путь будет после генерированного файла
application_template = Plugin::Office365::ApplicationTemplate.find(9775); #Plan.find(1180709).root.application_templates.last.origin
reseller = Reseller.find(397); #t1

generator = Plugin::Office365::Support::XlsGenerator.new(file_path: file_path, app_template: application_template, reseller: reseller);
generator.call

# Если ошибка, что ску нет и так далее, то нужно патчить генератор и мигратор. И запускать после него 

module Plugin
  module Office365
    module Support
      class XlsGenerator
        GUID_REGEX = /\A[A-F0-9]{8}\-[A-F0-9]{4}\-[A-F0-9]{4}\-[A-F0-9]{4}\-[A-F0-9]{12}\z/
        private
        def licenses(used_offers)
          used_offers.select do |offer|
            offer[:parentSubscriptionId].blank? && AZURE_OFFER_IDS.exclude?(offer[:offerId].upcase) && GUID_REGEX.match(offer[:offerId].upcase)
          end
        end
      end
    end
  end
end

# Копируем на сервер с контейнера 
docker cp support-spring-core-1:/home/app/core/public/uploads/migrations/customer_lists_with_prices_from_1678974031.xlsx .

# Копируем к себе с сервера и меняем цены
scp sl-aws:/home/ubuntu/support/kiryl/customer_lists_with_prices_from_1678974031.xlsx C:\Users\KirylMasliukou\Downloads
# Копируем назад на сервер 
scp C:\Users\KirylMasliukou\Downloads\customer_lists_with_prices_from_1678974031.xlsx sl-aws:/home/ubuntu/support/kiryl

______________________________________________________________________

Если миграция кастомная, переопределяем мигратор (это оригинал)

_____________________________________________________________________

https://gitlab.activeplatform.com/plugins/office365_plugin/-/blob/master/lib/plugin/office365/support/migrator.rb

___________________________________________________________________________

custom_migrator (определяем напрямую кастомера, задаем напрмую подписки для миграции)
___________________________________________________________________________


module Plugin
  module Office365
    module Support
      class Migrator
        def call
          self.success_rows = []
          self.error_rows = []
          self.accounts = []
          logger.info '---------START MIGRATION--------'
          (1...sheet.sheet_data.rows.size).each do |row_index|
            validate_file_on_price
            current_row = sheet.sheet_data[row_index].cells.map { |c| c&.value }
            row = first_row.zip(current_row).to_h.deep_symbolize_keys
            tid = row[:tid]
            next if tid.blank?
            logger.info '########################## NEW CUSTOMER ########################'
            logger.info "Works with customer tid: #{tid} and row: #{row_index}"
            #if Customer.find_by(tid:)
            #  success_rows.push(row_index:, tid:, status: :persisted)
            #  logger.info 'CUSTOMER EXIST'
            #  next
            #end
            ActiveRecord::Base.transaction do
              c_id = 24638 #Plugin::Office365::Customer.where(account_id: 29190)
              sc_report = subscription_creator(customer_id: c_id).call
              sub_ids_for_customer = sc_report.data
              #BalanceCorrector.new(c_id, sub_ids_for_customer, logger).call
              final_report(tid, sc_report)
              raise 'Test migration' if env == :test
              success_rows.push(row_index:, tid:, c_id:, status: :created, subscription_ids: sub_ids_for_customer)
              accounts << Customer.find(c_id).account
            end
          rescue StandardError => e
            error = e.respond_to?(:record) ? model_errors(e.record) : e.message
            logger.error "#{error}\n#{e.backtrace.inspect}"
            logger.info 'FAILED CREATE CUSTOMER'
            error_rows.push(row_index:, error:)
          end
          success_customer_ids = success_rows.pluck(:tid)
          if success_customer_ids.present?
            logger.info "&&&&&&&&&  Success created customers with tenant ids: #{success_customer_ids} &&&&&&&&&"
            ActiveRecord::Base.transaction do
              c_ids = success_rows.pluck(:c_id)
              file_with_password = PasswordUpdater.new(c_ids, logger).call
              logger.info "SUCCESS_UPDATE_PASSWORD for #{success_customer_ids}. File path: #{file_with_password}"
            rescue StandardError => e
              error = e.respond_to?(:record) ? e.record.errors : e.message
              logger.error error
              logger.info "FAILED_UPDATE_PASSWORD for #{success_customer_ids}"
            end
          end
          accounts.each(&:trigger_created_event) if notify_account_created
          logger.info '--------FINISH MIGRATION--------'
        end
      end
    end
  end
end

____________________________________________________________

Кстомизируем SubscriptionCreator - напрямую задаем подписку, которую нужно мигрировать.
____________________________________________________________


module Plugin
  module Office365
    module Support
      class SubscriptionCreator
        ALLOWED_SUBSCRIPTION_IDS = ['5F815742-D780-43B3-B619-053BD840EF4D', 'E32B8E8A-14F8-4810-9E09-F6B8DCFD4E30'].freeze

        def items
          @_items ||= begin
            subscriptions = @client.customer_subscriptions(@customer.tid)

            subscriptions[:items].select { |item| ALLOWED_SUBSCRIPTION_IDS.include?(item[:id].upcase) }
         end

         #@logger.info(@_items)
         @_items
        end
      end
    end
  end
end

_____________________________________________________________________________

Запуск миграции
__________________________________________________

# migrator = Plugin::Office365::Support::Migrator.new(file_path:, app_template:, reseller:)
# migrator.call
# migrator.success_rows returns successfully created users
# migrator.error_rows returns users who had had mistakes


file = File.expand_path('/home/app/core/support/kiryl/customer_lists_with_prices_from_1674053613.xlsx');
application_template = Plugin::Office365::ApplicationTemplate.find(9298);
reseller = Reseller.find(419);
generate_charges_from_next_billing_day = true;
notify_account_created = false;

# env: :test - тест , env: :something_else - на запуск 
migrator = Plugin::Office365::Support::Migrator.new(file_path: file,app_template: application_template,reseller: reseller, env: :test, notify_account_created: notify_account_created);
migrator.call

migrator = Plugin::Office365::Support::Migrator.new(file_path: file,app_template: application_template,reseller: reseller, env: :go, notify_account_created: notify_account_created,generate_charges_from_next_billing_day: generate_charges_from_next_billing_day);
migrator.call

# Если по какой-то причине все опубликовано, но Plan not found, то патч на отсечение NCE у клиента
module Plugin
  module Office365
    module Support
      class SubscriptionCreator
        GUID_REGEX = /\A[A-Z0-9]{12}\:[A-Z0-9]{4}\:[A-Z0-9]{12}\z/
        private
        def items
          @items ||=
            client
              .customer_subscriptions(customer.tid)[:items]
              .reject { |item| AZURE_OFFER_IDS.include?(item[:offerId].upcase) }
              .reject { |item| GUID_REGEX.match(item[:offerId].upcase) }
        end
      end
    end
  end
end

# Добавление ADDONS. Можно Хэш закидывать, а можно ручками вызывать для каждой ошибки по аддону. Передавать в него айди плана, оффер айди аддона, имя аддона
def create_resource(application_template, plugin_resource)
  Resource.create!(
    sku: SecureRandom.uuid,
    measurable: false,
    unit_of_measure: 'unit',
    application_template_id: application_template.id,
    name: plugin_resource.name,
    status: 'active',
    reseller_id: application_template.reseller_id,
    origin_id: plugin_resource.id,
    origin_type: plugin_resource.class.name
    )
end
def create_plan_resource_for_offer(plan_id, offer_id, offer_name)
  puts "work with #{offer_id} #{offer_name}"
  plan = Plan.find(plan_id)
  plan_parent = plan.parent
  plan.reload
  plan_parent.reload
  raise "Plan #{plan_parent.id} is invalid!" if plan_parent.application_templates.count != 1
  plan_resource = plan_parent.plan_resources.find_by(name: offer_name)
  if plan_resource
    puts "Plan Resource #{offer_id} #{offer_name} exists"
  else
    application_template = plan_parent.application_templates.first
    plugin_application_template = application_template.origin
    @plugin_application_template = plugin_application_template
    plugin_resource = plugin_application_template.resources.find_by(data: offer_id.downcase)
    if plugin_resource
      resource = plugin_resource.resource
    else
      plugin_resource = plugin_application_template.resources.new(
        name: offer_name,
        description: "",
        status: "active",
        application_template_id: plugin_application_template.id,
        resource_type: nil,
        unit_of_measure: "unit",
        data: offer_id.downcase,
        microsoft_offer: true
      )
      plugin_resource.save!
    end
    puts "#{application_template.id} and #{plugin_resource.id}"
    resource ||= create_resource(application_template, plugin_resource)
    plan_resource = PlanResource.new(
      plan_id: plan_parent.id,
      resource_id: resource.id,
      sku: resource.sku,
      included: 0,
      minimum: 0,
      limit: 1500,
      unlimited_units: false,
      status: 'active',
      public: false,
      name: offer_name,
      denominated: false,
      position: 1
    )
    puts "check"
    # lets try zero fee
    # we should use price updater in future
    vendor_price = Price.where(price_list_id: plan_parent.vendor_price_list.id, sku: plan_resource.sku).last
    if vendor_price
      puts "vendor price exists"
    else
      vendor_price = Price.create!(
        price_list_id: plan_parent.vendor_price_list.id,
        sku: plan_resource.sku,
        current: true,
        markup_rate: plan_parent.vendor_price_list.markup_rate,
        fees_updated_at: Date.today.to_time,
        currency_id: plan_parent.vendor_price_list.currency_id
      )
    end
    puts "check_1"
    client_price = Price.where(price_list_id: plan_parent.client_price_list.id, sku: plan_resource.sku).last
    if client_price
      "client price exists"
    else
      client_price = Price.create!(
        ancestry: vendor_price.id.to_s,
        price_list_id: plan_parent.client_price_list.id,
        sku: plan_resource.sku,
        current: true,
        markup_rate: plan_parent.client_price_list.markup_rate,
        fees_updated_at: Date.today.to_time,
        currency_id: plan_parent.client_price_list.currency_id
      )
    end
    plan_resource.save!
    plan_resource
  end
end


arr.map do |arr_item|
  create_plan_resource_for_offer(arr_item[:plan_id], arr_item[:offer_id], arr_item[:offer_name])
end

# Делегирование план ресурса на нижний уровень 
def deleg(plan_id)
  plan = Plan.find(plan_id).parent;
  undelegated_res = plan.plan_resources.select {|pr| pr.children.count == 0};
  undelegated_res.map {|pr| ActivePlatform::Interface::ScenarioBuilder::Delegation::PlanResourceChildren.new(root_plan_resource_id: pr.id).call};
end
# Просмотр логов в том же конйтере tail -n 20 /home/app/core/log/office365_migrations.log




# Проверка есть ли на стороне MPC принятое соглашение пользователя 

# Объявить от
module Plugin
  module Office365
    module Api
      class PartnerCenter
        module Client
          module Customer
            def customer_agreements(customer_id)
              uri = URI("#{host}/v1/customers/#{customer_id}/agreements?agreementType=MicrosoftCustomerAgreement")
              send_request_with_check_error(uri: uri, action: :get).parsed_body
            end
          end
        end
      end
    end
  end
end

def create_mpc(reseller_id)
  root_plan = Plan.joins(:plan_category).where(plans: { reseller_id: reseller_id, status: 'active', public: true}, plan_categories: { key: 'microsoft_azure'}).first.root
  plugin_application_template = root_plan.application_templates.first.origin
  return Plugin::Office365::API::PartnerCenter.new(plugin_application_template, Reseller.find(reseller_id))
end

errors = {}
mpc = create_mpc(399);
agreements = {}
# До сюда

# Подставить айди аккаунтов 
account_ids = [14848]
account_ids.each do |account_id|
  begin
    tid = Plugin::Office365::Customer.find_by!(account_id: account_id).tid
    agreements[account_id] = mpc.customer_agreements(tid).fetch(:items)
  rescue => e
    errors[account_id] ||= []
    errors[account_id].push(e)
    if e.is_a?(Plugin::Office365::Api::ClientErrorException)
      puts e.message
      sleep(2)
      retry
    end
  end
end;


# agreements
# errors

# После проверки у тех, кто принял нужно создать 
Plugin::Office365::AgreementAcceptance.create(account_id: 28181, reseller_id: 393, acceptor_ip: "127.0.0.1")

#Большая просьба на будущее: после миграции коммерческих легаси, пожалуйста, возвращайте их первоначальный непубличный статус.
#Так как МС сейчас не продает новые лицензии.

#Академические планы for faculty и for students оставляем публичными.