package main

import SDL "vendor:sdl2"

// This program opens a window for 3 seconds, and then closes that window automatically.
main :: proc()
{
	// initialize SDL
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	assert(sdl_init_error == 0, SDL.GetErrorString())
	defer SDL.Quit()

	// Window
	window := SDL.CreateWindow(
		"SDL2 Examples",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		1024, // width
		960, // height
		SDL.WINDOW_RESIZABLE // window flags
	)
	assert(window != nil, SDL.GetErrorString())
	defer SDL.DestroyWindow(window)

	// Keep the window open for 3 seconds.
	SDL.Delay(3000)

	// When we reach the end of main(), the program will end, and the window will close
}