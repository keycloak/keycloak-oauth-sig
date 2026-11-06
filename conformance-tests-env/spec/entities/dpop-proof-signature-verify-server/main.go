package main

import (
	"encoding/json"
	"net/http"
	"log"
	"math/rand"
	"time"
	"strings"
	"sync"
	"encoding/base64"
	"github.com/lestrrat-go/jwx/jwa"
	"github.com/lestrrat-go/jwx/jwk"
	"github.com/lestrrat-go/jwx/jws"
)

var dpopProofJtiMap = make(map[string]string)
var dpopProofJtiMutex sync.Mutex

func decodeJoseHeader(encodedDpopProof string) []byte {
    return decodeDPoPElement(encodedDpopProof, 0)
}

func decodePayload(encodedDpopProof string) []byte {
    return decodeDPoPElement(encodedDpopProof, 1)
}

func decodeDPoPElement(encodedDpopProof string, index int) []byte {
    encodedDpopProofArray := strings.Split(encodedDpopProof, ".")
	encededDPoPElement := encodedDpopProofArray[index]
	decodedDPoPElement, err := base64.RawURLEncoding.DecodeString(encededDPoPElement)
    if err != nil {
		log.Printf("error: ", err)
        return nil
    }
    return decodedDPoPElement
}

func unmarshallJson(b []byte) interface{} {
	var jsonObj interface{}
	_ = json.Unmarshal(b, &jsonObj)
	return jsonObj
}

func dpopHandler(w http.ResponseWriter, r *http.Request) {
	h := r.Header.Get("DPoP")
	log.Printf("DPoP : %s", h)
	djh := decodeJoseHeader(h)
	if djh == nil {
		http.Error(w, "DPoP JOSE Header decode error", http.StatusBadRequest)
		return
	}

	dpl := decodePayload(h)
	if dpl == nil {
		http.Error(w, "DPoP Payload decode error", http.StatusBadRequest)
		return
	}
	payloadJsonObj := unmarshallJson(dpl)
	dpopProofJti := payloadJsonObj.(map[string]interface{})["jti"].(string)
	dpopProofJtiMutex.Lock()
	_, included := dpopProofJtiMap[dpopProofJti]
	if !included {
		dpopProofJtiMap[dpopProofJti] = dpopProofJti
	}
	dpopProofJtiMutex.Unlock()
	if included { // replay suspect
		log.Printf("replay suspect jti = %s", dpopProofJti)
		http.Error(w, "replay suspect", http.StatusBadRequest)
		return
	}

	joseJsonObj := unmarshallJson(djh)
	jwkJson := joseJsonObj.(map[string]interface{})["jwk"].(interface{})
	log.Printf("  jwk - kty field = %s", jwkJson.(map[string]interface{})["kty"].(string))

	marshalledJwkJson, err := json.Marshal(jwkJson)
	log.Printf("  jwk - json marshalled = %s", marshalledJwkJson)

	pubKey, err := jwk.ParseKey(marshalledJwkJson)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	//alg := joseJsonObj.(map[string]interface{})["alg"].(string)
    algFromJwk := jwkJson.(map[string]interface{})["alg"].(string)
	log.Printf("  jwk - alg field = %s", algFromJwk)
	var dst jwa.SignatureAlgorithm
	dst.Accept(algFromJwk)
	payload, err := jws.Verify([]byte(h), dst, pubKey)
	if err != nil {
		log.Printf("  JWS verification failed = %s", err.Error())
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	} else {
		log.Printf("  payload = %s", payload)
	}

	log.Printf("DPoP Proof Signature Verify Server : successfully called.")
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
}

func main() {
	rand.Seed(time.Now().UnixNano())
	http.HandleFunc("/", dpopHandler)
	http.ListenAndServe(":3000", nil)
}
