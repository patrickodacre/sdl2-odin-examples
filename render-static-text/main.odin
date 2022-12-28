package main

import "core:fmt"
import SDL "vendor:sdl2"
import SDL_TTF "vendor:sdl2/ttf"

RENDER_FLAGS :: SDL.RENDERER_ACCELERATED
WINDOW_FLAGS :: SDL.WINDOW_SHOWN | SDL.WINDOW_RESIZABLE

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
	window_w: i32,
	window_h: i32,
	renderer: ^SDL.Renderer,

	font: ^SDL_TTF.Font,
	font_size: i32,
	texts: [TextId]Text,
}

game := Game{
	window_w = 1024,
	window_h = 960,

	font_size = 28,
}

main :: proc()
{
	// all inits
	init_sdl()
	// all quits and destroys
	defer clean_sdl()

	game.texts[TextId.Title] = create_text("Testing", 3)
	game.texts[TextId.SubTitle] = create_text("One, Two, Three")

	// poll for queued events each game loop
	event : SDL.Event

	game_loop : for
	{
		if SDL.PollEvent(&event)
		{
			if end_game(&event) do break game_loop

			handle_events(&event)
		}

		// START update and render

		// render Title
		title : Text = &game.texts[TextId.Title]
		// render roughly at the center of the window
		title.dest.x = (game.window_w / 2) - (title.dest.w / 2)
		title.dest.y = (game.window_h / 2) - (title.dest.h)
		SDL.RenderCopy(game.renderer, title.tex, nil, &title.dest)

		// render Sub Title
		sub_title : Text = &game.texts[TextId.SubTitle]
		sub_title.dest.x = (game.window_w / 2) - (sub_title.dest.w / 2)
		sub_title.dest.y = (game.window_h / 2) + (title.dest.h / 2)
		SDL.RenderCopy(game.renderer, sub_title.tex, nil, &sub_title.dest)


		// END update and render


		draw_scene()
	}

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

	if event.type != SDL.EventType.KEYDOWN && event.type != SDL.EventType.KEYUP do return

	scancode := event.key.keysym.scancode

	#partial switch scancode
	{
		// increase
		case .I:
			game.font_size += 1
			err_code := SDL_TTF.SetFontSize(game.font, game.font_size)
			assert(err_code != -1, SDL.GetErrorString())
			// recreate the textures with the new font size
			game.texts[TextId.Title] = create_text("Testing", 3)
			game.texts[TextId.SubTitle] = create_text("One, Two, Three")

		// decrease
		case .D:
			game.font_size -= 1
			err_code := SDL_TTF.SetFontSize(game.font, game.font_size)
			assert(err_code != -1, SDL.GetErrorString())
			game.texts[TextId.Title] = create_text("Testing", 3)
			game.texts[TextId.SubTitle] = create_text("One, Two, Three")

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

