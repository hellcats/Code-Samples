Get["../ducksoop/ducksoop.m"];
include["sceneManager.m", "sprite.m", "ship.m", "bullets.m", "score.m", "alien.m", "dust.m"];

proto = makeProto[mathemateroidsProto, Proto, final, "mathemateroids"];

proto["bulletVel"] = 400;		(* Pixels / sec *)
proto["creationDelay"] = 1.5;	(* Seconds to wait before creating new ship or sprites *)
proto["teleportDelay"] = 1;		(* Seconds to wait after teleporting *)
proto["smallAlienScore"] = 40000;	(* Score at which only small alien ships appear *)
proto["alienLongDelay"] = 30;	(* Average seconds before next alien appears when score low *)
proto["alienShortDelay"] = 7.6;	(* Average seconds before next alien appears when score high *)

proto["soundsPath"] = FileNameJoin[{DirectoryName[$InputFileName], "Sounds"}];
proto["spritesPath"] = FileNameJoin[{DirectoryName[$InputFileName], "Sprites"}];

(*	Sprite progression *)
proto["nextSpriteType"] = {"big" -> "med", "med" -> "small", "small" -> Null};

proto["beatDelay"] = 60;						(* Delay in secs. from start of level to beatMaxFreq *)
proto["beatMaxFreq"] = 3;						(* Max "heartbeats"/sec *)
proto["beatMinFreq"] = 1/3;						(* Min "heartbeats"/sec *)
proto["numBeatTracks"] = 16;					(* Number of discrete looping heartbeat tracks *)

method[proto."constructor"][options___] := (
	method[this, super."constructor"][];

	(this[#1] = #2)& @@@ Flatten[{options}];	(* Assign all options (e.g. {"bulletVel" -> 200} *)

	this."sceneManager" = new[sceneManagerProto][options];	(* Pass options to sceneManager *)
	this."sprites" = {};

	this."spriteDestroyedSignal" = new[signalProto][];

	this."alienRandomReal" = RandomReal[];

	this."beatObj" = Null;
	this."makeBeatSounds$"[];

	this."state" = "Paused";
);

(*	Main entry point. Call this to play 'Mathemateroids'. *)
method[proto."start"][] := Module[
	{go, sm},

	sm = this."sceneManager";

	this."startPanel" = this."makeStartPanel$"[];
	this."gameOverPanel" = this."makeGameOverPanel$"[];
	this."scorePanel" = this."makeScorePanel$"[];

	go = sm."newGameObject"[];
	this."bullets" = go."addComponent"[new[bulletsProto][]];

	sm."escapeKeyDownSignal"."connect"[sm."stop"];
	sm."keyDownSignal"."connect"[this."keyDown$"];
	sm."upArrowKeyDownSignal"."connect"[this."upArrowDown$"];

	(*	Perform actions prior to component updates. Use signal group 75 (group 100 is used for component updates,
		group 50 is used for event handlers, I want preUpdate to be called between these)
	*)
	sm."updateSignal"."connect"[this."preUpdate$", 75];

	this."initializeNewGame$"[True];

	sm."start"[]
];

method[proto."deleteAlienShip"][] := Module[
	{go},

	go = this."alienShip"."gameObject";
	this."sprites" = DeleteCases[this."sprites", go];
	this."alienShip" = Null;
	this."alienTime" = this."sceneManager"."time";
	delete[go];
];

method[proto."addBullet"][pos_, vel_, owner_] := (
	this."bullets"."addBullet"[pos, vel, owner];
);

method[proto."initializeNewGame$"][makeNewSprites_] := (
	this."alienShip" = Null;

	this."playerShip" = Null;
	this."shipsRemaining" = 3;	(* Start with 3 ships (playerShip is one of the ships) *)

	this."score"."score" = 0;

	this."startWait" = -Infinity;

	this."heartbeatTime" = this."sceneManager"."time";
	this."alienTime" = this."sceneManager"."time";

	If[makeNewSprites,
		this."numSprites" = 4;
		delete /@ (this."sprites");
		this."sprites" = {};
		this."makeBigSprites$"[this."numSprites"];
	];

	this."bullets"."deleteAll"[];
);

method[proto."startNewGame$"][firstGame_ : False] := (
	this."initializeNewGame$"[!firstGame];
	this."setState$"["MakePlayerShip"];
);

(*	Called before update is called on the game components *)
method[proto."preUpdate$"][] := Module[
	{sm, w, h},

	sm = this."sceneManager";
	{w, h} = {sm."width", sm."height"};

	Switch[this."state",
		"Paused",	(* Paused means a UI panel is being displayed *)
			Null,

		"MakePlayerShip",
			this."detectCollisions$"[];
			If[sm."time" - this."startWait" > this."creationDelay",
				this."makePlayerShipIfSafe$"[{w/2, h/2}];
				If[this."playerShip" =!= Null,
					If[Length[this."sprites"] == 0,
						this."setState$"["MakeBigSprites"];
						(* Create sprites immediately since I already waited for the ship to be created *)
						this."startWait" = -Infinity
					,
						this."setState$"["Playing"]
					]
				]
			],

		"Teleport",
			this."detectCollisions$"[];
			If[sm."time" - this."startWait" > this."teleportDelay",
				Do[
					(*	Attempt to create ship somewhere in center 1/2 of screen *)
					this."makePlayerShipIfSafe$"[{w/4, h/4} + {RandomReal[w/2], RandomReal[h/2]}];
					If[this."playerShip" =!= Null,
						this."playerShip"."gameObject"."transform"."rotation" = this."teleportRotation";
						this."setState$"["Playing"];
						Break[]
					]
				,{25}]
			],

		"MakeBigSprites",
			If[sm."time" - this."startWait" > this."creationDelay",
				this."makeBigSprites$"[this."numSprites"];
				this."setState$"["Playing"]
			],

		"Playing",
			this."detectCollisions$"[];
			this."heartbeat$"[];
			this."doAliens$"[];

			Which[
				this."playerShip" === Null && this."shipsRemaining" > 0,
					this."setState$"["MakePlayerShip"],

				this."playerShip" === Null,
					this."gameOverPanel"."active" = True;
					this."setState$"["Paused"],

				Length[this."sprites"] == 0,
					this."numSprites" += 2;
					this."setState$"["MakeBigSprites"]
			],
		_,
			Print@{"Unmatched state", this."state"};
			Abort[]
	];

	(*	Check if user has control *)
	If[this."state" != "Playing" && this."state" != "Teleport",
		(* Don't play the "heartbeat" when player not in control *)
		sm."audioMixer"."stop"[this."beatObj"];
		this."heartbeatTime" += sm."deltaTime";		(* don't age heartbeat either *)

		(* Don't age alien ship while player not in control *)
		this."alienTime" += sm."deltaTime";
	];
];

method[proto."setState$"][newState_] := (
	Switch[newState,
		"MakeBigSprites" | "MakePlayerShip" | "Teleport",
			this."startWait" = this."sceneManager"."time"
	];

	this."state" = newState;
);

method[proto."detectCollisions$"][] := Module[
	{go, sprite, deleteSprite, deleted, nextType, newSprite, deleteAlien = False},

	(*	Check bullets and player ship vs. sprites (note: alien ship is also a sprite, but player ship isn't) *)
	deleted = 0;
	Do[
		sprite = go."getComponent"[spriteProto];
		deleteSprite = False;

		If[this."bullets"."detectCollisions"[go, sprite."radius"],
			deleteSprite = True;
		,
			If[this."playerShip" =!= Null,
				If[this."objectObjectOverlap$"[go, sprite."radius", this."playerShip"."gameObject", this."playerShip"."radius"],
					this."destroyPlayerShip$"[];
					deleteSprite = True
				]
			]
		];

		(*	Check for collision between alien ship and a sprite *)
		If[this."alienShip" =!= Null && !deleteAlien && go =!= this."alienShip"."gameObject",
			If[this."objectObjectOverlap$"[go, sprite."radius", this."alienShip"."gameObject", this."alienShip"."radius"],
				deleteSprite = True;
				deleteAlien = True
			]
		];

		If[deleteSprite,
			this."deleteSprite$"[go, sprite]
			deleted++;
		]
	, {go, this."sprites"}];

	If[deleteAlien && this."alienShip" =!= Null,
		this."deleteAlienShip"[]
	];

	(*	Check bullets vs. player ship *)
	If[this."playerShip" =!= Null && this."bullets"."detectCollisions"[this."playerShip"."gameObject", this."playerShip"."radius"],
		this."destroyPlayerShip$"[];
		deleted++;	(* Play boomSound *)
	];

	If[deleted > 0,
		this."sceneManager"."audioMixer"."play"[this."assets"."boomSound"]
	];
];

method[proto."objectObjectOverlap$"][go1_, radius1_, go2_, radius2_] := (
	EuclideanDistance[go1."transform"."position", go2."transform"."position"] < (radius1 + radius2)
);

method[proto."deleteSprite$"][go_, sprite_] := Module[
	{nextType, newSprite, dust},

	this."spriteDestroyedSignal"."fire"[sprite];

	dust = this."sceneManager"."newGameObject"[];
	dust = dust."addComponent"[new[dustProto][go."transform"."position"]];

	If[sprite."type" == "bigAlien" || sprite."type" == "smallAlien",
		this."deleteAlienShip"[];
	,
		this."sprites" = DeleteCases[this."sprites", go];
		nextType = sprite."type" /. this."nextSpriteType";
		If[nextType =!= Null,
			Do[
				newSprite = this."makeSprite$"[RandomChoice[this."assets"[nextType <> "Sprites"]]];
				newSprite."vel" += sprite."vel";
				newSprite."gameObject"."transform"."position" = go."transform"."position";
				AppendTo[this."sprites", newSprite."gameObject"]
			,{2}]
		];
		delete[go];
	];
];

method[proto."destroyPlayerShip$"][] := (
	delete[this."playerShip"."gameObject"];
	this."shipsRemaining" -= 1;
	this."playerShip" = Null;
);

(*	What do aliens do? *)
method[proto."doAliens$"][] := Module[
	{sm = this."sceneManager", x, y, w, h, age, sprite, go, big, lam, mean, sig},

	If[this."alienShip" === Null,
		(* 	Decide if an alien ship should appear. Use a normal distribution of wait times. *)
		lam = Min[this."score"."score"/this."smallAlienScore", 1];	(* difficulty factor: 0=easy, 1=hard *)
		mean = (1.0 - lam) this."alienLongDelay" + lam this."alienShortDelay";
		age = sm."time" - this."alienTime";
		sig = mean/3;	(* Scale normal distribution so that 3 sigma fit around mean *)
		If[this."alienRandomReal" < CDF[NormalDistribution[mean, sig], age],
			{w, h} = {sm."width", sm."height"};

			(* 	Choose between big and little alien *)
			big = RandomReal[] > lam;
			If[big,
				sprite = this."makeSprite$"[this."assets"."bigAlien"]
			,
				sprite = this."makeSprite$"[this."assets"."smallAlien"]
			];
			go = sprite."gameObject";
			this."alienShip" = go."addComponent"[new[alienProto][this, big]];
			AppendTo[this."sprites", go];

			this."alienRandomReal" = RandomReal[];
		]
	];
];

method[proto."heartbeat$"][] := Module[
	{sm, age, beatIndex, beatFreq},

	sm = this."sceneManager";
	age = sm."time" - this."heartbeatTime";
	beatIndex = Round[Rescale[age, {0, this."beatDelay"}] (this."numBeatTracks" - 1) + 1];
	beatIndex = Min[beatIndex, this."numBeatTracks"];
	If[isa[this."beatObj", Proto],
		If[this."beatIndex" =!= beatIndex,
			this."beatObj" = sm."audioMixer"."playAfter"[this."beatObj", this["beat", beatIndex], True];
			this."beatIndex" = beatIndex;
		]
	,
		this."beatObj" = sm."audioMixer"."play"[this["beat", beatIndex], True];
		this."beatIndex" = beatIndex;
	];
];

method[proto."keyDown$"][key_] := Module[
	{shipTransform, pos, vel},

	If[this."state" == "Playing" && key == " ",
		shipTransform = this."playerShip"."gameObject"."transform";
		pos = shipTransform."position";
		vel = (this."bulletVel" + Norm[this."playerShip"."vel"]) shipTransform."getYAxis"[];
		this."bullets"."addBullet"[pos, vel, this."playerShip"."gameObject"];

		this."sceneManager"."audioMixer"."play"[this."assets"."fireSound"]
	];
];

(*	Teleport playerShip to safe location *)
method[proto."upArrowDown$"][] := (
	If[this."state" == "Playing",
		this."teleportRotation" = this."playerShip"."gameObject"."transform"."rotation";
		delete[this."playerShip"."gameObject"];
		this."playerShip" = Null;
		this."setState$"["Teleport"]
	];
);

method[proto."makePlayerShipIfSafe$"][pt_] := Module[
	{minDist, go, ship},

	(*	Find closest sprite to center of screen *)
	minDist = this."computeMinClearDistance$"[pt];
	If[minDist > this."sceneManager"."width" / 8,
		go = this."sceneManager"."newGameObject"[];
		go."transform"."position" = pt;
		(* Use staticGraphics instance as prototype - inherit all its properties and behaviors *)
		ship = go."addComponent"[new[this."assets"."ship"][]];
		this."playerShip" = go."addComponent"[new[shipProto][ship."radius", this."assets"."thrustSound"]];
	];
];

(*	Return minimum distance to something playerShip could collide with *)
method[proto."computeMinClearDistance$"][pt_] := Module[
	{},
	If[Length[this."sprites"] > 0,
		Min[Norm[#."transform"."position" - pt]& /@ (this."sprites")]
	,
		Infinity
	]
];

method[proto."loadAssets"][] := Module[
	{assets, makeGraphics, makeRasterGraphics, importSound},

	makeGraphics[filename_] := new[staticGraphicsProto] @@@ Get[FileNameJoin[{this."spritesPath", filename}]];

	(*	Have to call Rasterize on the Raster read from disk otherwise performance tanks.
		Rasterize must do something special. *)
	makeRasterGraphics[filename_] := Module[{raster, gr, type, radius, xmin, xmax, ymin, ymax},
		Table[
			{gr, type, radius} = p;
			raster = gr[[1]];
			dim = Dimensions[raster[[1]]];
			{{xmin, ymin}, {xmax, ymax}} = {{0,0}, dim[[1;;2]]};
			raster = Inset@Rasterize[Graphics[raster, PlotRange -> {{xmin, xmax}, {ymin, ymax}}], ImageSize -> {xmax, ymax}, Background -> Blue];
			gr[[1]] = raster;
			new[staticGraphicsProto][gr, type, radius]
		, {p, Get[FileNameJoin[{this."spritesPath", filename}]]}]
	];

	this."assets" = assets = new[Proto][];
	assets."bigSprites" = makeRasterGraphics["bigSprites.m"];
	assets."medSprites" = makeRasterGraphics["medSprites.m"];
	assets."smallSprites" = makeRasterGraphics["smallSprites.m"];
	{assets."bigAlien", assets."smallAlien"} = makeRasterGraphics["alienShips.m"];
	{assets."ship", assets."shipFlame"} = makeGraphics["playerShip.m"];

	(*	Flatten because Import[] sometimes returns a nested list for mono sampled sound files *)
	importSound[filename_] := Flatten[Import[FileNameJoin[{this."soundsPath", filename}], "Data"]];
	assets."fireSound" = importSound["MyFire8K.wav"];
	assets."boomSound" = importSound["MyBoom8K.wav"];
	assets."thrustSound" = importSound["MyThrust8K.wav"];
	assets."lowBeat" = importSound["MyLowBeat8K.wav"];
	assets."highBeat" = importSound["MyHighBeat8K.wav"];
	assets."alienSound" = importSound["MyAlien8K.wav"];
	assets."smallAlienSound" = importSound["MySmallAlien8K.wav"];
];

(*	Create initial set of big sprites *)
method[proto."makeBigSprites$"][n_] := Module[
	{sm, w, h, sprite, avoid = Null, avoidRadius = Null},

	sm = this."sceneManager";
	{w, h} = {sm."width", sm."height"};

	If[this."playerShip" =!= Null,
		avoid = this."playerShip"."gameObject"."transform"."position";
		avoidRadius = w/4;
	];

	this."sprites" = Table[
		sprite = this."makeSprite$"[RandomChoice[this."assets"."bigSprites"]];
		sprite."setRandomPosition"[{w, h}, avoid, avoidRadius];
		sprite."gameObject"
	,{n}];

	(*	This is start of a new "level" *)
	this."heartbeatTime" = sm."time";
];

method[proto."makeSprite$"][sg_] := Module[
	{w, h, go, sprite},

	{w, h} = {this."sceneManager"."width", this."sceneManager"."height"};

	go = this."sceneManager"."newGameObject"[];
	sprite = new[spriteProto][sg."type", sg."radius"];
	go."addComponent"[sprite];
	sprite."setRandomPosition"[{w, h}];
	(* Use staticGraphics instance sg as prototype - inherit all its properties and behaviors *)
	go."addComponent"[new[sg][]];
	sprite
];

method[proto."makeBeatSounds$"][] := Module[
	{sm, lowBeat, highBeat, beatFreq, samples, silent1, silent2, buf, lerp},

	sm = this."sceneManager";
	lowBeat = this."assets"."lowBeat";
	highBeat = this."assets"."highBeat";
	lerp[lam_, a_, b_] := (1-lam)a + lam b;

	Do[
		beatFreq = lerp[Rescale[i, {1, this."numBeatTracks"}], this."beatMinFreq", this."beatMaxFreq"];
		samples = Floor[sm."audioMixer"."freq" / beatFreq];		(* Total samples in one beat cycle *)
		silent1 = Floor[(samples - Length[lowBeat] - Length[highBeat])/2];
		silent2 = samples - Length[lowBeat] - Length[highBeat] - silent1;
		buf = Join[lowBeat, ConstantArray[0, silent1], highBeat, ConstantArray[0, silent2]];
		this["beat", i] = buf;
	,{i, this."numBeatTracks"}];
];

method[proto."makeStartPanel$"][] := Module[
	{panel, text, gr, sm},

	panel = this."sceneManager"."newGameObject"[];

	sm = 20;
	text = Column[{
		Style["Mathemateroids", Italic, FontSize -> 50],
		Style["By Eric 'Hellcats' Parker", FontSize -> sm],
		Style[" ", FontSize -> sm/2],
		Style["Instructions", FontSize -> sm],
		Style["SPACE fires cannon", FontSize -> sm],
		Style["SHIFT turns engine on", FontSize -> sm],
		Style["LEFT and RIGHT arrows rotate ship", FontSize -> sm],
		Style["UP arrow teleports", FontSize -> sm],
		Style["ESC quits the game", FontSize -> sm],
		Style["Press ENTER to begin", FontSize -> sm]
	}];
	gr = {White, Text[text, Scaled[{0.5, 0.5}]]};
	panel."addComponent"[new[staticGraphicsProto][gr]];

	this."sceneManager"."returnKeyDownSignal"."connect"[
		If[panel."active",
			panel."active" = False;
			this."startNewGame$"[True]
		]&
	];

	panel
];

method[proto."makeGameOverPanel$"][] := Module[
	{panel, text, gr},

	this."gameOverPanel" = panel = this."sceneManager"."newGameObject"[];
	panel."active" = False;
	text = Column[{
		Style["Game Over", FontSize -> 50],
		Style["Press ENTER to start a new game", FontSize -> 20]
	}];
	gr = {White, Text[text, Scaled[{0.5, 0.5}]]};
	panel."addComponent"[new[staticGraphicsProto][gr]];
	this."sceneManager"."returnKeyDownSignal"."connect"[
		If[panel."active",
			panel."active" = False;
			this."startNewGame$"[]
		]&
	];

	panel
];

method[proto."makeScorePanel$"][] := Module[
	{sm, panel},

	sm = this."sceneManager";
	panel = sm."newGameObject"[];
	this."score" = panel."addComponent"[new[scoreProto][this, this."assets"."ship"]];
	panel."transform"."position" = {sm."width", sm."height"} {.05, .95};

	panel
];





