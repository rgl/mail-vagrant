import smtplib

fromaddr = 'alice@@@config_domain@@'
toaddrs = ('bob@@@config_domain@@',)
body = 'Test'

msg = 'From: %s\r\nTo: %s\r\n\r\n' % (fromaddr, ', '.join(toaddrs))
msg = msg + body
server = smtplib.SMTP('mail.@@config_domain@@')
server.set_debuglevel(1)
try:
    server.sendmail(fromaddr, toaddrs, msg)
    raise Exception('Oh something is wrong... the server should have rejected our email because we did not authenticate')
except smtplib.SMTPRecipientsRefused:
    print('this smtplib.SMTPRecipientsRefused exception was expected since we did not authenticate.')
server.quit()
