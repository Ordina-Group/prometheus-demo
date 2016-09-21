package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
)

// This application just prints what is sent by the Alert Manager in the body
func main() {
	http.HandleFunc("/", handleRequest)
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	body, _ := ioutil.ReadAll(io.LimitReader(r.Body, 1048576))
	fmt.Println(string(body[:]))
}
