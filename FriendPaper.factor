! Copyright (C) 2013 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: FriendPaper.gcm accessors assocs db db.sqlite db.tuples db.types
furnace.actions furnace.alloy furnace.auth furnace.auth.basic
furnace.auth.features.registration furnace.auth.providers
furnace.json html.forms http.server http.server.dispatchers
http.server.responses io.servers io.sockets.secure kernel
namespaces validators logging io sets vectors continuations ;
IN: FriendPaper

LOG: log-value DEBUG
: ?vector-adjoin ( elt set/f -- set' )
    [ 1 <vector> ] unless* [ adjoin ] keep ;
: uadjoin ( value key -- ) [ ?vector-adjoin ] with uchange ;
: <register-id-action> ( -- action )
  <action>
    [
      { { "regid" [ v-required ] } } validate-params
    ] >>validate

    [
      "regid" [ value dup log-value ] [ uadjoin ] bi
      t <json-content>
    ] >>submit  ;

LOG: paired-username DEBUG
LOG: luser-profile DEBUG
LOG: user-ids DEBUG
: paired-regid ( -- ids )
    "pair-username" uget dup paired-username
    users get-user profile>> dup luser-profile
    "regid" of dup user-ids ;

LOG: log-response DEBUG
LOG: gcm-error ERROR
: send-submit ( -- response )
  "url" value paired-regid
  [ gcm-send log-response t <json-content> ]
  [ gcm-error 2drop <400> ] recover ;
: <send-action> ( -- action )
  <action>
    [
      { { "url" [ v-url ] } } validate-params
    ] >>validate
    
    [ send-submit ] >>submit  ;

: (pair-users) ( userA userB -- userA userB' )
  [ [ username>> "pair-username" ] [ profile>> ] bi* set-at ] 2keep ;

: users-changed ( userA userB -- )
  [ t swap changed?<< ] bi@ ;
: pair-users ( userA userB -- )
    (pair-users) swap (pair-users) users-changed ;
: pair-submit ( -- response )
  "pair-username" value users get-user
  logged-in-user get 2dup or [
    pair-users t <json-content>
  ] [ 2drop <400> ] if ;
: <pair-action> ( -- action )
  <action>
    [
      { { "pair-username" [ v-username ] } } validate-params
    ] >>validate
    
    [ pair-submit ] >>submit ;

TUPLE: friend-paper-app < dispatcher ;
: <friend-paper-dispatcher> ( -- responder )
    friend-paper-app new-dispatcher
        <register-id-action> "register-id" add-responder
        <pair-action> "pair" add-responder
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
       <friend-paper-secure-config> >>secure-config
       8080 >>insecure
       8431 >>secure ;

: run-friend-paper ( -- )
    <friend-paper-app> main-responder set-global
    friend-paper-db start-expiring
    <friend-paper-website-server> start-server drop ;

MAIN: run-friend-paper
