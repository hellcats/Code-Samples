proto = makeProto[bulletsProto, Proto, final, "bullets"];

proto["lifetime"] = 1;

proto["pos"] = {};
proto["vel"] = {};
proto["creationTime"] = {};
proto["owner"] = {};				(* Bullets don't collide with their owner gameObject *)

method[proto."addBullet"][pos_, vel_, owner_] := (
	AppendTo[this."pos", pos];
	AppendTo[this."vel", vel];
	AppendTo[this."creationTime", this."gameObject"."sceneManager"."time"];
	AppendTo[this."owner", owner];	(* Set the owner gameObject (may be Null) *)
);

method[proto."start"][] := Null;

method[proto."update"][] := Module[
	{sm, old},

	sm = this."gameObject"."sceneManager";
	old = Position[this."creationTime", x_ /; sm."time" - x > this."lifetime"];
	If[Length[old] >= 1,
		this."deleteIndices$"[old];
	];

	this."pos" += sm."deltaTime" * this."vel";
	this."pos" = {Mod[#1, sm."width"], Mod[#2, sm."height"]}& @@@ (this."pos");
];

method[proto."getGraphics"][] := (
	{White, Point[this."pos"]}
);

(*	Continuous collision detection between bullets and a circle centered at the gameObject with given radius.
	Returns True on first collision detected.
	The colliding bullet is also deleted.
 *)
method[proto."detectCollisions"][go_, radius_] := Module[
	{sm, owner, h, origin, p, q, u, v, a, b, c, d, test, t1, t2, ret},

	sm = this."gameObject"."sceneManager";
	owner = this."owner";
	h = sm."deltaTime";
	origin = go."transform"."position";	(* Origin of circle to test against *)

	p = this."pos" ;					(* Start of line segment *)
	q = this."pos" + h this."vel";		(* End of line segment *)
	u = origin - #& /@ p;				(* Vectors from a to origin of circle *)
	v = p - q;
	a = MapThread[Dot, {v, v}];
	b = 2 MapThread[Dot, {u, v}];
	c = MapThread[Dot, {u, u}] - radius^2;

	test[a_, b_, c_] := (
		d = b^2 - 4 a c;
		If[d > 0,
			{t1, t2} = {(-b - Sqrt[d])/(2 a), (-b + Sqrt[d])/(2 a)};
			t1 >= 0 && t1 <= 1 || t2 >= 0 && t2 <= 1
		,
			False
		]
	);

	ret = False;
	Do[
		If[owner[[i]] =!= go && test[a[[i]], b[[i]], c[[i]]],
			this."deleteIndices$"[{i}];
			ret = True;		(* Can't directly return from a function when inside a Do loop *)
			Break[];
		]
	,{i, Length@p}];
	ret
];

method[proto."deleteAll"][] := (
	this."pos" = this."vel" = this."creationTime" = this."owner" = {};
);

method[proto."deleteIndices$"][indices_] := (
	this."pos" = Delete[this."pos", indices];
	this."vel" = Delete[this."vel", indices];
	this."creationTime" = Delete[this."creationTime", indices];
	this."owner" = Delete[this."owner", indices];
);


