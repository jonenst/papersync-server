! Copyright (C) 2013 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: ;
IN: papersync-server.conf

! Example configuration
! This is only suitable for testing!

! Google cloud messenging
CONSTANT: GCM-API-KEY "key=YOURKEY"

! ports
CONSTANT: INSECURE-PORT 8080
CONSTANT: SECURE-PORT   8431

! Secure config parameters
CONSTANT: DH-FILE  "vocab:openssl/test/dh1024.pem"
CONSTANT: KEY-FILE "vocab:openssl/test/server.pem"
CONSTANT: PASSWORD "password"
