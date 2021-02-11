#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

## ISSUER
cat <<EOF | zexe issuer_keygen.zen | tee issuer_key.json
Scenario multidarkroom
Given I am 'The Authority'
when I create the issuer key
Then print my 'issuer key'
EOF

cat <<EOF | zexe issuer_credential.zen -k issuer_key.json | tee credential.json
Scenario multidarkroom
Given I am 'The Authority'
and I have my 'issuer key'
when I create the credential
Then print my 'credential'
EOF
##

generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe keygen_${1}.zen | tee keypair_${1}.json
Scenario multidarkroom
Given I am '${1}'
When I create the keypair
Then print my 'keypair'
EOF

	cat <<EOF | zexe pubkey_${1}.zen -k keypair_${1}.json | tee verifier_${1}.json
Scenario multidarkroom
Given I am '${1}'
and I have my 'keypair'
When I create the verifier
Then print my 'verifier'
EOF

	cat <<EOF | zexe request_${1}.zen -k keypair_${1}.json | tee request_${1}.json
Scenario multidarkroom
Given I am '${1}'
and I have my 'keypair'
When I create the issuance request
Then print my 'issuance request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe issuer_sign_${1}.zen -k issuer_key.json -a request_${1}.json | tee issuer_signature_${1}.json
Scenario multidarkroom
Given I am 'The Authority'
and I have my 'issuer key'
and I have a 'issuance request' in '${1}'
when I create the issuer signature
Then print my 'issuer signature'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe aggr_cred_${1}.zen -k keypair_${1}.json -a issuer_signature_${1}.json | tee verified_credential_${1}.json
Scenario multidarkroom
Given I am '${1}'
and I have my 'keypair'
and I have a 'issuer signature' in 'The Authority'
when I create the verified credential
then print my 'verified credential'
and print my 'keypair'
EOF
	##

}

# generate two signed credentials
generate_participant "Alice"
generate_participant "Bob"

# join the verifiers of signed credentials
json_join verifier_Alice.json verifier_Bob.json > verifiers.json

echo "{\"today\": \"`date +'%s'`\"}" > uid.json

# anyone can start a session

# SIGNING SESSION
cat <<EOF | zexe session_start.zen -k uid.json -a verifiers.json > multisignature.json
Scenario multidarkroom
Given I have a 'verifier' from 'Alice'
and I have a 'verifier' from 'Bob'
and I have a 'string' named 'today'
When I create the multisignature with uid 'today'
Then print the 'multisignature'
EOF
#

# anyone can require a verified credential to be able to sign, chosing
# the right issuer verifier for it
json_join credential.json multisignature.json > credential_to_sign.json


# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe sign_session.zen -a credential_to_sign.json -k verified_credential_$name.json | tee signature_$name.json
Scenario multidarkroom
Given I am '$name'
and I have my 'verified credential'
and I have my 'keypair'
and I have a 'multisignature'
and I have a 'credential' from 'The Authority'
When I create the signature
Then print the 'signature'
EOF
}

participant_sign 'Alice'
participant_sign 'Bob'

function collect_sign() {
	local name=$1
	local tmp_msig=`mktemp`
	local tmp_sig=`mktemp`
	cp -v multisignature.json $tmp_msig
	json_join credential.json signature_$name.json > $tmp_sig
	cat << EOF | zexe collect_sign.zen -a $tmp_msig -k $tmp_sig | tee multisignature.json
Scenario multidarkroom
Given I have a 'multisignature'
and I have a 'credential' from 'The Authority'
and I have a 'signature'
When I prepare credentials for verification
and I verify the signature credential
and I check the signature fingerprint is new
and I add the fingerprint to the multisignature
and I add the signature to the multisignature
Then print the 'multisignature'
EOF
	rm -f $tmp_msig $tmp_sig
}

# COLLECT UNIQUE SIGNATURES
collect_sign 'Alice'
collect_sign 'Bob'

# VERIFY SIGNATURE
cat << EOF | zexe verify_sign.zen -a multisignature.json | jq .
Scenario multidarkroom
Given I have a 'multisignature'
When I verify the multisignature is valid
Then print 'SUCCESS'
and print the 'multisignature'
EOF

