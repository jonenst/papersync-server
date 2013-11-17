! Copyright (C) 2013 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: FriendPaper.gcm accessors assocs continuations db.sqlite
furnace.actions furnace.alloy furnace.auth furnace.auth.basic
furnace.auth.features.registration furnace.auth.providers
furnace.json html.forms http.server http.server.dispatchers
http.server.responses io.servers io.sockets.secure kernel
logging namespaces sequences sets validators vectors ;
IN: FriendPaper

LOG: current-username DEBUG
LOG: register-regid DEBUG
: log-current-user ( -- ) logged-in-user get username>> current-username ;

: ?vector-adjoin ( elt set/f -- set' )
  [ 1 <vector> ] unless* [ adjoin ] keep ;
: uadjoin ( value key -- ) [ ?vector-adjoin ] with uchange ;
: register-id-submit ( -- response )
  log-current-user
  "regid" [ value dup register-regid ] [ uadjoin ] bi
  t <json-content> ;
: register-id-validate ( -- )
  { { "regid" [ v-required ] } } validate-params ;
: <register-id-action> ( -- action )
  <action>
    [ register-id-validate ] >>validate
    [ register-id-submit ] >>submit  ;

LOG: paired-username DEBUG
LOG: paired-user-ids DEBUG
LOG: current-user-ids DEBUG
: paired-regid ( -- ids )
  "pair-username" uget dup paired-username [ users get-user
   profile>> "regid" of dup paired-user-ids ] [ f ] if*
   profile   "regid" of dup current-user-ids union ;

LOG: gcm-response DEBUG
LOG: gcm-error ERROR
: send-submit ( -- response )
  log-current-user
  "url" value paired-regid
  [ gcm-send gcm-response t <json-content> ]
  [ gcm-error 2drop <400> ] recover ;
: send-validate ( -- )
  { { "url" [ v-url ] } } validate-params ;
: <send-action> ( -- action )
  <action>
    [ send-validate ] >>validate
    [ send-submit ] >>submit  ;

: (pair-users) ( userA userB -- userA userB' )
  [ [ username>> "pair-username" ] [ profile>> ] bi* set-at ] 2keep ;
: users-changed ( userA userB -- )
  [ t swap changed?<< ] bi@ ;
: pair-users ( userA userB -- )
    (pair-users) swap (pair-users) users-changed ;
: pair-submit ( -- response )
  log-current-user
  "pair-username" value dup paired-username users get-user dup [ save-user-after ] when*
  logged-in-user get 2dup and [
    pair-users t <json-content>
  ] [ 2drop <400> ] if ;
: pair-validate ( -- )
  { { "pair-username" [ v-username ] } } validate-params ;
: <pair-action> ( -- action )
  <action>
    [ pair-validate ] >>validate
    [ pair-submit ] >>submit ;

: nop-display ( -- response ) t <json-content> ;
: <check-action> ( -- action )
  <action>
    [ nop-display ] >>display ;

TUPLE: friend-paper-app < dispatcher ;
: <friend-paper-dispatcher> ( -- responder )
    friend-paper-app new-dispatcher
        <register-id-action> "register-id" add-responder
        <pair-action> "pair" add-responder
        <check-action> "check" add-responder
        <send-action> "send" add-responder <protected> ;

! Deployment example
USING: db.sqlite furnace.alloy namespaces ;

: friend-paper-db ( -- db ) "resource:friend-paper.db" <sqlite-db> ;

: <auth-config> ( responder -- responder' )
  "FriendPaper" <basic-auth-realm>
    allow-registration ;

: <friend-paper-secure-config> ( -- config )
  ! This is only suitable for testing!
  <secure-config>
    "vocab:openssl/test/dh1024.pem" >>dh-file
    "vocab:openssl/test/server.pem" >>key-file
    "password" >>password ;

: <friend-paper-app> ( -- responder )
  <friend-paper-dispatcher>
    <auth-config>
    friend-paper-db <alloy> ;

: <friend-paper-website-server> ( -- threaded-server )
  <http-server>
    "FriendPaper" >>name
    <friend-paper-secure-config> >>secure-config
    8080 >>insecure
    8431 >>secure ;

: run-friend-paper ( -- )
  <friend-paper-app> main-responder set-global
  friend-paper-db start-expiring
  <friend-paper-website-server> start-server drop ;

MAIN: run-friend-paper
