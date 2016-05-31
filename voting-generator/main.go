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
	apiURL  = flag.String("api-url", "http://localhost:8080/api", "The URL of the API to call")
	timeout = flag.Int("timeout", 5000, "The timeout for each API call")
)

func main() {

	flag.Parse()

	wg := sync.WaitGroup{}
	wg.Add(3)

	go func() {
		for {
			vote("cat")
			sleep()
		}
	}()

	go func() {
		for {
			vote("dog")
			sleep()
		}
	}()

	wg.Wait()

}

// Vote
type Vote struct {
	Name string `json:"name"`
}

// Sleep for a random amount of time
func sleep() {
	time.Sleep(time.Duration(rand.Float64()*200) * time.Millisecond)
}

// Calls the voting API
func vote(name string) {

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
