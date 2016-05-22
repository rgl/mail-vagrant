import smtplib

fromaddr = 'alice@@@config_domain@@'
toaddrs = ('bob@@@config_domain@@',)
body = 'Test'

msg = 'From: %s\r\nTo: %s\r\n\r\n' % (fromaddr, ', '.join(toaddrs))
msg = msg + body
server = smtplib.SMTP('mail.@@config_domain@@')
server.set_debuglevel(1)
server.sendmail(fromaddr, toaddrs, msg)
server.quit()