select r.id APReseller_id, a.id as account_id, s.id as sab_id, s.status as sub_status, a."name" as acc_name, s."name" as sub_name,
coalesce (poa.external_id, msp.external_id) as ms_sub_id,
coalesce (poc.tid, pocc.tid) as MS_tenant_ID,
coalesce (poc."domain", pocc."domain") as tenant_name,
coalesce (cav.value, cavv.value) as TAX_ID,
u.email email_owner
from subscriptions s
join accounts a on a.id = s.account_id
join resellers r on r.id = a.reseller_id
join applications ap on ap.subscription_id = s.id
join account_accesses aa on a.id = aa.account_id
    and aa."role" = 'owner'
join users u on u.id = aa.user_id
left join custom_attributes ca on ca.reseller_id = r.id
     and ca."key" = 'tax_id'
left join custom_attribute_values cav on cav.custom_attribute_id = ca.id
    and cav.attributable_id = a.id
    and cav.attributable_type = 'Account'
left join custom_attributes caa on caa.reseller_id = r.id
     and caa."key" = 'inn'
     and caa.applied_to = 'account'
left join custom_attribute_values cavv on cavv.custom_attribute_id = caa.id
    and cavv.attributable_id = a.id
    and cavv.attributable_type = 'Account'
left join plugin_office365_applications poa on poa.id = ap.origin_id
    and ap.origin_type = 'Plugin::Office365::Application'
left join plugin_office365_customers poc on poc.id = poa.customer_id
left join plugin_microsoft_csp_products_applications msp on msp.id = ap.origin_id
    and ap.origin_type = 'Plugin::MicrosoftCspProducts::Application'
left join plugin_office365_customers pocc on pocc.id = msp.customer_id
where s.status != '%deleted%' and a.reseller_id in (392, 393, 452, 456, 447, 460, 536, 400, 419, 337, 530)
order by s.id;