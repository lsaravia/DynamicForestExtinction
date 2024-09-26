breed [birds bird]            ; birds represent a biological species not particularly birds
breed [observers observer]    ; virtual observer

birds-own [ species]          ; Species are identified by a number
patches-own [ degraded
              cluster-label
]

globals [ total-patches
          gr-birds             ; Probability of growth
          mr-birds             ; Probability of migration
          re-birds             ; Probability of Replacement
          powexp               ; power law exponent
  birds-at-deforestation
]

extensions [
  ;table
  ;profiler
  ;vid
]

to setup-ini
  clear-all
  set total-patches count patches
  set-default-shape birds "circle"
  ask patches [
    set degraded false
    set cluster-label 0
  ]
end

;; Sets a random population of patches, if initial-population=1 set 1 individual in one edge at random to allow migration
;;
;;
to setup
  setup-ini
  ask n-of initial-population patches [
    if not degraded [

      sprout-birds 1 [
        let xx 0
        let yy 0
        set size 1
        set species random max-birds-species
        set color scale-color green species ( max-birds-species + 1 ) 0
        if initial-population = 1
        [
          let side random 4
          (ifelse side = 0 [ ; up
            set xx random-pxcor
            set yy max-pycor  ]
            side = 1 [
              set xx random-pxcor
              set yy min-pycor  ]
            side = 2 [
              set xx max-pxcor
              set yy random-pycor   ]
            [
              set xx min-pxcor
              set yy random-pycor
            ]
          )
          setxy xx yy
        ]
      ]
    ]
  ]
  ;if video [
  ;   vid:reset-recorder
  ;   vid:start-recorder
  ;        ; vid:record-interface
  ;   vid:record-view
  ;]

  reset-ticks

end

to go
  if deforestation-at-time != 0  and ticks = deforestation-at-time [
    (ifelse deforestation-type = "regular" [ regular-deforestation ]
      deforestation-type = "random block"  [ block-deforestation]
      deforestation-type = "random"        [ random-deforestation ]
    )
    set birds-at-deforestation count birds
    if migration0-at-deforestation [
      set migration-rate-birds 0
    ]
  ]
  if ticks = end-time [
    ;if video [
    ;    vid:save-recording "MultipleSpeciesNeutralMigrat.mp4"
    ;]
    stop
  ]

  ;;
  ;; Calculate probabilities
  set mr-birds migration-rate-birds / ( death-rate-birds + birth-rate-birds)
  ;; /( death-rate-birds + birth-rate-birds + migration-rate-birds)
  set gr-birds birth-rate-birds /( death-rate-birds + birth-rate-birds)
  ;;print (word "gr-birds:" gr-birds " mr-birds:" mr-birds)

  set re-birds replacement-rate /( death-rate-birds + birth-rate-birds)
  ;;
  ;; calculate power law exponent from dispersal distance, deriving the power exponent of a distribution with mean = birds-dispersal-distance
  ;;
  set powexp (1 - 2 * birds-dispersal-distance ) / (1 - birds-dispersal-distance )
  ;;print word "Power exponent " powexp
  ask patches [ migration-birds-neutral ]
  (ifelse
    birds-behavior = "NoSelection" [
      ask birds [ grow-birds-neutral-no-selection ]
    ]
    birds-behavior = "BirthSelection" [
      ask birds [ grow-birds-neutral]
    ]
    birds-behavior = "Hierarchical" [
      ask birds [ grow-birds-hierarchical]
    ]

  )

  tick
  ;if video [
  ;      ;vid:record-interface
  ;      vid:record-view
  ;]

end

;;
;; Birds select an empty site (if exist) to reproduce and if the site is occupied by species with a lower number
;;
to migration-birds-neutral
  let rnd random-float 1
  let xx 0
  let yy 0

  if rnd < mr-birds
  [
    ;; Migration from one of the edges at random
    let side random 4
    (ifelse side = 0 [ ; up
      set xx random-pxcor
      set yy max-pycor  ]
      side = 1 [
        set xx random-pxcor
        set yy min-pycor  ]
      side = 2 [
        set xx max-pxcor
        set yy random-pycor   ]
      [
        set xx min-pxcor
        set yy random-pycor
      ]
    )
    ;;print (word "rnd:" rnd " xx:" xx " yy:" yy)
    ask patch xx yy
    [
      if not degraded and not any? birds-here
      [ sprout-birds 1
        [ set size 1
          set species random max-birds-species
          set color scale-color green species ( max-birds-species + 1 ) 0
          setxy xx yy
        ]
      ]
    ]
  ]

end
;;
;; Birds search for an empty and not degraded site (if exist) to reproduce inside the dispersal distance
;; given by a power law distribution
;;
to grow-birds-neutral
  let rnd random-float 1
  ifelse rnd > gr-birds
  [ die ]
  [
    let effective-dispersal  random-power-law-distance 1 powexp
    let centerpatch patch-here
    ;;let target max-one-of (patches in-radius effective-dispersal with [not degraded and not any? birds-here]) [distance centerpatch]
    let targets patches in-radius effective-dispersal with [not degraded and not any? birds-here]

    if any? targets [
      let target max-one-of targets [distance centerpatch]
      ;;show (word "in-radius eff-disp " effective-dispersal " - Real distance " distance target)

      hatch-birds 1 [ move-to target ]
    ]
  ]
end

;;
;; Birds select a patch with a power law distance distribution if empty and not degraded site they reproduce
;; they don't search for empty and not degraded sites
;;
to grow-birds-neutral-no-selection
  let rnd random-float 1
  ifelse rnd > gr-birds
  [ die ]
  [
    let effective-dispersal  random-power-law-distance 1 powexp
    let centerpatch patch-here
    let target max-one-of patches in-radius effective-dispersal [distance centerpatch]
    ;;let target one-of patches in-radius effective-dispersal
    ;;show (word "in-radius eff-disp " effective-dispersal " - Real distance " distance target)

    if (not [degraded] of target and not any? birds-on target) [
      hatch-birds 1 [ move-to target ]
    ]
    ;;      let target one-of neighbors4 with [not any? birds-here]
    ;;      if target != nobody [
    ;;        hatch-birds 1 [ move-to target ]

  ]
end

;;
;; Birds select a patch with a power law distance distribution if empty or occupied by a species with number greater than the actual one,  and not degraded site they reproduce
;; they don't search. Thus species with lower numbers replace species with higher numbers.
;;
to grow-birds-hierarchical
  ifelse random-float 1 > gr-birds
  [ die ]
  [
    let effective-dispersal  random-power-law-distance 1 powexp
    let centerpatch patch-here
    ;;print word "Effective dispersal : " effective-dispersal

    let target max-one-of patches in-radius effective-dispersal [distance centerpatch]
    if target != nobody and not [degraded] of target
    [
      ifelse not any? birds-on target [
        hatch-birds 1 [ move-to target ]
      ][
        if [species] of one-of birds-on target > species
        [
          if random-float 1 < re-birds [
            ask birds-on target [die]
            hatch-birds 1 [ move-to target ]
          ]
        ]
      ]
    ]
  ]
end

to-report random-power-law-distance [ xmin alpha ]
  let dis xmin * (random-float 1) ^ (-1 / ( alpha - 1 ))
  if dis > (world-width / 2)  [set dis world-width / 2 ]
  report dis
end

to-report calc-shannon-diversity
  let species-l n-values max-birds-species [i -> i]
  let species-count []
  let total-species count birds
  ;;print total-species
  if total-species > 0 [
    foreach species-l [
      i -> let species-p count birds with [species = i] / total-species
      if species-p > 0 [
        set species-count lput (- species-p * ln species-p  ) species-count
      ]
    ]
  ]
  report sum species-count
  ;;count birds with [species = i]]
end

to-report calc-number-of-species
  let species-l n-values max-birds-species [i -> i]
  let species-count []
  ;;print total-species
  foreach species-l [
    i -> let species-p count birds with [species = i]
    if species-p > 0 [
      set species-count lput 1 species-count
    ]
  ]

  report sum species-count
  ;;count birds with [species = i]
end

to random-deforestation

  ;let width (world-width - 1) * prob-frag / 2
  ;print (word "width " width)
  let degraded-patches prob-frag * world-width * world-height
  ask n-of degraded-patches  patches  [

    set degraded true
    set pcolor magenta
    ask birds-here [die]

  ]

end

;;
;; The habitat is degraded with a regular patch distribution with side size given by `habitat-patch-size` + 1
;; The amount of degraded habitat is given by prob-frag
;;
to regular-deforestation

  let degraded-patches prob-frag * world-width * world-height  ; number of degraded patches
  let h 1 - prob-frag                                      ; Propotion of habitat
  let p habitat-patch-size + 1                         ; Side of the patch

  let n round ( world-width * world-height * h / (p * p ) )          ; Number of patches
  let prow int round sqrt n                                      ; Number of rows of patches
  if prow = 0 [
    Print "error number of rows 0, make patch size smaller!"
    stop ]
  let pos ( world-width -  p * prow ) / prow               ; position of the edge of the patch and distance between patches
;  print (word "Number of patches: " n " Number per row: "  prow  " Position: " pos " Side of patch: " p)

  let pcenter  pos +  habitat-patch-size + 1

  ask patches [ set degraded true ]
  let nearby moore-offsets habitat-patch-size true

  let prange range  n
  let shiftx 0
  let shifty 0

  foreach prange [ x ->
    let xx  x mod prow + 1
    let yy  int ( x / prow ) + 1
;    Center the degraded patches so they don't touch the borders
;
;    let coordx  ( x mod prow ) * pcenter + (pos / 2)
;    let coordy  ( int ( x / prow )  ) * pcenter + (pos / 2)

;    Degraded patches at the left bottom borders allow immigration
;
    let coordx  ( x mod prow ) * pcenter ;- 1
    let coordy  ( int ( x / prow )  ) * pcenter ;- 1

    if coordx >= min-pxcor and coordy >= min-pycor and coordx <= max-pxcor and coordy <= max-pycor  [
    ;print (word "coord y: "  coordy  " coord x: " coordx)

      ask patch coordx coordy [
        ask patches at-points nearby [
          set degraded false
        ]
      ]
    ]
  ]
  ask patches with [degraded ]
      [
        set pcolor magenta
        ask birds-here [die]
      ]
  correct-deforestation degraded-patches
  ;find-clusters
  ;let numcluster max [cluster_no] of patches
  ;let nondegraded  count patches with [ not degraded ]
  ;set habitat-patch-size int  sqrt ( nondegraded / numcluster ) - 1
end

;
; Some corrections are needed fot aproximating to the prob-frag amount of degraded habitat
;
to correct-deforestation [degraded-p]
  loop [
    let num-degraded count patches with [degraded] - degraded-p
    let dif-h ( abs num-degraded ) / total-patches
    if dif-h < 0.01 [
      ;set habitat-patch-size  int ( sqrt  count patches with [ not degraded] )
      stop
    ]
    ;show (word "num-degraded: " num-degraded  " Dif-h: " dif-h)
    if num-degraded  > 0 [
      let edge-degraded patches with [ degraded and any? neighbors with [not degraded] ]
      ;print word "edge-degraded: " edge-degraded
      ask up-to-n-of num-degraded edge-degraded [
        set degraded false
        set pcolor black
      ]
    ]
    if num-degraded < 0 [
      let edge-degraded patches with [ not degraded and any? neighbors with [degraded] ]
      ask up-to-n-of ( abs num-degraded ) edge-degraded [
        set degraded true
        set pcolor magenta
      ]
    ]
  ]
end

;;
;; Degrade the habitat using randomnly located squares with side size given by `habitat-patch-size` + 1
;; The amount of degraded habitat is given by prob-frag
;;
to block-deforestation

  let degraded-patches prob-frag * world-width * world-height
  ask patches [ set degraded true ]

  let nearby moore-offsets habitat-patch-size true

  loop [

    ask one-of patches [
     ask patches at-points nearby [
        set degraded false
      ]
    ]
    let num-degraded count patches with [ degraded ]
    ;print (word "num-degraded:  " num-degraded)
    if num-degraded <= degraded-patches [
      ask patches with [degraded ]
      [
        set pcolor magenta
        ask birds-here [die]
      ]
      correct-deforestation degraded-patches
      stop
    ]
  ]

end


to-report moore-offsets [n include-center?]
  let result [list pxcor pycor] of patches with [abs pxcor <= n and abs pycor <= n]
  ifelse include-center?
    [ report result ]
    [ report remove [0 0] result ]
end


; Calculate the shortest distance from a random point to the border of the patch
; from non-degraded to degraded and from degraded to non-degraded patches
;
to-report mean-free-path

  ; take random positions inside non-degraded habitat patches
  ; and calculate the distance to the border
  let non-degraded-patches patches with [ not degraded ]
  ;print word "Number of non-degraded patches " non-degraded-patches
  ask n-of ( 0.1 * count non-degraded-patches ) non-degraded-patches [
    sprout-observers 1 [ set color black ]
  ]
  let degraded-patches patches with [ degraded]
  if degraded-patches = nobody
      [ report list 0 0 ]

  let distance-to-degraded  []
  ask observers [
    let disdeg distance ( min-one-of degraded-patches [ distance myself ] ) ; This is more efficient than using in-radius
    ;print word "Distance to degraded: " disdeg
    set distance-to-degraded lput  disdeg  distance-to-degraded
  ]
  ;print word "Distance to degraded: " distance-to-degraded
  let mfp-list []
  set mfp-list lput precision mean distance-to-degraded 3 mfp-list
  ask observers [die]

  ;
  ; Calculate the mean-free-path of degraded habitat

  ;set degraded-patches patches with [ degraded ]
  ; print word "Number of degraded patches " degraded-patches
  ask n-of ( 0.1 * count degraded-patches ) degraded-patches [
    sprout-observers 1 [ set color black ]
  ]
  ;set non-degraded-patches patches with [ not degraded]
  set distance-to-degraded  []
  ask observers [
    let disdeg distance ( min-one-of non-degraded-patches [ distance myself ] ) ; This is more efficient than using in-radius
                                                                                ;print word "Distance to degraded: " disdeg
    set distance-to-degraded lput  disdeg  distance-to-degraded
  ]
  ;print word "Distance to non-degraded: " distance-to-degraded
  ask observers [die]
  set mfp-list lput precision mean distance-to-degraded 3 mfp-list

  report mfp-list

end

; Exact mean-free-path a bit slower than the previous
;
to-report exact-mean-free-path
  let non-degraded-patches patches with [ not degraded ]
  let degraded-patches patches with [ degraded ]

  if degraded-patches = nobody [ report list 0 0 ]

  let distance-to-degraded map [p -> [distance (min-one-of degraded-patches [distance myself])] of p] sort non-degraded-patches
  let mfp-list (list precision mean distance-to-degraded 3)

  set distance-to-degraded map [p -> [distance (min-one-of non-degraded-patches [distance myself])] of p] sort degraded-patches
  set mfp-list lput precision mean distance-to-degraded 3 mfp-list

  report mfp-list
end

to-report efective-degraded-proportion
  report count patches with [ degraded ] / total-patches
end

to-report rank-abundance
  let species-list [species] of birds

  let unique-species remove-duplicates species-list
  ;print word "unique-species: " unique-species

  let species-counts map [s -> count birds with [species = s ]] unique-species
  ;print word "species-counts : " species-counts

  let rank-abundance-list sort-by > species-counts


  report rank-abundance-list
end

;
; Hoshen–Kopelman algorithm for non-degraded patches
;
to-report find-cluster-sizes

  let cluster-sizes []
  let non-degraded patches with [ degraded = false] ;
  ;print (word " non-degraded: " non-degraded)
  if any? non-degraded [
    ask non-degraded [ set cluster-label 0 ]
    set non-degraded sort non-degraded                       ; convert agentset to a list
    let largest-label 0

    ;
    ; label clusters
    ;
    foreach non-degraded [
      t -> ask t [

        let pleft patch-at -1 0  ; same row to the left x-1
        let pabove patch-at 0 1  ; same column abobew   y+1
        ifelse  not member? pabove non-degraded and not member? pleft non-degraded [
          ;show "NO neighbor!!!!"

          set largest-label largest-label + 1
          set cluster-label largest-label
        ][
          ifelse member? pleft non-degraded and not member? pabove non-degraded [
            ;show "LEFT neighbor!!!!"
            set cluster-label [cluster-label] of pleft
          ][
            ifelse member? pabove non-degraded and not member? pleft non-degraded [
              ;show "ABOVE neighbor!!!!"
              set cluster-label [cluster-label] of pabove
            ][
              ;show "BOTH neighbors!!!"
              let lblabove [cluster-label] of pabove
              let lblleft  [cluster-label] of pleft
              ifelse lblleft = lblabove [
                set cluster-label lblleft
              ][
                ifelse lblleft < lblabove [
                  set cluster-label lblleft
                  foreach non-degraded [r -> ask r [ if cluster-label = lblabove[ set cluster-label lblleft] ] ]
                ][
                  set cluster-label lblabove
                  foreach non-degraded [r -> ask r [ if cluster-label = lblleft [ set cluster-label lblabove] ] ]
                ]
              ]


            ]
          ]
        ]
      ]
    ]

    ;
    ;
    ;
    set non-degraded patches with [member? self non-degraded]
    let label-list [cluster-label] of non-degraded
    ;print word "label-list: " label-list
    set label-list remove-duplicates label-list
    ;print word "label-list: " label-list

    foreach label-list [
      t -> set cluster-sizes lput count non-degraded with [cluster-label = t] cluster-sizes
    ]
  ]
  report cluster-sizes

end
@#$#@#$#@
GRAPHICS-WINDOW
230
10
738
519
-1
-1
2.5
1
10
1
1
1
0
0
0
1
0
199
0
199
1
1
1
ticks
30.0

SLIDER
20
52
195
85
max-birds-species
max-birds-species
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
20
265
93
298
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
755
10
1033
254
Species Rank-Abundance 
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "set-plot-y-range 0 1\nset-plot-x-range 0 max-birds-species"
PENS
"default" 1.0 1 -16777216 true "" "plot-pen-reset\nlet counts rank-abundance\nforeach counts plot"

SLIDER
20
90
195
123
birth-rate-birds
birth-rate-birds
0
5
2.0
.01
1
NIL
HORIZONTAL

BUTTON
20
305
83
338
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
10
195
43
initial-population
initial-population
0
20000
0.0
100
1
NIL
HORIZONTAL

SLIDER
20
130
195
163
death-rate-birds
death-rate-birds
0
5
1.0
.01
1
NIL
HORIZONTAL

MONITOR
20
350
117
395
lambda birds
(birth-rate-birds) / death-rate-birds
6
1
11

SLIDER
20
170
195
203
migration-rate-birds
migration-rate-birds
0
1
1.0E-4
0.0001
1
NIL
HORIZONTAL

SLIDER
20
210
210
243
birds-dispersal-distance
birds-dispersal-distance
1.01
10
3.0
0.01
1
NIL
HORIZONTAL

PLOT
755
275
1035
520
Total number of individuals
NIL
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13840069 true "" "plot count birds"

PLOT
1045
275
1325
520
Shannon Diversity
NIL
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"H" 1.0 0 -11221820 true "" "plot calc-shannon-diversity"

BUTTON
20
450
212
483
Random Deforestation
random-deforestation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
410
192
443
prob-frag
prob-frag
0
1
0.6
.01
1
NIL
HORIZONTAL

CHOOSER
720
570
867
615
birds-behavior
birds-behavior
"BirthSelection" "NoSelection" "Hierarchical"
1

SWITCH
110
305
213
338
Video
Video
1
1
-1000

SLIDER
720
630
902
663
replacement-rate
replacement-rate
0
5
0.3
0.1
1
NIL
HORIZONTAL

PLOT
1045
10
1325
255
Number of species
NIL
NIL
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot calc-number-of-species"

BUTTON
20
490
192
523
NIL
Block-deforestation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
570
222
603
habitat-patch-size
habitat-patch-size
1
200
3.0
1
1
NIL
HORIZONTAL

BUTTON
20
530
202
563
NIL
regular-deforestation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
15
615
232
660
Efective degraded proportion
efective-degraded-proportion
5
1
11

SLIDER
250
625
457
658
Deforestation-at-time
Deforestation-at-time
0
600
600.0
100
1
NIL
HORIZONTAL

SLIDER
250
675
422
708
end-time
end-time
0
2000
1500.0
100
1
NIL
HORIZONTAL

SWITCH
250
570
502
603
Migration0-at-deforestation
Migration0-at-deforestation
1
1
-1000

CHOOSER
530
570
687
615
deforestation-type
deforestation-type
"random" "random block" "regular"
1

@#$#@#$#@
## WHAT IS IT?

This model is about the dynamics of multispecies communities and the influence of fragmentation.

The model was developed by Leonardo A. Saravia
 
The model description below follows the ODD (Overview, Design concepts, Details) protocol for describing individual- and agent-based models (Grimm et al. 2006, 2010). The model was implemented in NetLogo (Wilensky, 1999), version 6.0.4.

# ODD

## 1. Purpose and patterns

The purpose of this model is to simulate the dynamics of multiple species occupying a landscape that undergoes habitat loss and fragmentation over time. The model allows exploring the effect of different habitat loss patterns, dispersal abilities, and competition mechanisms on species diversity and persistence. 

Key output patterns examined are:
- Species abundance distribution 
- Species diversity (e.g. Shannon index)
- Species occupancy and spatial distribution
- Extinction dynamics

## 2. Entities, state variables, and scales

The model contains the following entities:

**Birds** - the main mobile agents representing individuals of different species. Characterized by the state variables:
- *species* - identity number of the species (0 to max-birds-species)
- *size* - visualization size of the agent  
- *color* - visualization color scaled to the species identity

**Patches** - the spatial units forming the landscape. Characterized by: 
- *degraded* - Boolean indicating if the patch is degraded habitat or not
- *cluster* - agentset identifying which habitat fragment the patch belongs to
- *cluster_no* - patch cluster identity number  

**Globals** - model parameters and global variables

The spatial extent comprises the entire NetLogo world, which can be configured as desired (default is 200 x 200 patches). One time step represents one generation of the birds. Simulations are run for a max time configured by `end-time`

## 3. Process overview and scheduling

The model proceeds in discrete time steps representing single generations. Within each time step, the following actions occur in order:

1. Habitat loss event if the current time matches the configured loss time
2. Calculation of model probabilities for reproduction, dispersal, and replacement
3. Birds disperse stochastically based on assigned dispersal abilities and competition mechanisms
4. Data collection and recording 

The habitat loss event degrades patches according to one of three specified spatial patterns. Dispersal follows either neutral dynamics or a hierarchical competition mechanism. State variables are updated asynchronously as dispersal moves birds across the landscape.

The scheduling pseudo-code is:

```
Initialize landscape and bird populations
  
While time < end-time:

  If time = habitat loss time
    Degrade habitat patches 
  
  Calculate model probability parameters
  
  Ask patches:
    Perform probabilistic migration of birds into patch if empty
    
  Ask birds:  
    Hatch new bird in probability based on:
      - neutral dispersal  
      - hierarchy-based replacement of lower ranked species
      
    Die with configured probability
  
Collect data on model variables
  
Increment time step
```

## 4. Design concepts

**Basic principles** - The model explores two alternative hypotheses on how species divide resources: (1) neutral dynamics where species are functionally equivalent, vs (2) hierarchical competition where superior species can displace inferior ones.

**Emergence** - The spatial distribution, diversity, and abundance patterns of species emerge from the probabilistic behaviors of reproduction, dispersal, migration, and competition between individual birds.

**Adaptation** - Birds do not adapt. Their behaviors are fixed based on model configuration.

**Objectives** - Birds aim to reproduce based on fixed probabilities. They do not have explicit fitness objectives.

**Learning** - Birds do not learn.

**Prediction** - Birds do not predict future conditions. 

**Sensing** - Birds sense the occupancy of patches in their local dispersal neighborhood. With the hierarchical competition mode, they also sense the identity of other bird species present when dispersing.

**Interaction** - Birds interact by competing for space. The neutral model has equal competitive ability. The hierarchy model allows species replacement according to rank order.

**Stochasticity** - Stochasticity is implemented in multiple processes:
- Initial population placement
- Habitat loss pattern
- Dispersal distance 
- Reproduction
- Migration
- Species selection (with hierarchy)

**Collectives** - Birds do not form collectives. Patches self-organize into habitat clusters.

**Observation** - The following are recorded at each time step:
- Species abundance distribution
- Species diversity (Shannon index)
- Number of species
- Spatial distribution of birds 

## 5. Initialization

At initialization, the landscape is entirely suitable habitat. An initial number of birds are placed randomly across the landscape. Their species identity numbers are assigned randomly from 0 to the configured max unique species.

If starting with 1 individual, it is placed randomly on one edge of the world to allow immigration.

## 6. Input data

The model does not use input data from external sources.

## 7. Submodels

**Habitat loss** - Habitat patches are degraded probabilistically according to one of three spatial patterns:
1. Random loss placing magenta degraded patches randomly across the landscape.
2. Regular loss generating a fragmented landscape with regular pattern of degraded patches. 
3. Block loss using randomized squares of degraded patches.


The total amount of degradation is set by the *prob-frag* parameter. To reach an exact amount of habitat loss random habitat sites around squares of habitat patches is added if needed. 

**Dispersal** - Birds reproduce probabilistically based on fixed rates. Offspring disperse locally based on a power law distribution with an exponent chosen to match the mean dispersal distance set by the *birds-dispersal-distance* parameter. 

With neutral dynamics, they settle in any empty non-degraded patches within dispersal range. With hierarchy, they also displace resident birds of lower rank species.

**Migration** - Immigration from outside is implemented by spontaneous appearance of birds at patch edges with a fixed probability.

**Data collection** - At each time step, the model records:

- Species abundance distribution
- Shannon diversity index
- Number of unique species 
- Spatial distribution of birds

## 8. References

The model was originally described in: 

Saravia, L. A., & Momo, F. R. (2018). Biodiversity collapse and early warning indicators in a spatial phase transition between neutral and niche communities. Oikos, 127(1), 111–124. https://doi.org/10.1111/oik.04256
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower budding
false
0
Polygon -7500403 true true 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Polygon -7500403 true true 189 233 219 188 249 173 279 188 234 218
Polygon -7500403 true true 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 180 150 180 120 165 97 135 84 128 121 147 148 165 165
Polygon -7500403 true true 170 155 131 163 175 167 196 136

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="BirthSelection_pf06_hpf3-59_dd1-3" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoSelection_pf06_hpf3-59_dd1-3" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Hierarchical_pf06_hpf3-59_dd1-3" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;Hierarchical&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoHiBi_pf06_hpf3-61_dd1-3_lambda2_Migrat" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
      <value value="&quot;Hierarchical&quot;"/>
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoSelection_pf06_hpf3-59_dd1-3_lambda2" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoHiBi_pf00_hpf3_dd1-3_lambda1.7-4" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="1.7"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
      <value value="&quot;Hierarchical&quot;"/>
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Hierarchical_pf06_hpf3-59_dd1-3_lambda2" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;Hierarchical&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoHiBi_pf06_hpf3-61_dd1-3_lambda2_NoMigrat" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
      <value value="&quot;Hierarchical&quot;"/>
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoHiBi_pf06_hpf3-61_dd1-3_lambda4_Migrat" repetitions="15" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
      <value value="&quot;Hierarchical&quot;"/>
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="29"/>
      <value value="61"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoHiBi_200_pf06_hpf3-61_dd1-3_lambda2_NoMigrat" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="world-width">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
      <value value="&quot;Hierarchical&quot;"/>
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
      <value value="9"/>
      <value value="30"/>
      <value value="62"/>
      <value value="125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoHiBi_pf00_hpf3_dd1-3_lambda1.1-4" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>birds-at-deforestation</metric>
    <metric>calc-number-of-species</metric>
    <metric>calc-shannon-diversity</metric>
    <metric>count birds</metric>
    <enumeratedValueSet variable="world-width">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="1.1"/>
      <value value="1.5"/>
      <value value="1.7"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
      <value value="&quot;Hierarchical&quot;"/>
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="1600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="birds-dispersal-distance">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="migration-rate-birds">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Migration0-at-deforestation">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-birds-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Deforestation-at-time">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-frag">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-birds">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Video">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="end-time">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-patch-size">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deforestation-type">
      <value value="&quot;regular&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="replacement-rate">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
