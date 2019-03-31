include["sprite.m"];

(*	This component implements alien space ship behavior.

	It is assumed that a spriteProto component is attached to the same gameObject as this component.
	sprite."vel" is modified to "fly" the alien ship.
*)
proto = makeProto[alienProto, Proto, final, "alien"];

proto["speed"] = 60;	(* pixels/sec *)

(* +/- angle error when small alien shoots at player. The error reduces at higher scores. *)
proto["smallAngle"] = 30.0 Pi / 180;

method[proto."constructor"][game_, big_] := (
	method[this, super."constructor"][];

	this."game" = game;
	this."big" = big;		(* True if big alien ship *)
	this."soundObj" = Null;
);

(*	Stop playing alien sound effect when ship is destroyed *)
method[proto."destructor"][] := (
	If[this."soundObj" =!= Null,
		this."gameObject"."sceneManager"."audioMixer"."stop"[this."soundObj"];
	];
	this.super."destructor"[];
);

(*  actorInterface *)
method[proto."start"][] := Module[
	{go, sm, w, h, x, y, sprite, sound},

	go = this."gameObject";
	sm = go."sceneManager";
	{w, h} = {sm."width", sm."height"};

	this."velChangeTime" = sm."time";

	this."sprite" = sprite = go."getComponent"[spriteProto];
	this."radius" = sprite."radius";

	(*	Place at left or right border *)
	{x, y} = go."transform"."position";
	If[RandomChoice[{True, False}],
		go."transform"."position" = {w, y};
		sprite."vel" = {-this."speed", 0};
	,
		go."transform"."position" = {0, y};
		sprite."vel" = {this."speed", 0};
	];

	this."startTime" = sm."time";
	this."startx" = (go."transform"."position")[[1]];

	sound = If[this."big", this."game"."assets"."alienSound", this."game"."assets"."smallAlienSound"];
	this."soundObj" = sm."audioMixer"."play"[sound, True];
];

method[proto."update"][] := Module[
	{go, sm, age, vx, vy, pos, vel, u, theta, accuracy},

	go = this."gameObject";
	sm = go."sceneManager";

	(* 	50% chance of changing vertical velocity after each sec *)
	age = sm."time" - this."velChangeTime";
	If[age > 1,
		If[RandomReal[] < 0.5,
			{vx, vy} = this."sprite"."vel";
			If[vy > 0 || vy < 0,
				vy = 0
			,
				vy = RandomChoice[{-1, 1}] this."speed"
			];
			this."sprite"."vel" = {vx, vy};
		];
		this."velChangeTime" = sm."time";

		(*	Fire a bullet. Direction is random for the big alien ship and progressively more accurate for the little one. *)
		pos = go."transform"."position";
		If[this."big" || this."game"."playerShip" === Null,
			theta = RandomReal[{0, 2 Pi}]
		,
			u = this."game"."playerShip"."gameObject"."transform"."position" - pos;	(* Direction vector to player *)
			theta = ArcTan[u[[1]], u[[2]]];
			accuracy = Min[this."game"."score"."score" / this."game"."smallAlienScore", 1];	(* 1 = deadly accurate, 0 = poor accuracy *)
			theta += RandomReal[(1 - accuracy) {-this."smallAngle", this."smallAngle"}]
		];
		vel = (this."game"."bulletVel" + Norm[this."sprite"."vel"]) RotationMatrix[theta].{1,0};
		this."game"."addBullet"[pos, vel, go];
	];

	(*	Detect if sprite horizontally "wrapped" around the screen *)
	age = sm."time" - this."startTime";
	If[age > 2 && Abs[this."startx" - (go."transform"."position")[[1]]] < this."speed",
		this."game"."deleteAlienShip"[];
	];
];

