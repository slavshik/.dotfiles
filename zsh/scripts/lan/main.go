package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
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
	devices := loadDevices()

	type entry struct {
		ip   string
		mac  string
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
		mac := parseArpMAC(line)
		entries = append(entries, entry{ip: ip, mac: mac})
	}

	// Concurrent reverse DNS (only for entries without a device name)
	var mu sync.Mutex
	for i := range entries {
		if _, ok := devices[entries[i].mac]; ok {
			continue
		}
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

	isTTY := isTerminal()
	reset, dim, green, yellow := "", "", "", ""
	if isTTY {
		reset = "\033[0m"
		dim = "\033[2m"
		green = "\033[32m"
		yellow = "\033[33m"
	}

	for _, e := range entries {
		deviceName, known := devices[e.mac]
		if known {
			fmt.Printf("%s%s%s %s# %s✔ %s%s\n", green, e.ip, reset, dim, green, deviceName, reset)
		} else {
			name := e.host
			fmt.Printf("%s%s%s %s# %s %s%s\n", yellow, e.ip, reset, dim, e.mac, name, reset)
		}
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

func isTerminal() bool {
	fi, err := os.Stdout.Stat()
	if err != nil {
		return false
	}
	return fi.Mode()&os.ModeCharDevice != 0
}

func parseArpMAC(line string) string {
	fields := strings.Fields(line)
	for i, f := range fields {
		if f == "at" && i+1 < len(fields) {
			mac := strings.ToLower(fields[i+1])
			// Normalize single-digit octets: 0:1a:2b → 00:1a:2b
			parts := strings.Split(mac, ":")
			for j, p := range parts {
				if len(p) == 1 {
					parts[j] = "0" + p
				}
			}
			return strings.Join(parts, ":")
		}
	}
	return ""
}

func loadDevices() map[string]string {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil
	}
	f, err := os.Open(filepath.Join(home, ".config", "lan", "devices.txt"))
	if err != nil {
		return nil
	}
	defer f.Close()

	devices := make(map[string]string)
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, " ", 2)
		if len(parts) == 2 {
			mac := strings.ToLower(strings.TrimSpace(parts[0]))
			name := strings.TrimSpace(parts[1])
			devices[mac] = name
		}
	}
	return devices
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
