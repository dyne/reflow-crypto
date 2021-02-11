-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2020-2021 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
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


ABC = require_once('crypto_abc')

G1 = ECP.generator()
G2 = ECP2.generator()

ZEN.add_schema({
	  verifier = function(obj)
		 -- not using ZEN.get because verifier is aggregable just like
		 -- public_key_f keys in ECDH. TODO: semantic distinction
		 -- using a function
		 return ECP2.new( CONF.input.encoding.fun(obj) )
	  end,
      keypair = function(obj)
		 local sk = ZEN.get(obj, 'signing_key', INT.new)
		 local ck = ZEN.get(obj, 'credential_key', INT.new)
		 return { signing_key = sk,
				  credential_key = ck }
	  end,
	  issuer_key = function(obj)
		 return { x = ZEN.get(obj, 'x', INT.new),
				  y = ZEN.get(obj, 'y', INT.new) }
	  end,
	  credential = function(obj)
		 return { alpha = ZEN.get(obj, 'alpha', ECP2.new),
				  beta  = ZEN.get(obj, 'beta', ECP2.new) }
	  end,
	  verified_credential = function(obj)
		 return { h = ZEN.get(obj, 'h', ECP.new),
				  s = ZEN.get(obj, 's', ECP.new) } end,
	  issuance_request = function(obj)
		 local req = { sign = { a = ZEN.get(obj.sign, 'a', ECP.new),
								b = ZEN.get(obj.sign, 'b', ECP.new) },
					   pi_s = { rr =      ZEN.get(obj.pi_s, 'rr', INT.new),
								rm =      ZEN.get(obj.pi_s, 'rm', INT.new),
								rk =      ZEN.get(obj.pi_s, 'rk', INT.new),
								commit =  ZEN.get(obj.pi_s, 'commit',  INT.new)  },
					   commit = ZEN.get(obj, 'commit', ECP.new),
					   public = ZEN.get(obj, 'public', ECP.new) }
		 ZEN.assert(ABC.verify_pi_s(req),
					"Error in credential request:".." proof is invalid (verify_pi_s)")
		 return req
	  end,
	  issuer_signature = function(obj)
		 return { h = ZEN.get(obj, 'h', ECP.new),
				  b_tilde = ZEN.get(obj, 'b_tilde', ECP.new),
				  a_tilde = ZEN.get(obj, 'a_tilde', ECP.new) }
	  end
})

function credential_proof_f(o)
	local obj = deepmap(CONF.input.encoding.fun, o)
	return { nu = ZEN.get(obj, 'nu', ECP.new),
			 kappa = ZEN.get(obj, 'kappa', ECP2.new),
			 pi_v = { c = ZEN.get(obj.pi_v, 'c', INT.new),
					  rm = ZEN.get(obj.pi_v, 'rm', INT.new),
					  rr = ZEN.get(obj.pi_v, 'rr', INT.new) },
			 sigma_prime = { h_prime = ZEN.get(obj.sigma_prime, 'h_prime', ECP.new),
							 s_prime = ZEN.get(obj.sigma_prime, 's_prime', ECP.new) } }
 end

function multisignature_fingerprints_f(o)
	if not o then return { } end
	local rawarr = deepmap(CONF.input.encoding.fun, o)
	local arr = { }
	for k,v in pairs(rawarr) do
		table.insert(arr, ECP.new(v))
	end
	return arr
end

ZEN.add_schema({
	multisignature = function(obj)
		return { UID = ZEN.get(obj,'UID',ECP.new),
				 SM =  ZEN.get(obj,'SM',ECP.new),
				 verifier = ZEN.get(obj,'verifier', ECP2.new),
				 fingerprints = multisignature_fingerprints_f(obj.fingerprints) }
	end,
	signature = function(obj)
		return { UID = ZEN.get(obj,'UID',ECP.new),
				 signature = ZEN.get(obj,'signature',ECP.new),
				 proof = credential_proof_f(obj.proof),
				 zeta = ZEN.get(obj,'zeta',ECP.new) }
	end
})

local function have(o) ZEN.assert(ACK[o], "Cannot find object: "..o) end
local function empty(o) ZEN.assert(not ACK[o], "Cannot overwrite existing object: "..o) end

When("create the keypair",function()
		-- keygen: δ = r.O ; γ = δ.G2
		empty 'keypair'
		local sk = INT.random() -- signing key
		ACK.keypair = { signing_key = sk,
						credential_key = INT.random() }
						-- verifier_key = G2 * sk }
end)

When("create the verifier", function()
		empty 'verifier'
		have 'keypair'
		ACK.verifier = G2 * ACK.keypair.signing_key
end)

When("create the issuance request", function() -- lambda
		have 'keypair'
		ACK.issuance_request =
		   ABC.prepare_blind_sign( ACK.keypair.credential_key )
end)

When("create the issuer key", function()
		ACK.issuer_key = { x = INT.random(),
						   y = INT.random()  }
end)

When("create the credential", function()
		empty 'credential'
		have 'issuer_key'
		ACK.credential = { alpha = G2 * ACK.issuer_key.x,
						   beta = G2 * ACK.issuer_key.y }
end)

When("create the issuer signature", function() -- sigmatilde
		empty 'issuer_signature'
		ZEN.assert(not ACK.issuer_signature,
				   "Cannot overwrite existing object:".." issuer signature")
		have 'issuance_request'
		have 'issuer_key'
		ACK.issuer_signature = ABC.blind_sign(ACK.issuer_key, ACK.issuance_request)
end)

When("create the verified credential", function()
		empty 'verified_credential'
		have 'keypair'
		ACK.verified_credential =
		   ABC.aggregate_creds(ACK.keypair.credential_key, { ACK.issuer_signature })
end)

When("create the multisignature with UID ''",function(uid)
		empty 'multisignature'
		have 'verifier'
		have(uid)
		-- TODO: more checks
		-- init random and uid
		local r = INT.random()
		local UID = ECP.hashtopoint(uid)
		-- session public key
		local PM = G2 * r
		for k,v in pairs(ACK.verifier) do
		   PM = PM + v
		end
		ACK.multisignature = { UID = UID,
							   SM = UID * r,
							   verifier = PM }
end)

When("create the signature",function()
		empty 'signature'
		have 'keypair'
		have 'multisignature'
		-- aggregate all credentials
		local pubcred = false
		for k,v in pairs(ACK.credential) do
		   if not pubcred
		   then pubcred = v
		   else pubcred = { pubcred.alpha + v.alpha,
							pubcred.beta  + v.beta   }
		   end
		end
		local p,z = ABC.prove_cred_uid(pubcred, ACK.verified_credential,
									   ACK.keypair.credential_key, ACK.multisignature.UID)
		ACK.signature = { UID = ACK.multisignature.UID,
					  	  signature = ACK.multisignature.UID * ACK.keypair.signing_key,
						  proof = p,
						  zeta = z   }
end)

When("prepare credentials for verification",function()
	have 'credential'
	local res = false
	for k,v in pairs(ACK.credential) do
		if not res then res = { alpha = v.alpha, beta = v.beta }
		else
			res.alpha = res.alpha + v.alpha
			res.beta  = res.beta  + v.beta
		end
	end
	ACK.credential = res
end)

When("verify the signature credential",function()
	have 'signature'
	have 'credential'
	have 'multisignature'
	ZEN.assert( ABC.verify_cred_uid(ACK.credential, ACK.signature.proof,
									 ACK.signature.zeta, ACK.multisignature.UID),
				"Signature has an invalid credential to sign")
end)

When("check the signature fingerprint is new",function()
	have 'signature'
	have 'multisignature'
	if ACK.multisignature.fingerprints then
		for k,v in pairs(ACK.multisignature.fingerprints) do
			ZEN.assert(v ~= ACK.signature.zeta,
						"Signature fingerprint is not new")
		end
	end
end)

When("add the fingerprint to the multisignature",function()
	have 'signature'
	have 'multisignature'
	if not ACK.multisignature.fingerprints then
		ACK.multisignature.fingerprints = { ACK.signature.zeta }
	else
		table.insert(ACK.multisignature.fingerprints, ACK.signature.zeta)
	end
end)

When("add the signature to the multisignature",function()
	have 'multisignature'
	have 'signature'
	ACK.multisignature.SM = ACK.multisignature.SM + ACK.signature.signature
end)

When("verify the multisignature is valid",function()
 	have 'multisignature'
	ZEN.assert( ECP2.miller(ACK.multisignature.verifier, ACK.multisignature.UID)
				== ECP2.miller(G2,ACK.multisignature.SM), "Multisignature doesn't validates")
end)