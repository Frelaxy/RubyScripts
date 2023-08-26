=begin
1) Настройки редиректа со страницы Вход и Регистрация сущ CCP на New CCP:
  п.1 – обязателен всегда.
  {domain} – это домен реселлера, который переходит на NewCCP, Мексика (mx.subs.noventiq.com). Только для этих стран должен работать редирект.

  a. https://{domain}/sign_in 
  редирект на 
  https://{domain}/client/auth/sign_in

  b. https://{domain}/signup_users/new 
  редирект на 
  https://{domain}/client/auth/sign_up

2) Настройка редиректа на New CCP с Payment Gateway
  п.2 – обязателен, если страна использует способы оплаты, основанные на внешнем плагине (оплата картами) – Мексика (mx.subs.noventiq.com).

  a. https://{domain}/accounts/{account_id}/payments/completed 
  редирект на
  https://{domain}/client/billing/payment_completed

  b. https://{domain}/accounts/{account_id}/payments/canceled
  редирект на 
  https://{domain}/client/billing/payment_cancelled

3)В Настройках Office365 на прайсовом уровне заполнить ссылку на агримент MS – поле Microsoft Customer Agreement URL - https://www.microsoft.com/licensing/docs/customeragreement

4)на страницу Вход: Витрина-> Меню-> My subscription - https:// {domain}/client;
Например, https://mx.subs.noventiq.com/client

5)заменить ссылки для покупки подписок: OCP->Витрина (Storefront) поле External application URL. Например, https://mx.subs.noventiq.com/client/new_order

6)Изменение признака Опубликован в атрибуте user_manual в апликейшен темплейтах для услуг на основании VSP (чтобы отображались инструкции на детальной подписки)
  -в коннекторах если есть VendorService Plugin у реселлера
  -в вендор портал и там в продукте который закинут в реселлер меняешь статус атрибута который просят
=end

#############################        Эквадор - пункты 1 и 3            #############################
		1) 
		a. https://ec.subs.noventiq.com/sign_in -> https://ec.subs.noventiq.com/client/auth/sign_in
		b. https://ec.subs.noventiq.com/signup_users/new -> https://ec.subs.noventiq.com/client/auth/sign_up

		Решение:
		Добавить в файл конфигурации nginx ec.subs.noventiq.com редиректы:

		sudo docker cp web-nginx-1:/etc/nginx/sites-available/ec.subs.noventiq.com /tmp/sap_18738

		location /sign_in {
			return 301 /client/auth/sign_in;
		}

		location /signup_users/new {
			return 301 /client/auth/sign_up;
		}

		sudo docker cp /tmp/sap_18738/ec.subs.noventiq.com  web-nginx-1:/etc/nginx/sites-available/ec.subs.noventiq.com 

		sudo docker exec web-nginx-1 nginx -t

		sudo docker exec web-nginx-1 nginx -s reload

		3) https://www.microsoft.com/licensing/docs/customeragreement
		Через UI Office365 на прайсе
		или 
		Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

#############################          Диджитек - пункты 1, 3, 4 и 5           #############################
  1)
  a. https://manage.digitech-eg.com/sign_in -> https://manage.digitech-eg.com/client/auth/sign_in
  b. https://manage.digitech-eg.com/signup_users/new -> https://manage.digitech-eg.com/client/auth/sign_up

  Решение:
  Добавить в файл конфигурации nginx manage.digitech-eg.com редиректы:

  sudo docker cp web-nginx-1:/etc/nginx/sites-available/manage.digitech-eg.com /tmp/sap_18738

  location /sign_in {
    return 301 /client/auth/sign_in;
  }

  location /signup_users/new {
    return 301 /client/auth/sign_up;
  }

  sudo docker cp /tmp/sap_18738/manage.digitech-eg.com  web-nginx-1:/etc/nginx/sites-available/manage.digitech-eg.com 

  sudo docker exec web-nginx-1 nginx -t

  sudo docker exec web-nginx-1 nginx -s reload

  3) https://www.microsoft.com/licensing/docs/customeragreement
  Через UI Office365 на прайсе
  или 
  Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

  4) https://manage.digitech-eg.com/client
  Через UI Storefront на Т1
  5) https://manage.digitech-eg.com/client/new_order
  Через UI Storefront на Т1

#############################                  Камбоджа - пункты 1, 3, 4 и 5             #############################

  1)
  a. https://kh.subs.noventiq.com/sign_in -> https://kh.subs.noventiq.com/client/auth/sign_in
  b. https://kh.subs.noventiq.com/signup_users/new -> https://kh.subs.noventiq.com/client/auth/sign_up

  Решение:
  Добавить в файл конфигурации nginx kh.subs.noventiq.com редиректы:

  sudo docker cp web-nginx-1:/etc/nginx/sites-available/kh.subs.noventiq.com /tmp/sap_18675

  location /sign_in {
    return 301 /client/auth/sign_in;
  }

  location /signup_users/new {
    return 301 /client/auth/sign_up;
  }

  sudo docker cp /tmp/sap_18675/kh.subs.noventiq.com  web-nginx-1:/etc/nginx/sites-available/kh.subs.noventiq.com

  sudo docker exec web-nginx-1 nginx -t

  sudo docker exec web-nginx-1 nginx -s reload

  3) https://www.microsoft.com/licensing/docs/customeragreement
  Через UI Office365 на прайсе
  или 
  Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

  4) https://kh.subs.noventiq.com/client
  Через UI Storefront на Т1
  5) https://kh.subs.noventiq.com/client/new_order
  Через UI Storefront на Т1



#############################                   Мьянма - пункты 1, 3, 4 и 5              #############################
  1)
  a. https://mm.subs.noventiq.com/sign_in -> https://mm.subs.noventiq.com/client/auth/sign_in
  b. https://mm.subs.noventiq.com/signup_users/new -> https://mm.subs.noventiq.com/client/auth/sign_up

  Решение:
  Добавить в файл конфигурации nginx mm.subs.noventiq.com редиректы:

  sudo docker cp web-nginx-1:/etc/nginx/sites-available/mm.subs.noventiq.com /tmp/sap_18675

  location /sign_in {
    return 301 /client/auth/sign_in;
  }

  location /signup_users/new {
    return 301 /client/auth/sign_up;
  }

  sudo docker cp /tmp/sap_18675/mm.subs.noventiq.com  web-nginx-1:/etc/nginx/sites-available/mm.subs.noventiq.com

  sudo docker exec web-nginx-1 nginx -t

  sudo docker exec web-nginx-1 nginx -s reload

  3) https://www.microsoft.com/licensing/docs/customeragreement
  Через UI Office365 на прайсе
  или 
  Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

  4) https://mm.subs.noventiq.com/client
  Через UI Storefront на Т1
  5) https://mm.subs.noventiq.com/client/new_order
  Через UI Storefront на Т1
#############################        Индия - пункты 1 и 3, 4, 5,6            #############################
  1)
  a. https://in.subs.noventiq.com/sign_in -> https://in.subs.noventiq.com/client/auth/sign_in
  b. https://in.subs.noventiq.com/signup_users/new -> https://in.subs.noventiq.com/client/auth/sign_up

  Решение:
  Добавить в файл конфигурации nginx in.subs.noventiq.com редиректы:

  sudo docker cp web-nginx-1:/etc/nginx/sites-available/in.subs.noventiq.com /tmp/sap_18738

  location /sign_in {
    return 301 /client/auth/sign_in;
  }

  location /signup_users/new {
    return 301 /client/auth/sign_up;
  }

  sudo docker cp /tmp/sap_18738/in.subs.noventiq.com  web-nginx-1:/etc/nginx/sites-available/in.subs.noventiq.com 

  sudo docker exec web-nginx-1 nginx -t

  sudo docker exec web-nginx-1 nginx -s reload

  3) https://www.microsoft.com/licensing/docs/customeragreement
  Через UI Office365 на прайсе
  или 
  Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

  4) https://in.subs.noventiq.com/client
  Через UI Storefront на Т1
  5) https://in.subs.noventiq.com/client/new_order
  Через UI Storefront на Т1
  6)Изменение признака Опубликован в атрибуте user_manual в апликейшен темплейтах для услуг на основании VSP

#############################        Малайзия - пункты 1 и 3, 4, 5, 6            #############################
  1)
  a. https://my.subs.noventiq.com/sign_in -> https://my.subs.noventiq.com/client/auth/sign_in
  b. https://my.subs.noventiq.com/signup_users/new -> https://my.subs.noventiq.com/client/auth/sign_up

  Решение:
  Добавить в файл конфигурации nginx my.subs.noventiq.com редиректы:

  sudo docker cp web-nginx-1:/etc/nginx/sites-available/my.subs.noventiq.com /tmp/sap_18738

  location /sign_in {
    return 301 /client/auth/sign_in;
  }

  location /signup_users/new {
    return 301 /client/auth/sign_up;
  }

  sudo docker cp /tmp/sap_18738/my.subs.noventiq.com  web-nginx-1:/etc/nginx/sites-available/my.subs.noventiq.com 

  sudo docker exec web-nginx-1 nginx -t

  sudo docker exec web-nginx-1 nginx -s reload

  3) https://www.microsoft.com/licensing/docs/customeragreement
  Через UI Office365 на прайсе
  или 
  Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

  4) https://my.subs.noventiq.com/client
  Через UI Storefront на Т1
  5) https://my.subs.noventiq.com/client/new_order
  Через UI Storefront на Т1
  6)Изменение признака Опубликован в атрибуте user_manual в апликейшен темплейтах для услуг на основании VSP


	#############################        Беларусь - пункты 1 и 3, 4, 5, 6            #############################
  1)
  a. https://by.subs.noventiq.com/sign_in -> https://by.subs.noventiq.com/client/auth/sign_in
  b. https://by.subs.noventiq.com/signup_users/new -> https://by.subs.noventiq.com/client/auth/sign_up

  Решение:
  Добавить в файл конфигурации nginx by.subs.noventiq.com редиректы:

  sudo docker cp web-nginx-1:/etc/nginx/sites-available/by.subs.noventiq.com /tmp/SAP_18789

  location /sign_in {
    return 301 /client/auth/sign_in;
  }

  location /signup_users/new {
    return 301 /client/auth/sign_up;
  }

  sudo docker cp /tmp/sap_18738/by.subs.noventiq.com  web-nginx-1:/etc/nginx/sites-available/by.subs.noventiq.com 

  sudo docker exec web-nginx-1 nginx -t

  sudo docker exec web-nginx-1 nginx -s reload

  3) https://www.microsoft.com/licensing/docs/customeragreement
  Через UI Office365 на прайсе
  или 
  Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

  4) https://my.subs.noventiq.com/client
  Через UI Storefront на Т1
  5) https://my.subs.noventiq.com/client/new_order
  Через UI Storefront на Т1
  6)Изменение признака Опубликован в атрибуте user_manual в апликейшен темплейтах для услуг на основании VSP

	#############################        Казахстан - пункты 1 и 3, 4, 5, 6            #############################
	1)
  a. https://kz.subs.noventiq.com/sign_in -> https://kz.subs.noventiq.com/client/auth/sign_in
  b. https://kz.subs.noventiq.com/signup_users/new -> https://kz.subs.noventiq.com/client/auth/sign_up

  Решение:
  Добавить в файл конфигурации nginx kz.subs.noventiq.com редиректы:

  sudo docker cp web-nginx-1:/etc/nginx/sites-available/kz.subs.noventiq.com /tmp/SAP_18789

  location /sign_in {
    return 301 /client/auth/sign_in;
  }

  location /signup_users/new {
    return 301 /client/auth/sign_up;
  }

  sudo docker cp /tmp/SAP_18789/kz.subs.noventiq.com  web-nginx-1:/etc/nginx/sites-available/kz.subs.noventiq.com 

  sudo docker exec web-nginx-1 nginx -t

  sudo docker exec web-nginx-1 nginx -s reload

  3) https://www.microsoft.com/licensing/docs/customeragreement
  Через UI Office365 на прайсе
  или 
  Plugin::Office365::Setting.find(айди_настроек) и в поле добавить ссылку

  4) https://by.subs.noventiq.com/client
  Через UI Storefront на Т1
  5) https://by.subs.noventiq.com/client/new_order
  Через UI Storefront на Т1
  6)Изменение признака Опубликован в атрибуте user_manual в апликейшен темплейтах для услуг на основании VSP
