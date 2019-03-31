(*	staticGraphicsProto component renders static graphics.
*)
proto = makeProto[staticGraphicsProto, Proto, "staticGraphics"];

method[proto."constructor"][graphics_, type_ : "<none>", radius_ : 0] := (
	method[this, super."constructor"][];
	{this."graphics", this."type", this."radius"} = {graphics, type, radius};
);

(*  graphicsInterface *)
method[proto."getGraphics"][] := (
	this."graphics"
);

