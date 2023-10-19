load '/app/support/support_scripts/ms_legasy_migrator/migrate_ms_legasy.rb'

reseller_id = 447
account_id = 21362
tenant_id = 'ae544a57-aecb-4bf9-828a-5b520732b110'
tenant_name = 'upc.pe'
data = {
    '8D95FBC2-C5A2-4670-9105-CD7BBB3E2A8B' => 4.24
}


migrator = SupportTeam::MigrateLegasy.new(reseller_id: reseller_id, account_id: account_id, tenant_id: tenant_id, tenant_name: tenant_name, individual_prices: data, generate_charges_from_next_billing_day: false)


migrator.call

migrator.find_plan

migrator.run_migration(env: :test)

migrator.run_migration(env: :go)