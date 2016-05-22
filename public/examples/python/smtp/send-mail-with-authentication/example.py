import smtplib

user = 'bob@@@config_domain@@'
password = 'password'

fromaddr = user
toaddrs = ('alice@@@config_domain@@',)
body = 'Test'

msg = 'From: %s\r\nTo: %s\r\n\r\n' % (fromaddr, ', '.join(toaddrs))
msg = msg + body
server = smtplib.SMTP('mail.@@config_domain@@')
server.set_debuglevel(1)
server.starttls() # for SSL use the SMTP_SSL class instead of SMTP.
server.login(user, password)
server.sendmail(fromaddr, toaddrs, msg)
server.quit()