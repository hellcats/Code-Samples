(*  actorInterface

	Actors implement behavior.  The gameProto instance calls the update method once per frame.
*)
proto = makeProto[actorInterface, interfaceProto, "actorInterface"];

(*  Called before the first update. *)
method[proto."start"][] := abstract;

(*  Called once each time through the game loop.

	sceneManager."deltaTime" contains the elapsed time in seconds since the previous update.
*)
method[proto."update"][] := abstract;


(*  graphicsInterface

	Return graphics primitives for rendering.  The primitives will be wrapped in Graphics[...] before display.
*)
proto = makeProto[graphicsInterface, interfaceProto, "graphicsInterface"];

method[proto."getGraphics"][] := abstract;
