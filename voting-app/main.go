package main

import (
	"flag"
	"log"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"

	"github.com/ant0ine/go-json-rest/rest"
	"github.com/prometheus/client_golang/prometheus"
)

var (
	// Set up metrics
	voteAmountTotalMetrics = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "votes_amount_total",
			Help: "The amount of votes cast, partitioned by name",
		}, []string{"name"})
)

var (
	addr = flag.String("listen-address", ":8080", "The address to listen on for HTTP requests.")
)

func init() {
	prometheus.Unregister(prometheus.NewGoCollector())
	prometheus.MustRegister(voteAmountTotalMetrics)
}

func main() {
	flag.Parse()
	http.Handle("/metrics", prometheus.Handler())
	http.Handle("/api/", http.StripPrefix("/api", apiHandler()))
	log.Fatal(http.ListenAndServe(*addr, nil))
}

func apiHandler() http.Handler {
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
	return api.MakeHandler()
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

// Increment is a function that increments the vote count by one.
func (vc *VoteCount) Increment() {
	atomic.AddUint64(&vc.Count, 1)
}

var (
	// Create the store where we keep our vote counts
	store     = map[string]*VoteCount{}
	storeLock = sync.RWMutex{}
)

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

	vote.Name = strings.ToLower(vote.Name)

	voteAmountTotalMetrics.WithLabelValues(vote.Name).Inc()

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
