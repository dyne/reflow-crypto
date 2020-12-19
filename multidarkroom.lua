-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2020 Dyne.org foundation
-- Written by Denis Roio
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- δ = r.O
-- γ = δ.G2
-- σ = δ * ( H(m)*G1 )
-- assume: ε(δ*G2, H(m)) == ε(G2, δ*H(m))
-- check:  ε(γ, H(m))    == ε(G2, σ)


print''
print '= TEST MULTI-DARK-ROOM CRYPTO SIGNATURE'
print''

msg = str("This is the authenticated message")

---------
-- SETUP
---------

G1 = ECP.generator()
G2 = ECP2.generator()

-- credentials
ZK = require_once('crypto_abc')
issuer = ZK.issuer_keygen()

-- keygen: δ = r.O ; γ = δ.G2
sk1 = INT.random() -- signing key
ck1 = INT.random() -- credential key
PK1 = G2 * sk1     -- signature verifier

sk2 = INT.random()
ck2 = INT.random()
PK2 = G2 * sk2

-- issuer sign ZK credentials
Lambda1 = ZK.prepare_blind_sign(ck1*G1, ck1) -- credential request:       p -> i
SigmaTilde1 = ZK.blind_sign(issuer.sign, Lambda1)    -- issuer signs credential:  i -> p
Sigma1 = ZK.aggregate_creds(ck1, {SigmaTilde1})  -- credential sigma          p -> store

Lambda2 = ZK.prepare_blind_sign(ck2*G1, ck2)
SigmaTilde2 = ZK.blind_sign(issuer.sign, Lambda2)
Sigma2 = ZK.aggregate_creds(ck2, {SigmaTilde2})

-- sign: σ = δ * ( H(msg)*G1 )

UID = ECP.hashtopoint(msg) -- the message's hash is the unique identifier

--------------
-- SETUP done
--------------

print "--------------------------"
print "first base signing session"
r = INT.random()
R = UID * r      -- session

-- add public keys to public session key
PM = (G2 * r) + PK1 + PK2

-- Session opener broadcasts:
-- 1. R   - base G1 point for signature session
-- 2. PM  - base G2 point for public multi-signature key
-- 3. msg - the message to be signed

-- proofs of valid signature
-- uses public session key as UID
Proof1,z1 = ZK.prove_cred_uid(issuer.verify, Sigma1, ck1, UID)
Proof2,z2 = ZK.prove_cred_uid(issuer.verify, Sigma2, ck2, UID)
-- each signer signs
S1 = UID * sk1
S2 = UID * sk2

-- generate the signature
-- each signer will communicate: UID * sk
SM = R + S1 + S2


-- print signature contents to screen
I.print({pub = PM, -- session public keys
		 sign = SM,
		 uid = UID,
		 proofhash1 = sha256( ZEN.serialize( Proof1 ) ),
		 proofhash2 = sha256( ZEN.serialize( Proof2 ) ),
		 zeta1 = z1,
		 zeta2 = z2,
		 issuer = issuer.verify
})

-- verify: ε(γ,H(msg)) == ε(G2,σ)
assert( ZK.verify_cred_uid(issuer.verify, Proof1, z1, UID),
		"first proof verification fails")
assert( ZK.verify_cred_uid(issuer.verify, Proof2, z2, UID),
		"second proof verification fails")
assert( ECP2.miller(PM, UID)
		   == ECP2.miller(G2, SM),
        "Signature doesn't validates")
