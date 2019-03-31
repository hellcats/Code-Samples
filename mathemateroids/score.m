proto = makeProto[scoreProto, Proto, final, "score"];

proto["newShipPoints"] = 10000;
proto["points"] = {"big" -> 20, "med" -> 50, "small" -> 100, "bigAlien" -> 200, "smallAlien" -> 1000};

method[proto."constructor"][game_, ship_] := Module[
	{},

	this."score" = 0;
	this."game" = game;
	this."ship" = ship;

	game."spriteDestroyedSignal"."connect"[this."spriteDestroyed$"];
];

method[proto."getGraphics"][] := Module[
	{score, ships},

	score = Text[Style[this."score", White, FontSize -> 24], {0, 0}, {Left, Center}];

	(*	 Draw multiple copies of the ship *)
	ships = If[this."game"."shipsRemaining" > 0,
		Translate[this."ship"."graphics", Table[this."ship"."radius" + {(i-1) 2 (this."ship"."radius" + 2), -32}, {i, 1, this."game"."shipsRemaining"}]]
	,
		Null
	];

	{score, ships}
];

method[proto."spriteDestroyed$"][sprite_] := Module[
	{newScore},

	newScore = this."score" + sprite."type" /. this."points";
	If[Quotient[newScore, this."newShipPoints"] != Quotient[this."score", this."newShipPoints"],
		this."game"."shipsRemaining" += 1
	];
	this."score" = newScore;
];
