package main

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"
)

// Delay before the callback is sent once the conformance suite has called the automated approval endpoint.
// In ping mode, the conformance suite calls the token endpoint just before calling the automated approval endpoint,
// and calls it again as soon as the ping notification arrives. Keycloak returns slow_down if the token endpoint
// is called again within the CIBA polling interval (5 seconds by default), so the callback must be delayed longer than that.
const approvedCallbackDelay = 6 * time.Second

// Delay before the callback is sent when no approval arrives (e.g. manual tests, or tests where
// the user deliberately does not authenticate). The result is then always SUCCEED.
const fallbackCallbackDelay = 30 * time.Second

type Accounts struct {
	Accounts []Account `json:"accounts"`
}

type Account struct {
	Name string `json:"name"`
}

type AuthDelegateRequest struct {
	BindingMessage  string `json:"binding_message"`
	LoginHint       string `json:"login_hint"`
	ConsentRequired bool   `json:"is_consent_required"`
	Scope           string `json:"scope"`
	AcrValues       string `json:"acr_values"`
}

type AuthenticationResultNotification struct {
	Status string `json:"status"`
}

type ClientNotification struct {
	AuthReqId string `json:"auth_req_id"`
}

// pendingAuthentication is an authentication delegation request from Keycloak that has not been answered yet.
type pendingAuthentication struct {
	loginHint   string
	bearerToken string
	once        sync.Once
	timer       *time.Timer
}

// The auth_req_id sent to the automated approval endpoint cannot be linked to the bearer token
// sent by Keycloak (both are encrypted). The test plans run in parallel, so each plan uses its own
// user and sends it as login_hint in its approval URL, and an approval is applied to the most recent
// pending request of that user. This works because the conformance suite runs the tests of a plan
// one at a time, and Keycloak calls this server before returning auth_req_id to the client.
// An approval without login_hint, such as from a manual test, is applied to the most recent pending request.
var (
	pendingMu sync.Mutex
	pending   []*pendingAuthentication
)

func removePending(p *pendingAuthentication) {
	pendingMu.Lock()
	defer pendingMu.Unlock()
	for i, e := range pending {
		if e == p {
			pending = append(pending[:i], pending[i+1:]...)
			return
		}
	}
}

func popLatestPending(loginHint string) *pendingAuthentication {
	pendingMu.Lock()
	defer pendingMu.Unlock()
	for i := len(pending) - 1; i >= 0; i-- {
		p := pending[i]
		if loginHint == "" || p.loginHint == loginHint {
			pending = append(pending[:i], pending[i+1:]...)
			return p
		}
	}
	return nil
}

// sendCallback sends the authentication result to Keycloak. It is sent at most once per request.
func (p *pendingAuthentication) sendCallback(isAllowed bool) {
	p.once.Do(func() {
		removePending(p)
		log.Printf("Callback : Outgoing request.")

		u := "https://as.keycloak-fapi.org/auth/realms/test/protocol/openid-connect/ext/ciba/auth/callback/"
		notification := new(AuthenticationResultNotification)

		if isAllowed {
			notification.Status = "SUCCEED"
		} else {
			notification.Status = "CANCELLED"
		}

		k, _ := json.Marshal(notification)
		req, _ := http.NewRequest("POST", u, bytes.NewBuffer(k))
		req.Header.Set("Authorization", p.bearerToken)
		req.Header.Set("Content-Type", "application/json")

		tr := &http.Transport{
			TLSClientConfig: &tls.Config{
				InsecureSkipVerify: true,
				ServerName:         "as.keycloak-fapi.org",
			},
		}
		client := &http.Client{
			Transport: tr,
		}
		res, err := client.Do(req)
		log.Printf("Callback : Incoming response.")
		if err != nil {
			log.Printf("Error :  " + err.Error())
			return
		}
		defer res.Body.Close()
		log.Printf("Success : " + res.Status)
	})
}

func delegatedAuthnHandler(w http.ResponseWriter, r *http.Request) {
	log.Printf("Incoming request from %s, %s.", r.Host, r.RemoteAddr)

	// receive json and Authorization header for bearer token for token authentication afterwards
	var authDelegateRequest AuthDelegateRequest
	json.NewDecoder(r.Body).Decode(&authDelegateRequest)
	log.Printf("    acr_values : %s", authDelegateRequest.AcrValues)
	log.Printf("    binding_message : %s", authDelegateRequest.BindingMessage)
	log.Printf("    is_consent_required : %t", authDelegateRequest.ConsentRequired)
	log.Printf("    login_hint : %s", authDelegateRequest.LoginHint)
	log.Printf("    scope : %s", authDelegateRequest.Scope)

	bearerToken := r.Header.Get("Authorization")
	log.Printf("Bearer Token on Authorization Header = %s", bearerToken)

	p := &pendingAuthentication{loginHint: authDelegateRequest.LoginHint, bearerToken: bearerToken}

	// if no automated approval arrives, authenticate the user anyway after a while
	p.timer = time.AfterFunc(fallbackCallbackDelay, func() {
		log.Printf("Callback : No automated approval received, authentication succeeds.")
		p.sendCallback(true)
	})

	pendingMu.Lock()
	pending = append(pending, p)
	pendingMu.Unlock()

	w.WriteHeader(http.StatusCreated)

	log.Printf("Outgoing response.")
}

func automatedCibaApprovalHandler(w http.ResponseWriter, r *http.Request) {
	log.Printf("CIBA Ping : Automated CIBA Approval for test automation : Incoming request from %s, %s.", r.Host, r.RemoteAddr)

	var auth_req_id string = r.URL.Query().Get("auth_req_id")
	var action string = r.URL.Query().Get("action")
	var login_hint string = r.URL.Query().Get("login_hint")
	log.Printf("    auth_req_id : %s", auth_req_id)
	log.Printf("    action : %s", action)
	log.Printf("    login_hint : %s", login_hint)

	// action=allow or action=deny
	isAllowed := action == "allow"

	if p := popLatestPending(login_hint); p != nil {
		p.timer.Stop()
		time.AfterFunc(approvedCallbackDelay, func() {
			p.sendCallback(isAllowed)
		})
	} else {
		log.Printf("    no pending authentication request found")
	}

	w.WriteHeader(http.StatusNoContent)

	log.Printf("CIBA Ping : Automated CIBA Approval for test automation : Client Notification : Outgoing response.")
}

func main() {
	log.Println("Auth Entity Server booted.")
	http.HandleFunc("/", delegatedAuthnHandler)
	http.HandleFunc("/automated/ciba/approval", automatedCibaApprovalHandler)
	http.ListenAndServe(":3001", nil)
}
