breed [forest one-forest] ; forest patches
breed [bushes bush]        ; living bushes

globals [ total-patches   ; Measure the total number of patches
          cumul-bushes-list   ; List to calculate the average of bush proportion
          gr-forest
          gr-bushes
          powexp               ; power law exponent
        ]

;extensions [profiler]

to setup-ini
  clear-all
  set total-patches count patches
  set-default-shape bushes "circle"
  set-default-shape forest "circle"
  set cumul-bushes-list []
end

to setup
  setup-ini
  let bush-or-forest true
  let ini-f int initial-population * initial-forest-proportion
  let ini-b initial-population - ini-f

  ask n-of ini-f patches [
    sprout-forest 1 [ set color green set size 1]
  ]
  ask n-of ini-b patches [
    sprout-bushes 1 [ set color white set size .7]
  ]

  reset-ticks
end


to setup-full
  setup-ini
  let bush-or-forest true
  ask patches[
    ifelse bush-or-forest  [
      sprout-forest 1 [set color green set size 1]
      set bush-or-forest false
    ][
      sprout-bushes 1 [ set color white set size .7]
      set bush-or-forest true
    ]
  ]
  reset-ticks
end


to setup-center
  setup-ini
  let bush-or-forest true
  ask patches with [(abs pycor < 6) and (abs pxcor < 6)]
  [
    ifelse bush-or-forest  [
      sprout-forest 1 [set color green set size 1]
      set bush-or-forest false
    ][
      sprout-bushes 1 [ set color white set size .7]
      set bush-or-forest true
    ]
  ]
  reset-ticks
end

to go

  ;; updates the probabilities of growth
  set gr-forest birth-rate-forest /( death-rate-forest + birth-rate-forest )
  set gr-bushes birth-rate-bushes /(  death-rate-bushes + birth-rate-bushes )
  ;;
  ;; calculate power law exponent from dispersal distance, deriving the power exponent of a distribution with mean = bushes-dispersal-distance
  ;;
  set powexp (1 - 2 * forest-dispersal-distance ) / (1 - forest-dispersal-distance )
  let powexp-bushes (1 - 2 * bushes-dispersal-distance ) / (1 - bushes-dispersal-distance )
  ; print word "Power exponent " powexp


  ; event type, but then store those numbers in variables with clear names for readability.
  let grow-forest-event 0
  let grow-bushes-event 1

  let repetitions count patches / 2 ; At default settings, there will be an average of 1 event per patch.
                                    ; SHOULD BE PER TURTLE but per patch seems to be faster
  let events shuffle (sentence
    n-values random-poisson (repetitions * gr-forest)      [ grow-forest-event ]
    n-values random-poisson (repetitions * gr-bushes) [ grow-bushes-event ]
  )


  foreach events [ event ->

    if event = grow-forest-event [

      let target one-of forest
      ;show (word "bush target: " target)
      if target != nobody [
        ask target [ grow-forest ]
      ]
    ]
    if event = grow-bushes-event  [
      let target one-of bushes
      ;show (word "bush target: " target)
      if target != nobody [
        ask target [ grow-bushes powexp-bushes]
      ]
    ]
  ]




  ;calc-bushes-mean

  tick
  if habitat-proportion = 0 [stop]
  if (check-bushes-extinction = true) and (bushes-proportion = 0) [stop]

end

to grow-forest
  ifelse random-float 1 > gr-forest
  [
    ;show "1 forest died"
    die
  ]
  [
    let effective-dispersal  random-power-law-distance 1 powexp
    let centerpatch patch-here

    ask max-one-of patches in-radius effective-dispersal [distance centerpatch][
      ;;show (word "in-radius eff-disp " effective-dispersal " - Real distance " distance centerpatch)
      if not any? bushes-here and not any? forest-here [
         sprout-forest 1 [set color green set size 1]

      ]
    ]
  ]
end

;;
;; bushes procedure: if newborns select a suitable patch if exist
;;
to grow-bushes [powexponent]
  ifelse random-float 1 > gr-bushes
  [ die ]
  [
    let effective-dispersal random-power-law-distance 1 powexponent
    let centerpatch patch-here

    ask max-one-of patches in-radius effective-dispersal [distance centerpatch][
      if not any? bushes-here and not any? forest-here [
        sprout-bushes 1 [ set color white set size .7 ]
      ]
    ]
  ]
end


to-report habitat-proportion
  report count forest / total-patches
end


to-report bushes-proportion
  ;print "Calculate bushes proportion"
  report count bushes / total-patches
end

to-report calc-bushes-mean
  ;if empty? cumul-bushes-list
  ;; drop the first member of the list, but not until there are at least 100 items in the list
  if (length cumul-bushes-list > 200) [ set cumul-bushes-list but-first cumul-bushes-list ]

  ;; add the number of bushes-proportion in last tick to the end of the list
  set cumul-bushes-list lput bushes-proportion cumul-bushes-list
  report mean cumul-bushes-list
end

to-report random-power-law-distance [ xmin alpha ]
  ; median = xmin 2 ^( 1 / alpha )
  let dis xmin * (random-float 1) ^ (-1 / ( alpha - 1 ))
  if dis > world-width [set dis world-width]
  report dis
end
@#$#@#$#@
GRAPHICS-WINDOW
240
10
753
524
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
1
1
1
ticks
30.0

BUTTON
15
100
110
133
setup
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

BUTTON
119
139
214
172
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
0

MONITOR
765
170
940
215
Proportion of forest patches
habitat-proportion
6
1
11

SLIDER
16
15
193
48
initial-population
initial-population
0
10000
5000.0
10
1
NIL
HORIZONTAL

SLIDER
17
185
189
218
birth-rate-forest
birth-rate-forest
0
5
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
17
227
189
260
death-rate-forest
death-rate-forest
0
5
0.2
.01
1
NIL
HORIZONTAL

MONITOR
20
325
129
370
Lambda forest
birth-rate-forest / death-rate-forest
6
1
11

BUTTON
17
139
110
172
NIL
setup-full
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
118
100
215
133
NIL
setup-center
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
765
23
937
56
birth-rate-bushes
birth-rate-bushes
0
5
1.0
.01
1
NIL
HORIZONTAL

SLIDER
766
64
938
97
death-rate-bushes
death-rate-bushes
0
5
0.2
0.01
1
NIL
HORIZONTAL

MONITOR
765
224
938
269
Proportion of bushes
count bushes / total-patches
6
1
11

MONITOR
762
121
862
166
lambda bushes
birth-rate-bushes / death-rate-bushes
6
1
11

SWITCH
16
384
215
417
check-bushes-extinction
check-bushes-extinction
1
1
-1000

PLOT
764
297
1013
477
Populations Numbers
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
"default" 1.0 0 -13840069 true "" "plot count forest "
"pen-1" 1.0 0 -1184463 true "" "plot count bushes "

SLIDER
944
23
1136
56
bushes-dispersal-distance
bushes-dispersal-distance
1.01
10
1.01
0.01
1
NIL
HORIZONTAL

SLIDER
18
270
188
303
forest-dispersal-distance
forest-dispersal-distance
1.01
10
1.01
0.01
1
NIL
HORIZONTAL

SLIDER
15
55
232
88
initial-forest-proportion
initial-forest-proportion
0
1
0.5
.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is a model that explores the population dynamics of two species (bushes and forest) that lives in fixed area and compete by space, once the settle in a site neither of species can replace the other until it dies an leave the site empty.

## HOW IT WORKS

Then bushes can reproduce only within the forest but survive equally outside the forest. The population of forest and bushes have the same dynamics, they have a birth rate and a death rate. The birth of a new patch of forest is produced in the four closest neighbours if there is an empty site, the birth of a new bush is produced when there is an empty forest site in the 4 neighbours. 

We are assuming that a patch of forest is equivalent to the movement range of bushes and that bushes do not seek for a new forest patch if the forest where they live dies.  

We can calculate the relation between birth-rate-forest and death rate which is called lambda, so we have a lambda for forest and a lambda for bushes. The question is: for which lambda-forest the bushes survive and which lambda-bushes is needed? Is there an interaction between lambda-forest and lambda-bushes?

This is related to the fragmentation of the forest, when lambda-forest reaches a particular value the forest is not continuous but it is composed of fragments, the bushes population it is confined inside these fragments and becomes fragmented so the bushes get extinct, this is called the critical value, for each lambda-bushes the critical lambda-forest could be determined and vice-versa for each lambda-bushes there is a critical lambda-forest. 

We have two types of agents bushes which are turtles and forest which are patches. Both have two properties:  a birth-rate and a death-rate

We have a 2-dimensional discrete spatial environment defined by the NetLogo view.

Then the two types of agents have two actions, they can give birth to another individual and they can die. They die a constant rate regardless they position in the space, but they need an empty place in its four neighborhoods to give birth a new organism, additionally, the bushes need that a forest patch that is not occupied by another bush, then only one bush per patch is allowed. 

There are three types of bushes behavior, 
1) NoSelection: bushes select a neighbor patch at random then if the patch is forest and empty they reproduce a new bush 
2) BirthSelection: bushes select a forest neighbor patch at random then if the patch is  empty they reproduce a new bush, so here parents are selecting a forest patch for its newborn.
3) AdultSelection: bushes have BirthSelection but additionally they move to a forest patch if the place were they are is a no-forest patch, this is possible because the forest where they live can die.

We first evaluate the events for the forest, and then we evaluate the events for the bushes. For this we calculate the probability of forest birth relative to the total rate of forest events this is: birth-rate-forest / ( death-rate-forest + birth-rate-forest ).  And the probability of bushes births in the same way: birth-rate-bushes /( death-rate-bushes + birth-rate-bushes ) 

Thus, what we measure as output is the proportion of forest alive, and the proportion of bushes alive. 


## HOW TO USE IT

You need to seed an initial populations of forest and bushes, this is to set the inital conditions to run the model.

There are different ways to set the initial conditions of the model:

 1) The setup button puts in random positions a number of forest with one bush inside, controlled by the slider initial-population.

 2) The setup-center button puts in the center of the view a square of 11 x 11 patches of forests with one bush.

 3) The setup-full button fills all the view with forest and bushes.

Then we need to set the death-rate-forest and birth-rate-forest sliders that control the forest rates, and the death-rate-bushes birth-rate-bushes sliders that control the bushes. 

Then the go button runs the model

The lambda-forest is birth-rate-forest/death-rate-forest, this has to be greater than 1 for the forest to survive (how much greater?)

The lambda-bushes is birth-rate-bushes/death-rate-bushes, this has to be greater than 1, and probably greater than lambda-forest for the bushes to survive (how much greater?)
 
The proportion of forest patches is the number of forest patches divided by the total number of patches in the view, and the proportion of bushes is the number of bushes divided by the total number of patches.

The plot shows in green the number of forest patches and in yellow the number of bushes

## THINGS TO NOTICE

Starting the model with setup-full is better if you want to know the equilibrium of both populations, and starting with setup-center is better if you want to know if the population get extinct or not.

The different bushes' behavior produce different critical survival values, if the critical values are lower the bushes have more probability of survive when its habitat declines.

## THINGS TO TRY

You can start modelling a population of forest and bushes that survive, i.e. both lambda-forest and lambda-bushes greater than 2, and then move the birth-rate-forest slider down to observe when the bushes population gets extinct.

## EXTENDING THE MODEL

Deforestation could be added, one way to simulate deforestation is increase the death-rate-forest of the forest but the patterns of deforestation produced by humans are very different from random patterns (because mortality is random). Generally, the deforested zones are used for agriculture/livestock and they need roads to transport the harvest. These roads are straight lines with ramifications at 90 degrees and then square parcels with plantations. So, one interesting extension of this model is to add a sub-model for deforestation.

Another extension is that bushes could try to search for a new empty forest patch if the one where they live dies. 

bushes and forest can have a greater dispersal distance than the 4 neighbours patches, using 'in-radius' and a couple of sliders we can investigate the influence of the dispersal distance in the critical values for extinction.

## RELATED MODELS

The voter model is related to this model

## CREDITS AND REFERENCES

MIT License

Copyright (c) 2019  Leonardo A. Saravia

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="CriticalValueBirds1.5-3forest1.5-3_w101_birthSel" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-center</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>habitat-proportion</metric>
    <metric>birds-proportion</metric>
    <enumeratedValueSet variable="world-width">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="101"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-birds" first="1.5" step="0.01" last="3"/>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-forest">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-forest" first="1.5" step="0.01" last="3"/>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CriticalValueBirds1.5-3forest1.5-3_w201_birthSel" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-center</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>habitat-proportion</metric>
    <metric>birds-proportion</metric>
    <enumeratedValueSet variable="world-width">
      <value value="201"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="201"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-birds" first="1.5" step="0.01" last="3"/>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-forest">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-forest" first="1.5" step="0.01" last="3"/>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CriticalValueBirds2.5-4.5forest2.5-4.5_w51_noSel" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-center</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>habitat-proportion</metric>
    <metric>birds-proportion</metric>
    <enumeratedValueSet variable="world-width">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="51"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-birds" first="2.5" step="0.01" last="4.5"/>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-forest">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-forest" first="2.5" step="0.01" last="4.5"/>
  </experiment>
  <experiment name="CriticalValueBirds1.2-2forest3-4.5_w101_adSel" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-center</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>habitat-proportion</metric>
    <metric>birds-proportion</metric>
    <enumeratedValueSet variable="world-width">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="101"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-birds" first="1.2" step="0.01" last="2"/>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-forest">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-forest" first="3" step="0.01" last="4.5"/>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;AdultSelection&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CriticalValueBirds1.2-3forest1.2-3_w101_birthSel" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-center</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>habitat-proportion</metric>
    <metric>birds-proportion</metric>
    <enumeratedValueSet variable="world-width">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="101"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-birds" first="1.2" step="0.01" last="3"/>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-forest">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-forest" first="1.2" step="0.01" last="3"/>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;BirthSelection&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CriticalValueBirds2.5-4.5forest2.5-4.5_w101_noSel" repetitions="5" runMetricsEveryStep="false">
    <setup>setup-center</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>habitat-proportion</metric>
    <metric>birds-proportion</metric>
    <enumeratedValueSet variable="world-width">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="world-height">
      <value value="101"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-birds" first="2.5" step="0.01" last="4.5"/>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-forest">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-forest" first="2.5" step="0.01" last="4.5"/>
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
