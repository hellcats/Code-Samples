proto = makeProto[audioMixerProto, Proto, "audioMixer"];

proto["freq"] = 8000;
proto["enabled"] = True;
proto["bufferSecs"] = 0.10;
proto["bufferSize"] = Round[proto["bufferSecs"] proto["freq"]];	(* Number of samples in play-ahead buffer *)
proto["bufferSecs"] = proto["bufferSize"]/proto["freq"];		(* Ensure bufferSecs is rational *)

method[proto."constructor"][sceneManager_] := (
	method[this, super."constructor"][];

	this."sceneManager" = sceneManager;
	this."playing" = {};		(* List of currently playing sounds. {{sound, index}, ...} *)
	this."timeToEmpty" = 0;		(* How many secs before emitted sound buffer is empty *)

	(*	Emit next buffer after component updates (group 100) *)
	sceneManager."updateSignal"."connect"[this."update$", 150];
);

(*	Construct a Sound[] object from a list of amplitude samples at the default sampling freq. *)
method[proto."makeSoundFromSamples"][samples_] := Sound[SampledSoundList[{samples}, this."freq"]];

(*	Add a Sound to the list of currently playing samples.
	All sounds are mixed and played simultaneously.

	Return: object reference to the sound while it is playing that may be passed to "stop"
*)
method[proto."play"][sound_, looping_ : False] := Module[
	{obj},

	obj = this."makeSoundObj$"[sound, looping];
	AppendTo[this."playing", obj];
	obj
];

(*	Add or change the sound to be played after the currently playing sound p.
	The sound will be played immediately if p isn't currently playing.
*)
method[proto."playAfter"][p_, sound_, looping_ : False] := Module[
	{obj},

	obj = this."makeSoundObj$"[sound, looping];
	If[isa[p, Proto],
		p."playNext" = obj
	,
		AppendTo[this."playing", obj]		(* Start playing immmediately if p isn't currently playing *)
	];
	obj
];

(*	Stop playing the sound referenced by 'obj' (previously returned from the "play" method) *)
method[proto."stop"][obj_] := (
	If[isa[obj, Proto],
		this."playing" = DeleteCases[this."playing", obj];
		delete[obj]
	];
);

method[proto."makeSoundObj$"][samples_, looping_] := Module[
	{obj},

	obj = new[Proto][];
	obj."samples" = samples;
	obj."index" = 1;				(* Next sample to emit *)
	obj."playNext" = If[looping, obj, Null];
	obj
];

method[proto."update$"][] := Module[
	{dt, buf},

	dt = this."sceneManager"."deltaTime";
	this."timeToEmpty" -= dt;
	If[this."timeToEmpty" <= this."bufferSecs",
		(*	Check if buffer emptied out *)
		If[this."timeToEmpty" < 0,
			this."timeToEmpty" = 0;
		];

		buf = this."buildBuffer$"[];
		If[this."enabled",
			EmitSound[this."makeSoundFromSamples"[buf]]
		];

		this."timeToEmpty" += this."bufferSecs";
	];
];

method[proto."buildBuffer$"][] := Module[
	{i,j,k, n, buf, bufSize, len, samples, obj, next, playing},

	bufSize = this."bufferSize";
	buf = ConstantArray[0., bufSize];

	playing = {};	(* New playing list *)
	Do[
		obj = (this."playing")[[it]];
		{samples, i, next} = obj /@ {"samples", "index", "playNext"};
		len = Length[samples];

		k = 1;	(* Index into buffer for next sample *)
		While[isa[obj, Proto] && k <= bufSize,
			If[next === obj,
				While[k <= bufSize,
					n = len - (i-1);
					n = Min[n, bufSize - (k-1)];
					j = i+n-1;
					buf[[k;;k+n-1]] += samples[[i;;j]];
					i = Mod[i+n, len, 1];		(* Index into samples *)
					k += n;
				];
				obj."index" = Mod[j+1, len, 1];
				playing = {playing, obj};
				obj = Null
			,
				n = len - (i-1);				(* Number of samples to emit *)
				n = Min[n, bufSize - (k-1)];	(* Clamp to bufSize *)
				j = i+n-1;						(* Index of last sample to emit *)
				buf[[k;;k+n-1]] += samples[[i;;j]];
				k += n;
				If[j < len,
					obj."index" = j+1;
					playing = {playing, obj};
					obj = Null;
				,
					delete[obj];
					obj = next;
					If[obj =!= Null,
						{samples, i, next} = obj /@ {"samples", "index", "playNext"};
						len = Length[samples];
						If[k > bufSize,
							playing = {playing, obj}
						]
					]
				]
			]
		]
	,{it, Length[this."playing"]}];
	this."playing" = Flatten[playing];

	Clip[buf]	(* Clip to range [-1, 1] *)
];
