# Rendering Static Text

To render the text to the screen we still require our game loop. I've tried to move as much of that boilerplate / secondary code outside of the `main` function so you can focus on what is necessary for rendering text.

## Initializing the SDL TrueType Font Library

As with all SDL libraries, we need to initialize the TTF library before we can use it, and this includes chosing the font we want to use for the text textures we want to render. For our example we'll use the Terminal font.

```odin

init_font := SDL_TTF.Init()
assert(init_font == 0, SDL.GetErrorString())
game.font = SDL_TTF.OpenFont("Terminal.ttf", game.font_size)
assert(game.font != nil, SDL.GetErrorString())

```

## Creating Textures from Our Chosen Text

Next we'll create a helper function for creating our text textures:

```odin

// create textures for the given str
// optional scale param allows us to easily size the texture generated
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

With the exception of the text itself and the sizing, the code is the same for creating each texture. Using this helper function allows us to avoid typing the same code again and again.

### The Text Struct

Notice the `create_text` function returns a new object -- `Text`

```odin

Text :: struct
{
	tex: ^SDL.Texture,
	dest: SDL.Rect,
}

```

This struct holds a reference to our texture and the SDL.Rect used to render the texture to the window.

What is a texture? It is the object we render to the window. It is created from the `cstring` text we want to display in our chosen font.

We're creating these textures before our loop. We only need to create our texture once for a given size; there's no need to recreate these textures on each game loop iteration.

```odin

game.texts[TextId.Title] = create_text("Testing", 3)
game.texts[TextId.SubTitle] = create_text("One, Two, Three")

```

### TextId Enum

To help keep track of our Text objects we're storing each in an enumerated array with easy-to-read lookup keys that are enum variants.

Enums, or Enumeration Types, define a new type with the values we choose. In our case we have a type of `TypeId` with possible values `Title` and `SubTitle`.

When we want to render one of our text textures, we just have to get it from our array and tell SDL where to render it:

```odin

title := game.texts[TextId.Title]
// render roughly at the center of the window
title.dest.x = (WINDOW_WIDTH / 2) - (title.dest.w / 2)
title.dest.y = (WINDOW_HEIGHT / 2) - (title.dest.h)
SDL.RenderCopy(game.renderer, title.tex, nil, &title.dest)

```

### Changing Font Size

There are three ways we change the font size:

1. Setting font_size when we call `SDL_TTF.OpenFont()`
2. Re-setting the font_size using `SDL_TTF.SetFontSize()`
3. Scaling our destination SDL.Rect to which we render our texture.

