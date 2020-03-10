#!/usr/bin/env wolframscript

$renderer = "render.m";
$parallel = True;
$nthreads = $ProcessorCount-1;
$movie = True;
$step = 1;
$nframes = Infinity;

$usage = "Usage: ./mathematica_movie.m [opts] <filename>
Options:
 -h            (Print this information)
 -g <header>   (Use given header instead of render.m)
 -p <n>        (Render frames in parallel using n procs)
 -w            (Render frames without making a movie)
 -j <n>        (Render every n frames)
 -n <n>        (Render up to n frames)";

args = Rest[$ScriptCommandLine];
nargs = Length[args];
If[nargs < 1, Print[$usage]; Exit[]];

i = 1;
foundfile = False;
While[i <= nargs,
    With[{arg = args[[i]]},
        If[StringPart[arg,1] === "-",
            (* Parse options *)
            If[StringMatchQ[arg, "-g"|"-p"|"-j"|"-n"],
                (* These options require a second argument *)
                If[i==nargs || StringPart[args[[i+1]],1] === "-",
                    Print[$usage]; Exit[],
                    x = args[[i+1]];
                    i++;
                ]
            ];
            Switch[arg,
                "-g", $renderer = x, (* Render function *)
                "-j", Check[$step     = FromDigits[x], Print[$usage]; Exit[]], (* Step size *)
                "-n", Check[$nframes  = FromDigits[x], Print[$usage]; Exit[]], (* Total frames *)
                "-p", Check[$nthreads = FromDigits[x], Print[$usage]; Exit[]]; (* Threads *)
                      If[$nthreads==0, $parallel = False],
                "-w", $movie = False,
                _, Print[$usage]; Exit[]
            ],
            foundfile = True;
            filespec = arg;
        ];
        i++;
    ]
];
If[!foundfile, Print[$usage]; Exit[]];

(* Parse the filenames *)
If[!DirectoryQ[filespec],
    Print["Data must be specified as a directory."];
    Exit[];
]
basedir  = FileNameJoin[Most[FileNameSplit[filespec]]];
basespec = FileBaseName[filespec];
files = FileNames[All, filespec];
$nframes = Min[$nframes, Length[files]];
ndigits = IntegerLength[$nframes];

(* Create frames directory *)
framedir = FileNameJoin[{basedir, basespec <> ".frames"}];
If[!FileExistsQ[framedir],
    CreateDirectory[framedir]
];

(* Get the plotting definitions *)
If[!FileExistsQ[$renderer],
    Print["Renderer not found."];
    Exit[];
];
SetOptions[$Output, FormatType->OutputForm];
If[TrueQ[$parallel],
    do = ParallelDo;
    LaunchKernels[$nthreads];
    ParallelEvaluate[Get[$renderer]];
    SetSharedFunction[Print],
    do = Do;
    Get[$renderer];
];

(* Render the frames *)
count = 1;
SetSharedVariable[count];
monitor = StringTemplate["printf \r\"Rendering frames... ``%% (`` / ``, `` sec/frame, `` threads)\""];
Run[monitor[0, 0, $nframes, "--", $nthreads]];
do[
    Module[{ii, infile, outfile, image, t},
        ii = StringPadLeft[ToString[i], ndigits, "0"];
        infile  = FileNameJoin[{filespec, basespec <> "." <> ToString[i]}];
        outfile = FileNameJoin[{framedir, basespec <> "_" <> ii}];
        t = First@AbsoluteTiming[ render[infile, outfile]; ];
        Run[monitor[Round[100.*count/$nframes], count, $nframes, NumberForm[t, {Infinity, 2}], $nthreads]];
        count++;
    ],
{i, 0, $nframes-1, $step}];
CloseKernels[];
Print["\n"];

(* Make the movie *)
If[TrueQ[$movie],
    movopts = "-r 24 -y -preset slow -c:v libx265 -crf 17 -vf \"pad=ceil(iw/2)*2:ceil(ih/2)*2\" -pix_fmt yuv420p -tag:v hvc1 -movflags faststart";
    frameformat = FileNameJoin[{framedir, basespec <> "_%" <> ToString[ndigits] <> "d.png"}];
    Run[StringTemplate["ffmpeg -i `` `` ``.mov"][frameformat, movopts, FileNameJoin[{basedir, basespec}]]];
];
