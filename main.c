// file:///home/ibro/Documents/Library/sdlwiki/SDL3/
#include <SDL3/SDL.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;

void draw() {
  const double now = ((double)SDL_GetTicks()) / 1000.0;
  const double col = (double)(SDL_GetTicks() % 2);
  SDL_SetRenderDrawColorFloat(renderer, col, col, col, SDL_ALPHA_OPAQUE_FLOAT);
  SDL_RenderClear(renderer);
  SDL_RenderPresent(renderer);
}

// Event docs: SDL_EventType.html
bool handle_event(SDL_Event *event) {
  switch (event->type) {
  case SDL_EVENT_WINDOW_RESIZED: {
    SDL_Log("resize (%d, %d)", event->window.data1, event->window.data2);
  } break;
  case SDL_EVENT_KEY_DOWN: {
    SDL_Log("key down: %d", event->window.data2);
  } break;
  case SDL_EVENT_KEY_UP: {
    SDL_Log("key up: %d", event->window.data2);
  } break;
  case SDL_EVENT_WINDOW_EXPOSED: {
    draw();
  } break;
  default: {
    SDL_Log("unhandled event: %d", event->type);
  } break;
  }
  return true;
}

bool init_ui() {
  SDL_SetAppMetadata("Hero", "1.0", "supply.same.handmade");
  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return false;
  }
  if (!SDL_CreateWindowAndRenderer("Hero", 640, 480, SDL_WINDOW_RESIZABLE,
                                   &window, &renderer)) {
    SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
    return false;
  }
  return true;
}

void quit() {
  SDL_DestroyWindow(window);
  SDL_Quit();
}

int main() {
  if (!init_ui()) {
    return -1;
  }

  bool done = false;
  while (!done) {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      if (event.type == SDL_EVENT_QUIT) {
        done = true;
      }
      handle_event(&event);
    }
  }

  quit();
  return 0;
}
