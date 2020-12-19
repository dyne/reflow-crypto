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

-- setup
G1 = ECP.generator()
G2 = ECP2.generator()

-- credentials
ZK = require_once('crypto_abc')
issuer = ZK.issuer_keygen()

-- keygen: δ = r.O ; γ = δ.G2
sk1 = INT.random()
ck1 = INT.random()
pk1 = G2 * sk1

sk2 = INT.random()
ck2 = INT.random()
pk2 = G2 * sk2

-- issuer sign ZK credentials
l1 = ZK.prepare_blind_sign(ck1*G1, ck1)
st1 = ZK.blind_sign(issuer.sign, l1)
cred1 = ZK.aggregate_creds(ck1, {st1})

l2 = ZK.prepare_blind_sign(ck2*G1, ck2)
st2 = ZK.blind_sign(issuer.sign, l2)
cred2 = ZK.aggregate_creds(ck2, {st2})

-- sign: σ = δ * ( H(msg)*G1 )

hm = ECP.hashtopoint(msg) -- message hash

print "--------------------------"
print "first base signing session"
r = INT.random()
sm = hm * r

-- add public keys to session
pm = G2 * r
pm = pm + pk1 + pk2

-- proofs of valid signature
-- uses public session key as UID
p1,z1 = ZK.prove_cred_uid(issuer.verify, cred1, ck1, hm)
p2,z2 = ZK.prove_cred_uid(issuer.verify, cred2, ck2, hm)

-- add signatures
sm = sm + ( hm * sk1 )
sm = sm + ( hm * sk2 ) -- sum of G1

I.print({pub = pm, -- session public keys
		 sign = sm,
		 uid = hm,
		 proofhash1 = sha256( ZEN.serialize( p1 ) ),
		 proofhash2 = sha256( ZEN.serialize( p2 ) ),
		 zeta1 = z1,
		 zeta2 = z2,
		 issuer = issuer.verify
})

-- verify: ε(γ,H(msg)) == ε(G2,σ)
assert( ZK.verify_cred_uid(issuer.verify, p1, z1, hm),
		"first proof verification fails")
assert( ZK.verify_cred_uid(issuer.verify, p2, z2, hm),
		"second proof verification fails")
assert( ECP2.miller(pm, hm)
		   == ECP2.miller(G2, sm),
        "Signature doesn't validates")


print "---------------------------"
print "second base signing session"

r = INT.random()
sm = hm * r

-- add public keys to session
pm = G2 * r
pm = pm + pk1 + pk2

-- proofs of valid signature
-- uses public session key as UID
p1,z1 = ZK.prove_cred_uid(issuer.verify, cred1, ck1, hm)
p2,z2 = ZK.prove_cred_uid(issuer.verify, cred2, ck2, hm)

-- add signatures
sm = sm + ( hm * sk1 )
sm = sm + ( hm * sk2 ) -- sum of G1

I.print({pub = pm, -- session public keys
		 sign = sm,
		 uid = hm,
		 proofhash1 = sha256( ZEN.serialize( p1 ) ),
		 proofhash2 = sha256( ZEN.serialize( p2 ) ),
		 zeta1 = z1,
		 zeta2 = z2,
		 issuer = issuer.verify
})

-- verify: ε(γ,H(msg)) == ε(G2,σ)
assert( ZK.verify_cred_uid(issuer.verify, p1, z1, hm),
		"first proof verification fails")
assert( ZK.verify_cred_uid(issuer.verify, p2, z2, hm),
		"second proof verification fails")
assert( ECP2.miller(pm, hm)
		   == ECP2.miller(G2, sm),
        "Signature doesn't validates")
