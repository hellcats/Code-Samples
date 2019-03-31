proto = makeProto[spriteProto, Proto, "sprite"];

proto["minVel"] = 36;	(* pixels / sec *)
proto["maxVel"] = 72;

method[proto."constructor"][type_, radius_] := (
	method[this, super."constructor"][];

	this."type" = type;
	this."radius" = radius;
	this."vel" = RotationMatrix[RandomReal[2 Pi]] . {RandomReal[{this."minVel", this."maxVel"}], 0};
);

(*  actorInterface *)
method[proto."start"][] := Null;

method[proto."update"][] := Module[
	{sm, x, y},

	sm = this."gameObject"."sceneManager";
	{x, y} = this."gameObject"."transform"."position";
	{x, y} += sm."deltaTime" * this."vel";
	this."gameObject"."transform"."position" = {Mod[x, sm."width"], Mod[y, sm."height"]};
];

method[proto."setRandomPosition"][{w_, h_}, avoidOrigin_ : Null, avoidRadius_ : Null] := Module[
	{x, y},

	While[True,
		this."gameObject"."transform"."position" = {x, y} = {RandomReal[w], RandomReal[h]};

		If[avoidOrigin === Null || avoidRadius === Null || EuclideanDistance[{x, y}, avoidOrigin] > avoidRadius,
			Break[];
		];
	]
];
