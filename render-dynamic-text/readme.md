# Rendering Dynamic Text

This is a method I came up with for rendering dynamic text.

By "dynamic" I mean text that isn't known at compile time -- text that comes from keyboard input events.

This is a fairly simple example -- things like word-wrapping and line breaks aren't handled.

**If you haven't already read the guide on Rendering Static Text, please do so before reading this one.**

## Texture Map

First, we create a `map` so we can lookup textures for numbers, letters, and other symbols.

```odin

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

```

Our map and related `Text` struct are defined and initialized like so:

```odin

Text :: struct
{
	tex: ^SDL.Texture,
	dest: SDL.Rect,
}

Game :: struct
{
	// existing code..

	chars: map[rune]Text,
}

game := Game{
	chars = make(map[rune]Text),
}

```

To create the `Text` objects stored in our `game.chars` map we use the `create_text` function from the last guide:

```odin
COLOR_WHITE : SDL.Color : {255,255,255,255}

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

```

This map of `Text` objects helps us when it comes time to render the text we capture from the TEXTINPUT event.

We render our captured text in our game loop:

```odin

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

```

Our render code goes through each character in a string -- `game.text_input`, finds its corresponding texture in our texture map, then renders that texture next to the previous one. Using `prev_chars_w` allows us to keep track of where to place our current character as we iterate through all characters in the string.

But how do we capture the text input from the keyboard?

## Taking Keyboard Input

```odin

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
		//
	}

}

```

In our `handle_events()` function we handle all TEXTINPUT events to grab the text from `event.text.text`. It's necessary to transform the text slice to a cstring to strip out any odd characters -- `cstring(raw_data(event.text.text[:]))`. We then concatenate the current string with the new input. `strings.concatenate({game.text_input, string(input)})`.

If we make a mistake, deleting the last character is easy. We take a slice of the current string being sure to leave off the last character in the string.

```odin

handle_events :: proc(event: ^SDL.Event)
{

	scancode := event.key.keysym.scancode

	if event.type == SDL.EventType.TEXTINPUT
	{
		//
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

```

## StartTextInput(), StopTextInput(), and SetTextInputRect()

Solid information on these functions is hard to find. They don't seem necessary for running this on Windows, though perhaps they are necessary for running a program on a phone, or accepting non-English text.

If you have more information to shed some light on these functions, please share.