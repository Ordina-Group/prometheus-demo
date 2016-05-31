package main

import (
	"log"
	"net/http"
	"sync"
	"sync/atomic"

	"github.com/ant0ine/go-json-rest/rest"
)

func main() {
	api := rest.NewApi()
	api.Use(rest.DefaultDevStack...)
	router, err := rest.MakeRouter(
		rest.Get("/results", GetResults),
		rest.Post("/vote", MakeVote),
	)
	if err != nil {
		log.Fatal(err)
	}
	api.SetApp(router)
	log.Fatal(http.ListenAndServe(":8080", api.MakeHandler()))
}

// Vote contains the name of the item to vote on
type Vote struct {
	Name string
}

// VoteCount keeps track of the amount of votes for a certain item
type VoteCount struct {
	Name  string `json:"-"`
	Count uint64 `json:"count"`
}

// Increment the vote count
func (vc *VoteCount) Increment() {
	atomic.AddUint64(&vc.Count, 1)
}

var store = map[string]*VoteCount{}

var storeLock = sync.RWMutex{}

// GetResults returns the results of all votes
func GetResults(w rest.ResponseWriter, r *rest.Request) {
	storeLock.RLock()

	w.WriteJson(store)

	storeLock.RUnlock()
}

// MakeVote makes a vote
func MakeVote(w rest.ResponseWriter, r *rest.Request) {
	vote := Vote{}
	err := r.DecodeJsonPayload(&vote)
	if err != nil {
		rest.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if vote.Name == "" {
		rest.Error(w, "name required", 400)
		return
	}

	storeLock.RLock()
	var voteCount *VoteCount
	if store[vote.Name] != nil {
		voteCount = store[vote.Name]
	}
	storeLock.RUnlock()

	if voteCount == nil {
		storeLock.Lock()
		voteCount = &VoteCount{Name: vote.Name, Count: 0}
		store[vote.Name] = voteCount
		storeLock.Unlock()
	}

	voteCount.Increment()

	w.WriteJson(voteCount)
	w.WriteHeader(http.StatusOK)
}
