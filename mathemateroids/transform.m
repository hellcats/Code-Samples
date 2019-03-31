(*  transformProto transforms Graphics returned from the 'getGraphics' method. Graphical hierarchies are supported.

	Game objects with a transformProto component automatically apply a geometric transformation to the result
	of their 'getGraphics' method. The transformation is composed of a scale, followed by rotation, and then
	translation. Every gameObject gets a transform component.

	Properties:
		scale       Uniform scale factor (default 1.0)
		rotation    Current rotation angle (default 0.0)
		position	Current translation amount (default {0, 0})
		parent      The parent transform (or Null if there isn't one)
*)

proto = makeProto[transformProto, Proto, "transform"];

(*	Default property values *)
proto["scale"] = 1;
proto["rotation"] = 0;
proto["position"] = {0, 0};
proto["parent"] = Null;

method[proto."getTransformations"][] := Module[
	{p, xforms = {}},

	For[p = this, p =!= Null, p = p."parent",
		If[p."position" != {0, 0},
			xforms = {xforms, TranslationTransform[p."position"]}];
		If[p."rotation" != 0,
			xforms = {xforms, RotationTransform[p."rotation"]}];
		If[p."scale" != 1,
			xforms = {xforms, ScalingTransform[{p."scale", p."scale"}]}];
	];

	Flatten @ xforms
];

(*	Return unit-length global vector of the local y-axis *)
method[proto."getYAxis"][] := Module[
	{p, rotation = 0},

	For[p = this."gameObject"."transform", p =!= Null, p = p."parent",
		rotation += this."rotation";
	];

	{-Sin[rotation], Cos[rotation]}
];


