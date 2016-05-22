import imaplib

user = 'alice@@@config_domain@@'
password = 'password'

server = imaplib.IMAP4('mail.@@config_domain@@')
server.debug = 4
server.starttls()
server.login(user, password)
server.enable('UTF8=ACCEPT')
server.select('INBOX', True)
typ, data = server.search(None, 'ALL')
for num in data[0].split():
    typ, data = server.fetch(num, '(RFC822)')
    print('# message %s\n' % num.decode('utf-8'))
    print(data[0][1].decode('utf-8'))
server.close()
server.logout()