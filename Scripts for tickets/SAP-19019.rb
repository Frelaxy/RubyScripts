subs_ids = Plugin::MicrosoftCspProducts::NCESubscriptionMigration.where("term_duration = 'P1M' and duration > 0.1e1 and status = 'completed' and generate_charges = 'true'").map {|migration| migration.subscription_id}
subs = Subscription.where(id: subs_ids).select {|sub| sub.charges.where("duration > 0.1e1").count > 0}
charges = subs.map {|sub| sub.charges.where("duration > 0.1e1")}
subs.map do |sub|
  puts "Sub_id: #{sub.id} Reseller_id: #{sub.reseller.id}"
end