import base64
from binascii import Error
import io
import httplib2
from googleapiclient.discovery import build
from oauth2client.service_account import ServiceAccountCredentials

# Only for the lasr def in this file
CUSTOMER_DOES_NOT_EXISTS = 0
CUSTOMER_EXIST_IN_RESELLER = 1
CUSTOMER_EXIST = 2
 
 
 
SCOPES = [
    'https://www.googleapis.com/auth/apps.order',
    'https://www.googleapis.com/auth/apps.order.readonly',
    'https://www.googleapis.com/auth/admin.directory.user',
    'https://www.googleapis.com/auth/admin.directory.domain.readonly',
    'https://www.googleapis.com/auth/admin.directory.domain'
]
 
#Information from Google Workspace https://cproot.cloud.softline.ru/plugin/vendor_service/admin/products/336/reseller_attributes?spoof_reseller_id=1
 
service_account_email = "112340973194365285803"
reseller_admin_email = "apuser@reseller.ru.softlinegroup.com"
certificate = "MIIJqAIBAzCCCWIGCSqGSIb3DQEHAaCCCVMEgglPMIIJSzCCBXAGCSqGSIb3DQEHAaCCBWEEggVd MIIFWTCCBVUGCyqGSIb3DQEMCgECoIIE+jCCBPYwKAYKKoZIhvcNAQwBAzAaBBRZV2jN830L74ey kT5vARreEMaNDgICBAAEggTIqffJTWAuZVvFRl920z803ZmOK7V1sa+KLJUkz8q9gGi+gOwTVV8g 68HAYX0poU865Wo2k/fozUNEwpNcqChi6R2aBAG33rBxd/IM/WvcjOdnYd2o6eYuLs7H1WixzjKw pu1ytxrPcz+rKo+7dyux67+B2t1HQE0DH8AW5Fn7bWkAGAJvMlq56uZF0UGyKDIG6u/C7UMxAhAE dkXi+kOLrmYhDDtBtjfEWL+pq1iyqFBUgqNohOhuf2LVC4kKmDupD3HBHc1qWmhFs0Gjlz0zxgaH 3O+JGS8ZfFrqIVl7EMdebDtCCiGtSnXcu3TWp0Ktc6flT0Yd4Sg2dj7EsatG79KyVnkOowE693hs MsowVGATMlSslD68Xif+6kaETqhAh9VOxeMxKmwAAaobhxK66OId0CXUF/E5NHUjAfEn2DuFDTjM ona77lyEBZXpKh8yII9S9jHxbcMDFeiR/n6xJtiier1NxBRUZ6bUC9Gox2D+/O6J7eK3Y6F2LTT6 DAe3cTlXfb6QFCon/mQo7DfZyQJjwr83tjQz8PYliNrCTP8ksaGtZQSn115wZEFK62ImAD3+BNAR A4LsD5gmBotkFVQ0C6jgMchAhIwD19oToBXd4kw4adL/yjdia0a4uh6bVx5MbpFkN/lMBN5bpHig LdXEiJqgqaVZdUQcNzpOSjn/hKS1/XLPwUe7uG/QVuhdsaXyahkQy4uMYLYsUTQfQPrds7jWx+xP RLJZqocRjAh/XDtUrO/lyoPTLfgLCUjQaglRSCNxNmiRAe9L2Md07Uo8QnbjGMc2/zRAONqDl2yA wT4GRzq+H3on0vMchhK7lMIn1LuNpEn9OUi/qbTi5t8gZKwkmfoI9VH1pvEzXm2Dr2DN0dsDHYsP 5Pn+fI8avN4oPZ4JaRzlwRFg84rmtpIaJjgAmz7l/5qzEpZedFSafQps8wpWIAjLxGaX3ecDBLRO oNRNOzoTW0EY3Xl/rkilx7f17QW0HTbfpPeARGnphBSytT8kKlo/bG9dVOJP9yqMPJ7ruQceYOif 9X7NcBkV7DK/ksEW1xnq6tqL7Rg32rxL+a7b0o9MrEub1MJby6Zmiq2TZx86h8yyENkPA0C/5Di7 ROq73pcOGe6h3qvQ6Zrk2bSZKjXSQbewwZQ7pZkCN/2IySRqby55MMUaCqWy1tZTYBvZ+TslHHJ9 W8r/IxyT2B0lyYbXLdSQlzDc2VakKsZh6aXqjnEFby8/ZdIhk6IqacQMYPnkN34B4ZekckxugVIR Xg+8VRh8JkpkSypAV58hG0avEChfADXO+ZMnmp7ZeJLbw6dnXEw7SOnr7xvPGmDrGEmqaCyxnl6R aqdyp6dONq5wAyAn+m1FUA0gNKM1mZZFDMgFUXbp8VN5h3bSqfQifN6/z0bNVFfo+4pf9Cl2IBdG vOrrq5C/ZUvcSmNZ7wcsg2p8UwRoqGBZBdiwYDkj5EcIr4tu68nloIy8XHAZtyzW6zLnNuL/tPvi QHbwJ9o78RKLnlihru1vnq9OLPCrccHD8OoWHD0nSIGCNO0MYNIavGT91FD+Ir1LlAIy7EIxq3zc v12IY3Ir/3q/Fejc/dJR9e2XyWIsasvASANexHyg2eAvv/QzGoGexflPRfD9MUgwIwYJKoZIhvcN AQkUMRYeFABwAHIAaQB2AGEAdABlAGsAZQB5MCEGCSqGSIb3DQEJFTEUBBJUaW1lIDE1MjY5ODAz NjI2MzQwggPTBgkqhkiG9w0BBwagggPEMIIDwAIBADCCA7kGCSqGSIb3DQEHATAoBgoqhkiG9w0B DAEGMBoEFKzo1bg7qioozOSr6M0lZG0zedlPAgIEAICCA4D9gKWJ6X3ccRFc2ixvURmGAt/zhle4 nG6342GWx9cWxlZ2QFhzc2rm21bhe7TTLcS6sCenAMjslSpfsk2yMB70tPoiGqH/irE6luCOr6g8 kRnWkt55EwnzytYSWSg+4z7/vym3bVDPa30ftLugAC87hA01O0UjFQNv4Fg0fYDfPf/CZjV9q3KX To+yGp15RNZT4Jmkq7ZLxdEEiwr7NaqOI9s5kM8B/XtmcbsU1mRAVedIDU5mYB9kxFxwVBHpQ6RZ oI3Tk+qtPF9U6JOoZZfjUNF5BWsCKyd4Uq+kCC1lhl6smyDOyAnZGj2/ZVRkDbr2vc43W+3CpXFb HId6PXvvBCvEvHCp2uPmJvzkuXeuawvSYiz8k4JeOdQxaSZUnvkRVcpTcQuZBJERmRRuypQoZJyj 7dfC2CDMtGWL5Fn4QOuA6GOQRWV0sUMzj4moF86Q+N83LxgW1zEMoWUGfGsMVYb0bLdAS7g9Pp0d ljGhoHtN9ZtnlQ1m6LRz9lgPbTwSkBXDBh1WuAydFJgUWfpQF5/LuztrrIbpD8My4VZgwQ/yXvxg 70VhloTQxs12HQVkV+ZnhNyGVGWZsMTydYKRWut1S9XzHMU1u4CGSLvvOwVKZiJswtNr5ZJQgm7G u7Ai8gt86nZl7ncjXJgmabmNN6GVA/kVBXTvQEuiKiIq3tlondC0lNNf7zwIC1jj/4RDEaqXW2Tp YyUmdoYbdpc2lf9BtE47//JFdEeEf08EqrCXfTbhYNE7cOG0ufzdsZY9whY+sbm6n6NkaPQOLfn+ Ir+W6rpvX0mzYz9VB2VpB22TUsID1UhqSB1Ncj9RMtYLjGiuKs6dTQ83A/lfLQ5pWE77zaVnedhc QJ1TMhExdqbHC7+7Ly0OzYUBiPV3hiQWiin4PlVQqeDEJ1ftZfr/FSwgR+CYEaVU4XCdOfa/22Fm bJbvnJneKrAG4IZxwVZl7AptrBKiqSPml2VUVfiAv7oSesD487NeIIOxQmj0BsVw4cXGf9vw1XKn eie9qQD97IXjeCC3lq5j2UHDp2u//ZVpfJrt90C1aA56DI7pLAPJ3f8V7G/Nb8S+KTJKd8iLllcK JCe/j261uKgX9xfy7IuMEb7oaH55+AjaYHmkPB7wTceDFumhkP+MifomNNE5HndZlp6zL7JabcXJ 8iYEstYYQazOhC6hzlo2qDwuUzA9MCEwCQYFKw4DAhoFAAQUn0FlXmnEirTTsusPf90l+vKSA0IE FHBVJRGMaRkhfQsp/f7NSV9W7g4xAgIEAA==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"
 
 

 
certificate_encoded = base64.b64decode(certificate)
certificate_buffer = io.BytesIO(certificate_encoded)
credentials = ServiceAccountCredentials.from_p12_keyfile_buffer(
            service_account_email,
            file_buffer=certificate_buffer,
            scopes=SCOPES
        ).create_delegated(reseller_admin_email)
 
 
 
http = httplib2.Http()
 
credentials.authorize(http)
 
service = build(serviceName='reseller', version='v1', http=http, cache_discovery=False)
 

#get customer by domain:
customer = service.customers().get(customerId='asgbs.com').execute()
 
#get customer subscriptions
 
kwargs = {'customerId': 'C03x8iep1' }
 
subscriptions_api = service.subscriptions()
request = subscriptions_api.list(**kwargs)
 
response = request.execute()

# If we have  <HttpError 403 when requesting https://reseller.googleapis.com/apps/reseller/v1/subscriptions?customerId=C00w0dezl&alt=json returned "Forbidden">
# That means this customer does not have any subscriptions


# Cancel subscription

request = service.subscriptions().delete(customerId='C02j158gd', subscriptionId='2562484789', deletionType='transfer_to_direct')
response = request.execute()



#check customer status
def check_customer_status(customer):
    """
    Check customer status by data returned fetch_customer
 
    :param customer: customer data dict or None
    :return:
        CUSTOMER_DOES_NOT_EXISTS
        CUSTOMER_EXIST_IN_RESELLER
        CUSTOMER_EXIST
    """
    assert isinstance(customer, dict) or customer is None, f'{type(customer)}: {customer}'
    if customer is None:
        return CUSTOMER_DOES_NOT_EXISTS
    elif 'alternateEmail' in customer:
        return CUSTOMER_EXIST_IN_RESELLER
    return CUSTOMER_EXIST