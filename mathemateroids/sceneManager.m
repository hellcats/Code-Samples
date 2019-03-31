include["audioMixer.m", "gameObject.m", "interfaces.m", "staticGraphics.m"];

(*  sceneManagerProto manages gameObjects and runs the main game loop.

*)
proto = makeProto[sceneManagerProto, Proto, final, "sceneManager"];

proto["width"] = 640;
proto["height"] = 480;
proto["targetFrameRate"] = 20;
proto["audioEnabled"] = True;

method[proto."constructor"][options___] := (
	method[this, super."constructor"][];

	(this[#1] = #2)& @@@ Flatten[{options}];	(* Assign all options (e.g. {"width" -> 720, "height" -> 540} *)

	this."running" = False;
	this."time" = 0;
	this."deltaTime" = 0;		(* Time in seconds since last update *)
	this."frameTimes" = {};		(* Keep track of frame execution times for performance profiling *)

	this."gameObjects" = {};	(* All gameObjects *)

	(* 	Queue Mma events since they are sent on the "preemptive" kernel link while the rest of the game runs
		on the main link. *)
	this."eventQueue" = {};

	(*	Signals connected to Mathematica EventHandler *)
	this."keyDownSignal" = new[signalProto][];
	this."returnKeyDownSignal" = new[signalProto][];
	this."escapeKeyDownSignal" = new[signalProto][];
	this."leftArrowKeyDownSignal" = new[signalProto][];
	this."rightArrowKeyDownSignal" = new[signalProto][];
	this."upArrowKeyDownSignal" = new[signalProto][];
	this."downArrowKeyDownSignal" = new[signalProto][];

	(*	Update signal. Fired once per frame. *)
	this."updateSignal" = new[signalProto][];

	(*	Create the audioMixer. call its "play" method to play a sound. *)
	this."audioMixer" = new[audioMixerProto][this];
	this."audioMixer"."enabled" = this."audioEnabled";
);

method[proto."start"][] := (
	this."running" = True;
	this."time" = 0;
	this."deltaTime" = 0;		(* Time in seconds since last update *)
	this."frameTime" = SessionTime[];

	(*	actorInterface updates happen in signal group 100 *)
	this."updateSignal"."connect"[this."callQueuedEventListeners$", 50];
	this."updateSignal"."connect"[this."callUpdateOnAllComponents$", 100];

	this."getPanel$"[]
);

method[proto."stop"][] := (
	this."running" = False;

	this."updateSignal"."disconnect"[this."callQueuedEventListeners$", 50];
	this."updateSignal"."disconnect"[this."callUpdateOnAllComponents$", 100];
);

(*	Add an existing gameObject to the scene *)
method[proto."addGameObject"][go_] := (
	AppendTo[this."gameObjects", go];
	go."sceneManager" = this;
	go
);

(*	Remove a gameObject from the scene. The game object is not deleted. *)
method[proto."removeGameObject"][go_] := (
	this."gameObjects" = DeleteCases[this."gameObjects", go];
	go."sceneManager" = Null;
	go
);

(*	Both create a new gameObject and add it to the scene *)
method[proto."newGameObject"][] := (
	this."addGameObject"[new[gameObjectProto][]]
);

(*	Return a list of all components implementing the desired interfaces that are attached to active gameObjects.
	Each gameObject and all its parent gameObjects must also be active.
*)
method[proto."getActiveComponentsImplementing"][interfaces__] := (
	Select[Flatten[#."components"& /@ Select[this."gameObjects", method[this, "isActive"]]],
		interfaceProto."doesImplement"[#, interfaces]&]
);

(*	Return True if p and all its parent gameObjects are active *)
method[proto."isActive"][p_] := Module[
	{transform},

	If[p."active",
		For[transform = p."transform", transform =!= Null, transform = transform."parent",
			If[!transform."gameObject"."active",
				Return[False]
			]
		];
		True
	,
		False
	]
];

method[proto."getPanel$"][] := Module[
	{w, h},

	{w, h} = {this."width", this."height"};
	EventHandler[
		Graphics[
			this."getGraphics$"[]
			, PlotRange -> {{0, w}, {0, h}}, ImageSize -> {w, h}, Frame -> False, Background -> Black
		],
		{
			"KeyDown" :> With[{key = CurrentValue["EventKey"]},
				AppendTo[this."eventQueue", this."keyDownSignal"."fire"[key]&]],
			"ReturnKeyDown" :> AppendTo[this."eventQueue", this."returnKeyDownSignal"."fire"[]&],
			"EscapeKeyDown" :> AppendTo[this."eventQueue", this."escapeKeyDownSignal"."fire"[]&],
			"LeftArrowKeyDown" :> AppendTo[this."eventQueue", this."leftArrowKeyDownSignal"."fire"[]&],
			"RightArrowKeyDown" :> AppendTo[this."eventQueue", this."rightArrowKeyDownSignal"."fire"[]&],
			"UpArrowKeyDown" :> AppendTo[this."eventQueue", this."upArrowKeyDownSignal"."fire"[]&],
			"DownArrowKeyDown" :> AppendTo[this."eventQueue", this."downArrowKeyDownSignal"."fire"[][]&]
		}
		, PassEventsUp -> False
	]
];

(*	This function returns code to get all the graphics to be rendered, and injects a Dynamic[] that
	runs the main game loop.
*)
method[proto."getGraphics$"][] := Module[
	{gr, g, components, transform, xforms, frame},

	gr := (
		If[this."running",
			frame++
		];
		components = this."getActiveComponentsImplementing"[graphicsInterface];
		Table[
			g = p."getGraphics"[];
			If[g =!= Null,
				xforms = p."gameObject"."transform"."getTransformations"[];
				If[Length[xforms] > 0,
					GeometricTransformation[g, Composition@@xforms]
				,
					g
				]
			]
		,{p, components}]
	);

	Dynamic[
		{gr, this."doFrame$"[]},
		SynchronousUpdating -> False,
		TrackedSymbols :> {frame}, Initialization -> (frame = 0)
	]
];

method[proto."doFrame$"][] := Module[
	{now, elapsed, t},

	If[this."running",
		now = SessionTime[];
		elapsed = now - this."frameTime";
		this."frameTimes" = {this."frameTimes", elapsed};
		Pause[Max[1 / this."targetFrameRate" - elapsed, 0]];
		now = SessionTime[];
		this."deltaTime" = now - this."frameTime";
		this."frameTime" = now;
		this."time" += this."deltaTime";
		this."updateSignal"."fire"[];
	];
];

method[proto."callQueuedEventListeners$"][] := Module[
	{queue},

	(*	Atomic swap *)
	PreemptProtect[
		{queue, this."eventQueue"} = {this."eventQueue", {}}
	];
	#[]& /@ queue;
];

method[proto."callUpdateOnAllComponents$"][] := Module[
	{active, notStarted},

	(*	Ensure that the start method is called before the first update *)
	active = this."getActiveComponentsImplementing"[actorInterface];
	notStarted = Select[active, Not[#."started"]&];
	(#."start"[]; #."started" = True)& /@ notStarted;
	#."update"[]& /@ active;
];

