local require = require
local jwt = require("resty.jwt")
local cjson = require("cjson.safe")
local http = require("resty.http")
local sha256 = (require 'resty.sha256'):new()
local b64url = require("ngx.base64").encode_base64url
local httpc = require("resty.http").new()

local function verify_dpop_jose_header(header)
    if not header.typ then
        return false, "Missing DPoP proof JOSE header claim - typ"
    end

    if header.typ ~= "dpop+jwt" then
        return false, "Invalid DPoP proof JOSE header claim - typ"
    end

    if not header.alg then
        return false, "Missing DPoP proof JOSE header claim - alg"
    end

    if header.alg == "none" then
        return false, "Invalid DPoP proof JOSE header claim - alg"
    end

    if not header.jwk then
        return false, "Missing DPoP proof JOSE header claim - jwk"
    end

    return true, nil
end

-- RFC 9449 section 4.3: compare htu ignoring query and fragment, after the
-- syntax and scheme based normalization of RFC 3986 sections 6.2.2 and 6.2.3.
local function normalize_uri(uri)
    local without_query = string.match(uri, "^[^?#]*")
    local scheme, authority, path = string.match(without_query, "^(%a[%w+.-]*)://([^/]*)(.*)$")
    if not scheme then
        return without_query
    end

    scheme = string.lower(scheme)
    authority = string.lower(authority)
    if scheme == "https" then
        authority = string.gsub(authority, ":443$", "")
    end

    return scheme .. "://" .. authority .. path
end

local function verify_dpop_payload(payload, uri, method)

    if not payload.jti then
        return false, "Missing DPoP proof claims - jti"
    end

    if not payload.htu then
        return false, "Missing DPoP proof claims - htu"
    end

    if normalize_uri(payload.htu) ~= normalize_uri(uri) then
        return false, "Invalid DPoP proof claims - htu"
    end

    if not payload.htm  then
        return false, "Missing DPoP proof claims - htm"
    end

    if payload.htm ~= method then
        return false, "Invalid DPoP proof claims - htm"
    end

    if not payload.iat then
        return false, "Missing DPoP proof claim - iat"
    end

    if os.time() - payload.iat > 60 then
        return false, "DPoP proof is too old - iat"
    end

    if payload.iat - os.time() > 60 then
        return false, "DPoP proof is in future - iat"
    end

    if not payload.ath then
        return false, "Missing DPoP proof JOSE header claim - ath"
    end

    --local size = 0
    --for _ in pairs(payload) do size = size + 1 end
    --if size ~= 5 then
    --    return false, "Unnessesary DPoP proof JOSE header claim"
    --end

    return true, nil
end

local function verify_request_header(auth_header, dpop_header)
    if not auth_header then
        return false, "Missing Authorization header"
    end

    if type(auth_header) ~= "string" then
        return false, "Invalid DPoP Proof"
    end

    if not dpop_header then
        return false, "Missing DPoP Proof"
    end

    if type(dpop_header) ~= "string" then
        return false, "Invalid DPoP Proof"
    end

    local encoded_header, encoded_payload, encoded_signature = string.match(dpop_header, "(.-)%.(.-)%.(.+)")
    ngx.log(ngx.INFO, "encoded_header: ", encoded_header)
    ngx.log(ngx.INFO, "encoded_payload: ", encoded_payload)
    ngx.log(ngx.INFO, "encoded_signature: ", encoded_signature)

    if encoded_signature == nil then
        return false, "Missing DPoP Proof signature"
    end

    return true, nil
end

local function get_s256_value(token)
    sha256:update(token)
    local token_s256 = b64url(sha256:final())
    sha256:reset()
    return token_s256
end

local function verify_dpop_proof_bound_with_access_token(payload, access_token)
    local access_token_s256 = get_s256_value(access_token)
    ngx.log(ngx.INFO, "Encoded Access Token SHA-256 value: ", access_token_s256)

    if payload.ath ~= access_token_s256 then
        return false, "Invalid DPoP proof claims - ath not match access token S256 hash value"
    end

    return true, nil
end

local function verify_public_key_bound_with_access_token(header, access_token)

    local public_key_jwk = nil
    if header.jwk.kty == "EC" then
        public_key_jwk = "{".."\"crv\":\""..header.jwk.crv.."\",\"kty\":\""..header.jwk.kty.."\",\"x\":\""..header.jwk.x.."\",\"y\":\""..header.jwk.y.."\"}"
    elseif header.jwk.kty == "RSA" then
        public_key_jwk = "{".."\"e\":\""..header.jwk.e.."\",\"kty\":\""..header.jwk.kty.."\",\"n\":\""..header.jwk.n.."\"}"
    else
        return false, "Invalid JWK key type claim - kty"
    end

    local public_key_jwk_s256 = get_s256_value(public_key_jwk)
    ngx.log(ngx.INFO, "DPoP Public Key SHA-256 value: ", public_key_jwk_s256)

    local access_token_jwt = jwt:load_jwt(access_token)
    ngx.log(ngx.INFO, "Access Token cnf - jkt claim: ", access_token_jwt.payload.cnf.jkt)

    if access_token_jwt.payload.cnf.jkt ~= public_key_jwk_s256 then
        return false, "Invalid DPoP proof public key"
    end

    return true, nil
end

local function verify_dpop_signature(dpop_header)
    local res, err = httpc:request_uri("http://dpop_proof_signature_verify_server:3000", {
        method = "GET",
        headers = {
            ["DPoP"] = dpop_header,
        },
    })
    local status = res.status
    local length = res.headers["Content-Length"]
    local body   = res.body
    ngx.log(ngx.INFO, "DPoP Proof Signature Verify Server - status: ", status)
    ngx.log(ngx.INFO, "DPoP Proof Signature Verify Server - length: ", length)
    ngx.log(ngx.INFO, "DPoP Proof Signature Verify Server - body: ", body)
    if status == 400 then
        return false, "Invalid DPoP proof signature verification failed"
    end

    return true, nil
end

-- A DPoP proof says nothing about revocation, so ask the authorization server
-- whether the access token is still active.
local function verify_access_token_active(access_token)
    local credentials = ngx.encode_base64("resource-server:" .. os.getenv("CLIENT_SECRET"))
    local res, err = http.new():request_uri(os.getenv("INTROSPECTION_ENDPOINT_URL"), {
        method = "POST",
        body = ngx.encode_args({ token = access_token, token_type_hint = "access_token" }),
        headers = {
            ["Authorization"] = "Basic " .. credentials,
            ["Content-Type"] = "application/x-www-form-urlencoded",
        },
    })
    if not res then
        return false, "Token introspection failed: " .. err
    end
    if res.status ~= 200 then
        return false, "Token introspection failed - status: " .. res.status
    end

    local introspection = cjson.decode(res.body)
    if not introspection or introspection.active ~= true then
        return false, "Access token is not active"
    end

    return true, nil
end

-- Function to validate DPoP
local function verify_dpop()
    local headers = ngx.req.get_headers()
    local auth_header = headers["Authorization"]
    local dpop_header = headers["DPoP"]

    local valid, err = verify_request_header(auth_header, dpop_header)
    if not valid then
        return false, err
    end

    ngx.log(ngx.INFO, "Header - Authorization: ", auth_header)
    ngx.log(ngx.INFO, "Header - DPoP: ", dpop_header)
    ngx.log(ngx.INFO, "Scheme: ", ngx.var.scheme)
    ngx.log(ngx.INFO, "Host: ", headers["Host"])
    ngx.log(ngx.INFO, "Path: ", ngx.var.uri) -- normalized

    local access_token = string.match(auth_header, "^[Dd][Pp][oO][Pp]%s+(%S+)$")
    if not access_token then
        return false, "Invalid Authorization header format"
    end
    ngx.log(ngx.INFO, "Access Token: ", access_token)

    local dpop_proof = jwt:load_jwt(dpop_header)

    valid, err = verify_dpop_jose_header(dpop_proof.header)
    if not valid then
        return false, err
    end

    local payload = dpop_proof.payload
    local uri = ngx.var.scheme.."://"..headers["Host"]..ngx.var.uri
    local method = ngx.req.get_method()

    valid, err = verify_dpop_payload(payload, uri, method)
    if not valid then
        return false, err
    end

    ngx.log(ngx.INFO, "HTTP Method: ", method)
    ngx.log(ngx.INFO, "HTTP Request URI: ", uri)
    ngx.log(ngx.INFO, "DPoP Proof htu claim: ", payload.htu)
    ngx.log(ngx.INFO, "DPoP Proof htm claim: ", payload.htm)
    ngx.log(ngx.INFO, "DPoP Proof iat claim: ", payload.iat)
    ngx.log(ngx.INFO, "DPoP Proof jti claim: ", payload.jti)
    ngx.log(ngx.INFO, "DPoP Proof ath claim: ", payload.ath)

    valid, err = verify_dpop_proof_bound_with_access_token(payload, access_token)
    if not valid then
        return false, err
    end

    valid, err = verify_public_key_bound_with_access_token(dpop_proof.header, access_token)
    if not valid then
        return false, err
    end

    valid, err = verify_dpop_signature(dpop_header)
    if not valid then
        return false, err
    end

    valid, err = verify_access_token_active(access_token)
    if not valid then
        return false, err
    end

    return true
end

-- Main execution
local valid, err = verify_dpop()
if not valid then
    ngx.log(ngx.ERR, "DPoP validation failed: ", err)
    ngx.header['Content-Type'] = 'application/json; charset=UTF-8'
    ngx.header['Content-Length'] = '0'
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- FAPI-R-6.2.1-11 Handling x-fapi-interaction-id
-- https://openid.net/specs/openid-financial-api-part-1-ID2.html#rfc.section.6.2.1
if ngx.var.http_x_fapi_interaction_id == nil then
    local uuid = require("resty.jit-uuid")
    ngx.req.set_header("x-fapi-interaction-id", uuid())
end
ngx.header["x-fapi-interaction-id"] = ngx.var.http_x_fapi_interaction_id
