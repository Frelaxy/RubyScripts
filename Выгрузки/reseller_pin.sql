select r.id as reseller_id, r."name" as reseller_name, ca."name"  as attribute_name, cav.value as resseller_pin
from custom_attributes ca
left join custom_attribute_values cav on cav.custom_attribute_id = ca.id
left join resellers r on r.id = cav.attributable_id
where ca.key = 'reseller_pin' and cav.value != ''