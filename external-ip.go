package main
import (
	"fmt"
	"net"
	"os"
	"time"
	externalip "github.com/glendc/go-external-ip"
)
func main() {
	args := os.Args[1:]
	if len(args) != 2 {
		fmt.Println("Usage: scan_command hostname port")
		os.Exit(1)
	}
	consensus := externalip.DefaultConsensus(nil, nil)
	ip, err := consensus.ExternalIP()
	if err == nil {
		fmt.Println("Our external IP: ", ip.String())
	}
	ips, err := net.LookupIP(args[0])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Could not get IPs: %v\n", err)
		os.Exit(1)
	}
	for _, ip := range ips {
		fmt.Printf("DNS: %v. IN A %s\n", args[0], ip.String())
	}
	raw_connect(args[0], args[1])
}
func raw_connect(host, port string) {
	timeout := time.Second
	conn, err := net.DialTimeout("tcp", net.JoinHostPort(host, port), timeout)
	if err != nil {
		fmt.Println("Connecting error:", err)
	}
	if conn != nil {
		defer conn.Close()
		fmt.Println("Connected to:", net.JoinHostPort(host, port))
	}
}
