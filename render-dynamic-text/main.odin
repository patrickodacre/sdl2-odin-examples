package main

import "core:fmt"
import SDL "vendor:sdl2"
import SDL_TTF "vendor:sdl2/ttf"
import "core:strings"
import "core:unicode/utf8"
import "core:unicode/utf8/utf8string"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE
WINDOW_WIDTH :: 1024
WINDOW_HEIGHT :: 960

// Fonts
COLOR_WHITE : SDL.Color : {255,255,255,255}

TextId :: enum
{
	Title,
	SubTitle,
}

Text :: struct
{
	tex: ^SDL.Texture,
	dest: SDL.Rect,
}

Game :: struct
{
	window: ^SDL.Window,
	renderer: ^SDL.Renderer,

	font: ^SDL_TTF.Font,
	font_size: i32,
	texts: [TextId]Text,

	chars: map[rune]^SDL.Texture,

	text_input: string,
	text_input_dest: SDL.Rect,

}

game := Game{
	font_size = 28,
	chars = make(map[rune]^SDL.Texture),
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

		// render in the midding of the window
		x : i32 = (WINDOW_WIDTH / 2) - i32(len(game.text_input) / 2)
		y : i32 = (WINDOW_HEIGHT / 2)
		// reuse the same text_input_dest rather than create a new SDL.Rect each frame
		make_word(game.text_input, x, y, &game.text_input_dest)

		// END update and render

		draw_scene()
	}

	SDL.StopTextInput()

}

handle_events :: proc(event: ^SDL.Event)
{

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
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
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
	chars := "',.@_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for c in chars[:]
	{
		str := utf8.runes_to_string([]rune{c})
		defer delete(str)

		surface := SDL_TTF.RenderText_Solid(game.font, cstring(raw_data(str)), COLOR_WHITE)
		defer SDL.FreeSurface(surface)

		game.chars[c] = SDL.CreateTextureFromSurface(game.renderer, surface)
	}

}

// render textures corresponding to each char in a string
make_word :: proc(text: string, x, y : i32, dest: ^SDL.Rect)
{

	char_spacing : i32 = 2
	prev_chars_w : i32 = 0

	for c in text
	{
		char_tex := game.chars[c]

		// render this char after the previous one
		dest.x = x + prev_chars_w
		dest.y = y
		// size dest SDL.Rect for the current char_tex
		SDL.QueryTexture(char_tex, nil, nil, &dest.w, &dest.h)

		SDL.RenderCopy(game.renderer, char_tex, nil, dest)

		prev_chars_w += dest.w + char_spacing
	}

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

