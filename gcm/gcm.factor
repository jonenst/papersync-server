! Copyright (C) 2013 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs http http.client io.encodings.string
io.encodings.utf8 io.sockets.secure json.reader json.writer
kernel math sequences urls papersync-server.conf ;
IN: papersync-server.gcm

CONSTANT: GCM-SEND-URL URL" https://android.googleapis.com/gcm/send"

: build-assoc ( value key assoc -- assoc' ) [ set-at ] keep ; inline
: prepare-data ( url -- data )
  H{ } clone
    [ "url" ] dip build-assoc ;
: prepare-gcm-data ( url ids -- hash ) 
  [ prepare-data ] dip H{ } clone
    [ "registration_ids" ] dip build-assoc
    [ "data" ] dip build-assoc ;

: gcm-post-data ( url ids -- post-data )
  dup length 1000 > [ "Attempting to multicast to more than 1000 ids" throw ] when
  prepare-gcm-data "application/json" <post-data> 
  swap >json utf8 encode >>data ;

: gcm-test-data ( -- data )
  "http://factorcode.org/logo.png" { 42 } gcm-post-data ;
  
: (gcm-send) ( post-data -- response-data ) 
  GCM-SEND-URL <post-request>
    GCM-API-KEY "Authorization" set-header
  http-request nip json> ;
: gcm-test-send ( -- response ) gcm-test-data (gcm-send) ;

: gcm-send ( url ids -- response-data )
    gcm-post-data (gcm-send) ;
