# Rendering Dynamic Text

This is a method I came up with for rendering dynamic text.

By "dynamic" I mean text that isn't known at compile time.

This is a fairly simple example -- things like word-wrapping and line breaks aren't handled.

**If you haven't already read the guide on Rendering Static Text, please do so before reading this one.**

## Texture Map

First, we create a `map` so we can lookup textures for numbers, letters, and other symbols.

```odin

// create a map of chars that be used in make_word
create_chars :: proc()
{

	chars := "!@#$%^&*();:',.@_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for c in chars[:]
	{
		str := utf8.runes_to_string([]rune{c})
		defer delete(str)

		surface := SDL_TTF.RenderText_Solid(game.font, cstring(raw_data(str)), COLOR_WHITE)
		defer SDL.FreeSurface(surface)

		game.chars[c] = SDL.CreateTextureFromSurface(game.renderer, surface)
	}
}

```

This map helps us when using `make_word()`.

## make_word() to Render Our Text

```odin

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

```

`make_word()` goes through each character in a string, finds its corresponding texture in our texture map, then renders that texture next to the previous one. Using `prev_chars_w` allows us to keep track of where to place our current character as we iterate through all characters in the string.

But how does our keyboard input get to the screen?

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