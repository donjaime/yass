// Command yass is the YASS CLI. See https://github.com/donjaime/yass.
package main

import (
	"os"
	"runtime/debug"

	"github.com/donjaime/yass/internal/yass"
)

// version is set by release builds: -ldflags "-X main.version=1.2.3".
var version = "dev"

func main() {
	if version == "dev" {
		if bi, ok := debug.ReadBuildInfo(); ok && bi.Main.Version != "" && bi.Main.Version != "(devel)" {
			version = bi.Main.Version // go install github.com/donjaime/yass/cmd/yass@v1.2.3
		}
	}
	os.Exit(yass.Main(os.Args[1:], version))
}
