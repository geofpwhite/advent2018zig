package main

import (
	"bufio"
	"flag"
	"os"
	"runtime/pprof"
	"strconv"
	"strings"

	"fortio.org/cli"
	"fortio.org/log"
	"fortio.org/terminal/ansipixels"
)

func main() {
	_ = Main()
}

func Main() int {
	points := parse()
	truecolorDefault := ansipixels.DetectColorMode().TrueColor
	fTrueColor := flag.Bool("truecolor", truecolorDefault,
		"Use true color (24-bit RGB) instead of 8-bit ANSI colors (default is true if COLORTERM is set)")
	fCpuprofile := flag.String("profile-cpu", "", "write cpu profile to `file`")
	fpsFlag := flag.Float64("fps", 60, "set fps for display refresh")
	cli.Main()
	if *fCpuprofile != "" {
		f, err := os.Create(*fCpuprofile)
		if err != nil {
			return log.FErrf("can't open file for cpu profile: %v", err)
		}
		err = pprof.StartCPUProfile(f)
		if err != nil {
			return log.FErrf("can't start cpu profile: %v", err)
		}
		log.Infof("Writing cpu profile to %s", *fCpuprofile)
		defer pprof.StopCPUProfile()
	}
	ap := ansipixels.NewAnsiPixels(*fpsFlag)
	ap.TrueColor = *fTrueColor
	if err := ap.Open(); err != nil {
		return 1 // error already logged
	}
	defer func() {
		ap.ShowCursor()
		ap.MouseClickOff()
		ap.Restore()
		ap.ClearScreen()
	}()
	ap.MouseClickOn()

	ap.SyncBackgroundColor()
	ap.OnResize = func() error {
		userInput, quit := Tick(ap)
		if quit {
			return nil
		}
		if userInput {
			Update(ap)
		}
		return nil
	}
	ap.AutoSync = false
	_ = ap.OnResize() // initial draw.
	err := ap.FPSTicks(func() bool {
		userInput, quit := Tick()
		if quit {
			return false
		}
		if userInput {
			Update()
		}
		return true
	})
}

func parse() []point {
	f, err := os.Open("d10/input.txt")
	if err != nil {
		panic(err)
	}
	scanner := bufio.NewScanner(f)
	points := make([]point, 0)
	for scanner.Scan() {
		line := scanner.Text()
		px, err := strconv.Atoi(strings.Trim(line[11:16], " "))
		if err != nil {
			panic(err)
		}
		py, err := strconv.Atoi(strings.Trim(line[17:24], " "))
		if err != nil {
			panic(err)
		}
		pos := coord{px, py}
		vx, err := strconv.Atoi(strings.Trim(line[36:38], " "))
		if err != nil {
			panic(err)
		}
		vy, err := strconv.Atoi(strings.Trim(line[39:42], " "))
		if err != nil {
			panic(err)
		}
		vel := coord{vx, vy}
		points = append(points, point{pos, vel})
	}
	return points
}

type point struct {
	c, vc coord
}

type coord struct {
	x, y int
}
