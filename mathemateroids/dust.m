(*	A small animation of dust after an explosion *)

proto = makeProto[dustProto, Proto, final, "dust"];

proto["minInitialVel"] = 20;		(* Random initial velocity in range [minInitialVel, maxInitialVel] *)
proto["maxInitialVel"] = 75;
proto["numParticles"] = 8;
proto["C"] = 0.5;					(* Velocity dampening factor (v'[t] = -C v[t]) *)
proto["lifetime"] = 0.75;			(* In seconds *)

method[proto."constructor"][origin_] := (
	method[this, super."constructor"][];
	this."origin" = origin;
);

(*	actorInterface *)
method[proto."start"][] := Module[
	{theta0, rot},

	this."t0" = this."gameObject"."sceneManager"."time";
	theta0 = 2 Pi RandomReal[];
	this."vel" = Table[
		RandomReal[{this."minInitialVel", this."maxInitialVel"}] RotationMatrix[theta0 + i 2 Pi / this."numParticles"].{1, 0}
		, {i, this."numParticles"}];
	this."pos" = ConstantArray[this."origin", this."numParticles"];
];

method[proto."update"][] := Module[
	{sm},

	sm = this."gameObject"."sceneManager";
	this."pos" += sm."deltaTime" * this."vel";
	this."pos" = {Mod[#1, sm."width"], Mod[#2, sm."height"]}& @@@ (this."pos");

	(* Dampen velocity (v'[t] = -C v[t]) *)
	this."vel" = this."vel" E^(-this."C" sm."deltaTime");

	this."age" = sm."time" - this."t0";
	If[this."age" >= this."lifetime",
		delete[this."gameObject"]
	];
];

(*	graphicsInterface *)
method[proto."getGraphics"][] := (
	{GrayLevel[1 - this."age" / this."lifetime"], Point[this."pos"]}
);
