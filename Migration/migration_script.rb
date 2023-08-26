load '/app/support/support_scripts/ms_legasy_migrator/migrate_ms_legasy.rb'

reseller_id = 447
account_id = 30624
tenant_id = 'f1752cab-9961-4ece-89b7-f93027f72de2'
tenant_name = 'uap.edu.pe'
data = {
    '9bb27672-a926-4f5d-aac1-31bdd7569b1c' => 8.75
}


migrator = SupportTeam::MigrateLegasy.new(reseller_id: reseller_id, account_id: account_id, tenant_id: tenant_id, tenant_name: tenant_name, individual_prices: data, generate_charges_from_next_billing_day: false)


migrator.call

migrator.find_plan

migrator.run_migration(env: :test)

migrator.run_migration(env: :go)