proto = makeProto[shipProto, Proto, final, "ship"];

proto["turnRate"] = 12.5 Degree;
proto["dampenRate"] = 0.5;		(* Vel dampening/sec *)
proto["thrust"] = 10.0;			(* Acceleration while engine is on *)
proto["minVel"] = 5;			(* Lower vel limit - vel will be set to zero if it goes below this value *)
proto["maxVel"] = 200;			(* Upper vel limit *)

method[proto."constructor"][radius_, thrustSound_] := (
	method[this, super."constructor"][];

	this."radius" = radius;
	this."thrustSound" = thrustSound;
	this."soundObject" = Null;		(* Object reference to sound while being played *)
	this."engineOn" = False;
);

method[proto."destructor"][] := Module[
	{sm},

	sm = this."gameObject"."sceneManager";
	sm."leftArrowKeyDownSignal"."disconnect"[this."leftArrowDown$"];
	sm."rightArrowKeyDownSignal"."disconnect"[this."rightArrowDown$"];
	this."stopEngineSound$"[];

	method[this, super."destructor"][];
];

method[proto."start"][] := Module[
	{sm},

	sm = this."gameObject"."sceneManager";
	sm."leftArrowKeyDownSignal"."connect"[this."leftArrowDown$"];
	sm."rightArrowKeyDownSignal"."connect"[this."rightArrowDown$"];

	this."vel" = {0, 0};
];

method[proto."update"][] := Module[
	{sm, h, x, y, v},

	sm = this."gameObject"."sceneManager";
	h = sm."deltaTime";

	If[CurrentValue["ShiftKey"],
		this."engineOn" = True;
		this."vel" += this."thrust" this."gameObject"."transform"."getYAxis"[];

		this."playEngineSound$"[]
	,
		this."engineOn" = False;
		this."vel" *= this."dampenRate"^h;

		this."stopEngineSound$"[]
	];

	v = Norm[this."vel"];
	If[v < this."minVel",
		this."vel" = {0, 0}
	,
		this."vel" = Min[v, this."maxVel"] this."vel" / v
	];

	{x, y} = this."gameObject"."transform"."position";
	{x, y} += h this."vel";
	this."gameObject"."transform"."position" = {Mod[x, sm."width"], Mod[y, sm."height"]};
];

(*	Add a little flame to ship when engines are on *)
method[proto."getGraphics"][] := Module[
	{sm, tip},

	If[this."engineOn",
		sm = this."gameObject"."sceneManager";
		{White, Line[{{-4, -7.5}, {0, -11 + 3 Cos[40 sm."time"]}, {4, -7.5}}]}
	,
		Null
	]
];

method[proto."leftArrowDown$"][] := (
	this."gameObject"."transform"."rotation" += this."turnRate";
);

method[proto."rightArrowDown$"][] := (
	this."gameObject"."transform"."rotation" -= this."turnRate";
);

(*	Start playing the engine thrust sound if it isn't currently playing *)
method[proto."playEngineSound$"][] := (
	If[!isa[this."soundObject", Proto],
		this."soundObject" = this."gameObject"."sceneManager"."audioMixer"."play"[this."thrustSound", True]
	]
);

(*	Stop the engine thrust sound if it is currently playing *)
method[proto."stopEngineSound$"][] := (
	If[isa[this."soundObject", Proto],
		this."gameObject"."sceneManager"."audioMixer"."stop"[this."soundObject"]
	]
);


