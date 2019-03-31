include["transform.m"];

(*  gameObjectProto provides a container for components.

	You add behavior to gameObjects by creating custom components and adding them to the gameObject.
	Add the gameObject itself to the sceneManager.

	All gameObjects have a transformProto component by default that provides a local coordinate space for
	components implementing graphicsInerface. transformProto has a "parent" property that may be used
	to contruct hierarchies of gameObjects.

	Properties:
		active		True to enable components on this gameObject (and all its children gameObjects).
		components	List of components attached to this gameObject
					Note: each component will get a "gameObject" and "started" property in the "addComponent"
					method. "gameObject" refers to the gameObject the component is added to, "started" is set
					True after the "start" method is called for components implementing the actorInterface.
*)
proto = makeProto[gameObjectProto, Proto, final, "gameObject"];

gameObjectProto::notAdded = "gameObject has not been added to the sceneManager";

(*  Default properties *)
proto["sceneManager"] = Null;

method[proto."constructor"][] := (
	method[this, super."constructor"][];

	this."components" = {};
	this."active" = True;

	this."transform" = new[transformProto][];
	this."addComponent"[this."transform"];
);

method[proto."destructor"][] := (
	delete /@ (this."components");
	If[this."sceneManager" =!= Null,
		this."sceneManager"."removeGameObject"[this]
	];
	method[this, super."destructor"][];
);

method[proto."addComponent"][component_] := (
	AppendTo[this."components", component];
	component."gameObject" = this;
	component."started" = False;
	component
);

method[proto."removeComponent"][component_] := (
	this."components" = Delete[this."components", component];
	unset[component, "gameObject"];
	unset[component, "started"];
);

(*	Return first component of type 'prototype', or Null if one isn't found *)
method[proto."getComponent"][prototype_] := Module[
	{matching},

	matching = Select[this."components", isa[#, prototype]&];
	If[Length[matching] == 0,
		Null
	,
		matching[[1]]
	]
];
