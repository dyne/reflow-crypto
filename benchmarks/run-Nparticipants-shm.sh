#!/usr/bin/env bash



####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

# agent: issuer
# verb: create
# obj: issuer key
# obj: credential (= issuer public key)
# obj: signed credential request (= issuer signature)

# agent: participant
# verb:  create
# obj:   key
# obj:   credential request (~= issuance request)
# obj:   verifier (= public key)
# verb:  aggregate
# obj:   verifiable credential
# participant create [ keypair | request]
# participant aggregate verified credential


# echo "${red}red text ${green}green text${reset}"
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`


#################
# Change this to change the amount of participants

Participants=4
Cycles=4

#################

mkdir -p ./files

users=""
for i in $(seq $Participants)
do
  users+=" Participant_${i}"
done

cycles=""
for i in $(seq $Cycles)
do
  cycles+=" Cycles_${i}"
done

# for user in ${users[@]}
# do
# echo  ${user}
# done

# exit 0


issuer_keygen_sign() {
## ISSUER SIGNS

cat <<EOF | zexe /dev/shm/files/issuer_keygen.zen  | jq . | tee /dev/shm/files/issuer_key.json
Scenario multidarkroom
Given I am 'The Authority'
when I create the issuer key
Then print my 'issuer key'
EOF

cat <<EOF | zexe /dev/shm/files/issuer_credential.zen -k /dev/shm/files/issuer_key.json  | jq . | tee /dev/shm/files/credential.json
Scenario multidarkroom
Given I am 'The Authority'
and I have my 'issuer key'
when I create the credential
Then print my 'credential'
EOF
##

	cat <<EOF | zexe /dev/shm/files/issuer_sign_${1}.zen -k /dev/shm/files/issuer_key.json -a /dev/shm/files/request_${1}.json  | jq . | tee /dev/shm/files/issuer_signature_${1}.json
Scenario multidarkroom
Given I am 'The Authority'
and I have my 'issuer key'
and I have a 'issuance request' in '${1}'
when I create the issuer signature
Then print my 'issuer signature'
EOF
	##

}


for user in ${users[@]}
do
issuer_keygen_sign ${user}
echo  "Issuer creates keypair, verifier and signs the request from: "  ${user}
done

# exit 0


## ISSUER
cat <<EOF | zexe /dev/shm/files/issuer_keygen.zen  | jq . | tee /dev/shm/files/issuer_key.json
Scenario multidarkroom
Given I am 'The Authority'
when I create the issuer key
Then print my 'issuer key'
EOF

cat <<EOF | zexe /dev/shm/files/issuer_credential.zen -k /dev/shm/files/issuer_key.json  | jq . | tee /dev/shm/files/credential.json
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
	cat <<EOF | zexe /dev/shm/files/keygen_${1}.zen  | jq . | tee /dev/shm/files/keypair_${1}.json
Scenario multidarkroom
Given I am '${1}'
When I create the keypair
Then print my 'keypair'
EOF

	cat <<EOF | zexe /dev/shm/files/pubkey_${1}.zen -k /dev/shm/files/keypair_${1}.json  | jq . | tee /dev/shm/files/verifier_${1}.json
Scenario multidarkroom
Given I am '${1}'
and I have my 'keypair'
When I create the verifier
Then print my 'verifier'
EOF

	cat <<EOF | zexe /dev/shm/files/request_${1}.zen -k /dev/shm/files/keypair_${1}.json  | jq . | tee /dev/shm/files/request_${1}.json
Scenario multidarkroom
Given I am '${1}'
and I have my 'keypair'
When I create the issuance request
Then print my 'issuance request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe /dev/shm/files/issuer_sign_${1}.zen -k /dev/shm/files/issuer_key.json -a /dev/shm/files/request_${1}.json  | jq . | tee /dev/shm/files/issuer_signature_${1}.json
Scenario multidarkroom
Given I am 'The Authority'
and I have my 'issuer key'
and I have a 'issuance request' in '${1}'
when I create the issuer signature
Then print my 'issuer signature'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe /dev/shm/files/aggr_cred_${1}.zen -k /dev/shm/files/keypair_${1}.json -a /dev/shm/files/issuer_signature_${1}.json  | jq . | tee /dev/shm/files/verified_credential_${1}.json
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

for user in ${users[@]}
do
generate_participant ${user}
echo  "now generating the participant: "  ${user}
done

# exit 0





# agent: signature caller
# verb:  aggregate
# obj:   verifiers (sum of all participant verifiers)
# verb:  create
# obj:   uid (arbitrary string, may be the hash of a document)
# obj:   multisignature (session to sign uid)

# join the verifiers of signed credentials

# jq -s 'reduce .[] as $item ({}; . * $item)' . verifier_Alice.json verifier_Bob.json verifier_Carl.json verifier_Derek.json verifier_Eva.json verifier_Frank.json verifier_Gina.json verifier_Jessie.json verifier_Karl.json verifier_Ingrid.json | tee verifiers.json

jq -s 'reduce .[] as $item ({}; . * $item)' . /dev/shm/files/verifier_* | tee /dev/shm/files/verifiers.json


echo "{\"today\": \"`date +'%s'`\"}" > /dev/shm/files/uid.json

# anyone can start a session
#############################
### SCRIPT THAT PRODUCES THE MULTISIGNATURE
#############################

multisignature="Scenario multidarkroom \n"

for user in ${users[@]}
do

multisignature+="Given I have a 'verifier' from '${user}' \n"  
done

multisignature+="Given I have a 'string' named 'today' \nWhen I create the multisignature with uid 'today' \nThen print the 'multisignature'\n"

echo -e "\n \n \n THis is the multisig script: \n \n \n" $multisignature 



#############################


# SIGNING SESSION
echo -e $multisignature | zexe /dev/shm/files/session_start.zen -k /dev/shm/files/uid.json -a /dev/shm/files/verifiers.json > /dev/shm/files/multisignature.json
#
# TODO: credentials may be included in the multisignature



# participant is told of the multisignature and offered to sign
# participant joins the credential (=issuer pubkey) and the multisignature
json_join /dev/shm/files/credential.json /dev/shm/files/multisignature.json | jq . > /dev/shm/files/credential_to_sign.json

cp multisignature.json multisignature_input.json

# PARTICIPANT SIGNS (function)
function participant_sign() {
	local name=$1
	cat <<EOF | zexe /dev/shm/files/sign_session.zen -a /dev/shm/files/credential_to_sign.json -k /dev/shm/files/verified_credential_$name.json  | jq . | tee /dev/shm/files/signature_$name.json
Scenario multidarkroom
Given I am '$name'
and I have my 'verified credential'
and I have my 'keypair'
# TODO maybe include all together with VC
# have my 'credential key'
# have my 'signing key'
and I have a 'multisignature'
and I have a 'credential' from 'The Authority'
When I create the signature
Then print the 'signature'
EOF
}

for user in ${users[@]}
do
participant_sign ${user}
echo  "now generating the participant: "  ${user}
done




# TODO: check traceability option signature -> multisignature

function collect_sign() {
	local name=$1
	local tmp_msig=`mktemp`
	local tmp_sig=`mktemp`
	cp -v /dev/shm/files/multisignature.json $tmp_msig
	json_join /dev/shm/files/credential.json /dev/shm/files/signature_$name.json > $tmp_sig
	cat << EOF | zexe /dev/shm/files/collect_sign.zen -a $tmp_msig -k $tmp_sig  | jq . | tee /dev/shm/files/multisignature.json
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


for user in ${users[@]}
do
collect_sign ${user}
echo  "now collecting the signature: "  ${user}
done


# VERIFY SIGNATURE
cat << EOF | zexe /dev/shm/files/verify_sign.zen -a /dev/shm/files/multisignature.json | jq .
Scenario multidarkroom
Given I have a 'multisignature'
When I verify the multisignature is valid
Then print 'SUCCESS'
and print the 'multisignature'
EOF

echo -e "${reset} "
echo -e "${red}### \n \nChange the value of 'Participants' in the beginning of the script, to change the amount of signees, currently it is: ${green} $Participants \n" 
echo -e "${red}### \n ${reset} "