package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"net/http"
	"sync"
	"time"
)

var (
	apiURL   = flag.String("api-url", "http://voting-app:8080/api", "The URL of the API to call")
	timeout  = flag.Int("timeout", 5000, "The timeout for each API call")
	vote     = flag.String("vote", "dog", "The thing to vote for")
	maxDelay = flag.Int("max-delay", 200, "The maximum delay between each vote")
)

func main() {

	flag.Parse()

	wg := sync.WaitGroup{}
	wg.Add(3)

	go func() {
		for {
			makeVote(*vote)
			sleep()
		}
	}()

	wg.Wait()

}

// Vote holds
type Vote struct {
	Name string `json:"name"`
}

// Sleep for a random amount of time
func sleep() {
	time.Sleep(time.Duration(rand.Float64()*500) * time.Millisecond)
}

// Calls the voting API
func makeVote(name string) {

	fmt.Println("Voting for " + name)

	vote := Vote{Name: name}
	body, err := json.Marshal(vote)
	if err != nil {
		return
	}

	req, err := http.NewRequest("POST", *apiURL+"/vote", bytes.NewBuffer(body))
	if err != nil {
		fmt.Println(err.Error())
		return
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{
		Timeout: time.Duration(*timeout) * time.Millisecond,
	}

	resp, err := client.Do(req)
	if err != nil {
		fmt.Println(err.Error())
		return
	}
	defer resp.Body.Close()
}
