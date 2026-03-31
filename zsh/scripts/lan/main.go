package main

import (
	"fmt"
	"net"
	"os/exec"
	"strings"
	"sync"
	"time"
)

func main() {
	ifaceName, ip := getDefaultInterface()
	if ip == nil {
		fmt.Println("No active network connection found.")
		return
	}
	_ = ifaceName

	mask := ip.DefaultMask()
	network := ip.Mask(mask)
	size := maskSize(mask)

	// Blast UDP packets to all IPs to populate ARP table
	var wg sync.WaitGroup
	for i := 1; i < size-1; i++ {
		target := incrementIP(network, i)
		wg.Add(1)
		go func(t string) {
			defer wg.Done()
			conn, err := net.DialTimeout("udp4", t+":9", 30*time.Millisecond)
			if err == nil {
				conn.Write([]byte{0})
				conn.Close()
			}
		}(target.String())
	}
	wg.Wait()
	time.Sleep(100 * time.Millisecond)

	// Parse ARP table without reverse DNS (-n flag)
	out, err := exec.Command("arp", "-an").Output()
	if err != nil {
		fmt.Println("Failed to read ARP table.")
		return
	}

	// Collect IPs first, then resolve names concurrently
	type entry struct {
		ip   string
		host string
	}
	var entries []entry
	for _, line := range strings.Split(string(out), "\n") {
		if strings.Contains(line, "incomplete") || line == "" {
			continue
		}
		ip := parseArpIP(line)
		if ip == "" {
			continue
		}
		if strings.HasPrefix(ip, "224.") || strings.HasPrefix(ip, "239.") || strings.HasSuffix(ip, ".255") {
			continue
		}
		entries = append(entries, entry{ip: ip})
	}

	// Concurrent reverse DNS
	var mu sync.Mutex
	for i := range entries {
		wg.Add(1)
		go func(e *entry) {
			defer wg.Done()
			names, err := net.LookupAddr(e.ip)
			mu.Lock()
			defer mu.Unlock()
			if err == nil && len(names) > 0 {
				e.host = strings.TrimSuffix(names[0], ".")
			} else {
				e.host = "-"
			}
		}(&entries[i])
	}
	wg.Wait()

	for _, e := range entries {
		fmt.Printf("%s # %s\n", e.ip, e.host)
	}
}

func getDefaultInterface() (string, net.IP) {
	out, err := exec.Command("route", "-n", "get", "default").Output()
	if err != nil {
		return "", nil
	}
	var ifaceName string
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "interface:") {
			ifaceName = strings.TrimSpace(strings.TrimPrefix(line, "interface:"))
			break
		}
	}
	if ifaceName == "" {
		return "", nil
	}
	iface, err := net.InterfaceByName(ifaceName)
	if err != nil {
		return ifaceName, nil
	}
	addrs, err := iface.Addrs()
	if err != nil {
		return ifaceName, nil
	}
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok {
			if ipv4 := ipnet.IP.To4(); ipv4 != nil {
				return ifaceName, ipv4
			}
		}
	}
	return ifaceName, nil
}

func parseArpIP(line string) string {
	start := strings.Index(line, "(")
	end := strings.Index(line, ")")
	if start < 0 || end < 0 {
		return ""
	}
	return line[start+1 : end]
}

func maskSize(mask net.IPMask) int {
	ones, bits := mask.Size()
	return 1 << uint(bits-ones)
}

func incrementIP(base net.IP, inc int) net.IP {
	ip := make(net.IP, len(base))
	copy(ip, base)
	for i := len(ip) - 1; i >= 0 && inc > 0; i-- {
		sum := int(ip[i]) + inc
		ip[i] = byte(sum % 256)
		inc = sum / 256
	}
	return ip
}
