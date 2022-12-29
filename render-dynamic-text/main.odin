package main

import "core:fmt"
import SDL "vendor:sdl2"
import SDL_TTF "vendor:sdl2/ttf"
import "core:strings"
import "core:unicode/utf8"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE

// Fonts
COLOR_WHITE : SDL.Color : {255,255,255,255}

Text :: struct
{
	tex: ^SDL.Texture,
	dest: SDL.Rect,
}

Game :: struct
{
	window: ^SDL.Window,
	window_w: i32,
	window_h: i32,
	renderer: ^SDL.Renderer,

	font: ^SDL_TTF.Font,
	font_size: i32,

	chars: map[rune]Text,

	text_input: string,

}

game := Game{
	window_w = 1024,
	window_h = 960,

	font_size = 80,
	chars = make(map[rune]Text),
}

main :: proc()
{
	// all inits
	init_sdl()
	// all quits and destroys
	defer clean_sdl()

	create_chars()

	// poll for queued events each game loop
	event : SDL.Event

	// NOTE:: This doesn't seem to be necessary for our example --
	// the TEXTINPUT event fires without it, as well
	SDL.StartTextInput()
	// NOTE:: Unsure what this does
	// SDL.SetTextInputRect()

	game_loop : for
	{

		if SDL.PollEvent(&event)
		{
			if end_game(&event) do break game_loop

			handle_events(&event)
		}


		// START update and render

		char_spacing : i32 = 2
		prev_chars_w : i32 = 0

		starting_x : i32 = 100
		starting_y : i32 = 100

		// iterate characters in the string
		for c in game.text_input
		{
			// grab the texture for the single character
			char : Text = game.chars[c]

			// render this character after the previous one
			char.dest.x = starting_x + prev_chars_w
			char.dest.y = starting_y

			SDL.RenderCopy(game.renderer, char.tex, nil, &char.dest)

			prev_chars_w += char.dest.w + char_spacing
		}

		// END update and render

		draw_scene()
	}

	SDL.StopTextInput()

}

handle_events :: proc(event: ^SDL.Event)
{
	if event.type == SDL.EventType.WINDOWEVENT
	{
        if (event.window.windowID == SDL.GetWindowID(game.window))
        {
        	if event.window.event == SDL.WindowEventID.RESIZED
        	{
        		game.window_w = event.window.data1
        		game.window_h = event.window.data2
        	}
        }
	}

	scancode := event.key.keysym.scancode

	if event.type == SDL.EventType.TEXTINPUT
	{
		input := cstring(raw_data(event.text.text[:]))
		game.text_input = strings.concatenate({game.text_input, string(input)})
	}

	if scancode == .BACKSPACE
	{
		if len(game.text_input) > 0
		{
			input := game.text_input[:len(game.text_input) -1]
			game.text_input = input
		}
	}

}


draw_scene :: proc()
{
	// actual flipping / presentation of the copy
	// read comments here :: https://wiki.libsdl.org/SDL_RenderCopy
	SDL.RenderPresent(game.renderer)

	// make sure our background is black
	// RenderClear colors the entire screen whatever color is set here
	SDL.SetRenderDrawColor(game.renderer, 0, 0, 0, 100)

	// clear the old scene from the renderer
	// clear after presentation so we remain free to call RenderCopy() throughout our update code / wherever it makes the most sense
	SDL.RenderClear(game.renderer)

}


init_sdl :: proc()
{
	// initialize SDL
	sdl_init_error := SDL.Init(SDL.INIT_VIDEO)
	assert(sdl_init_error != -1, SDL.GetErrorString())

	// Window
	game.window = SDL.CreateWindow(
		"SDL2 Examples",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		game.window_w,
		game.window_h,
		WINDOW_FLAGS,
	)
	assert(game.window != nil, SDL.GetErrorString())

	// Renderer
	// This is used throughout the program to render everything.
	// You only require ONE renderer for the entire program.
	game.renderer = SDL.CreateRenderer(game.window, -1, RENDER_FLAGS)
	assert(game.renderer != nil, SDL.GetErrorString())

	ttf_init_error := SDL_TTF.Init()
	assert(ttf_init_error != -1, SDL.GetErrorString())
	game.font = SDL_TTF.OpenFont("Terminal.ttf", game.font_size)
	assert(game.font != nil, SDL.GetErrorString())
}

clean_sdl :: proc()
{
	SDL_TTF.Quit()
	SDL.Quit()
	SDL.DestroyWindow(game.window)
	SDL.DestroyRenderer(game.renderer)
}

// create a map of chars that be used in make_word
create_chars :: proc()
{

	chars := " ?!@#$%^&*();:',.@_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

	for c in chars[:]
	{
		str := utf8.runes_to_string([]rune{c})
		defer delete(str)

		game.chars[c] = create_text(cstring(raw_data(str)))
	}

}

// create textures for the given str
// optional scale param allows us to easily size the texture generated
// relative to the current game.font_size
create_text :: proc(str: cstring, scale: i32 = 1) -> Text
{
	// create surface
	surface := SDL_TTF.RenderText_Solid(game.font, str, COLOR_WHITE)
	defer SDL.FreeSurface(surface)

	// create texture to render
	texture := SDL.CreateTextureFromSurface(game.renderer, surface)

	// destination SDL.Rect
	dest_rect := SDL.Rect{}
	SDL_TTF.SizeText(game.font, str, &dest_rect.w, &dest_rect.h)

	// scale the size of the text
	dest_rect.w *= scale
	dest_rect.h *= scale

	return Text{tex = texture, dest = dest_rect}
}


// check for a quit event
// this is an example of using a Named Result - "exit".
// with named results we can just put "return" at the end of the function
// and the value of our named return-variable will be returned.
end_game :: proc(event: ^SDL.Event) -> (exit: bool)
{
	exit = false

	// Quit event is clicking on the X on the window
	if event.type == SDL.EventType.QUIT || event.key.keysym.scancode == .ESCAPE
	{
		exit = true
	}

	return
}

