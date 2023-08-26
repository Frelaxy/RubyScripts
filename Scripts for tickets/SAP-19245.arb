def search_charges_withoit_invoice()
  subs_ids = Plugin::MicrosoftCspProducts::NCESubscriptionMigration.where(status: :completed).pluck(:subscription_id);
  progressbar = ProgressBar.create(total: subs_ids.count, format: 'Processed: %P%% (%c out of %C) |%B|');
  @charges_without_invoices = []

  Subscription.where(id: subs_ids).find_each do |subscription|
      charges_ids_from_invoices = subscription.account.invoices.map { |invoice| invoice.charges.ids }.flatten;
      charges_ids = subscription.charges.where(status: :closed).ids

      @charges_without_invoices << charges_ids.difference(charges_ids_from_invoices)
      progressbar.increment
  end
  @charges_without_invoices.flatten!
end