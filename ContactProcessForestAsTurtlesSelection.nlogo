breed [forest one-forest] ; forest patches
breed [birds bird]        ; living birds

globals [ total-patches   ; Measure the total number of patches
          cumul-birds-list   ; List to calculate the average of bird proportion
          gr-forest
          gr-birds
        ]

to setup-ini
  clear-all
  set total-patches count patches
  set-default-shape birds "circle"
  set-default-shape forest "circle"
  set cumul-birds-list []
end

to setup
  setup-ini

  ask n-of initial-population patches [
    sprout-forest 1 [set color green set size 1]
    sprout-birds 1 [ set color white set size .7]
  ]
  reset-ticks
end


to setup-full
  setup-ini
  ask patches[
      sprout-forest 1 [set color green set size 1]
      sprout-birds 1 [ set color white set size .7]
  ]
  reset-ticks
end


to setup-center
  setup-ini
  ask patches with [(abs pycor < 6) and (abs pxcor < 6)]
  [
    sprout-forest 1 [set color green set size 1]
    sprout-birds 1 [ set color white set size .7]
  ]
  reset-ticks
end

to go
  ;; updates the probabilities of growth
  set gr-forest birth-rate-forest /( death-rate-forest + birth-rate-forest )
  set gr-birds birth-rate-birds /( death-rate-birds + birth-rate-birds )

  ask forest [ grow-forest ]
  (ifelse
    birds-behavior = "NoSelection" [
      ask birds [ grow-birds-no-selection ]
    ]
    birds-behavior = "BirthSelection" [
      ask birds [ grow-birds ]
    ]
    birds-behavior = "AdultSelection" [
      ask birds [ grow-birds-adult-selection ]
    ]

  )
  ;calc-birds-mean

  tick
  if habitat-proportion = 0 [stop]
  if (check-birds-extinction = true) and (birds-proportion = 0) [stop]

end

to grow-forest
  ifelse random-float 1 > gr-forest
  [
    ;show "1 forest died"
    die
  ]
  [
    ask one-of neighbors4 [
      if not any? forest-here [
         sprout-forest 1 [set color green set size 1]

      ]
    ]
  ]
end

;;
;; birds procedure: if newborns select a suitable patch if exist
;;
to grow-birds
  ifelse random-float 1 > gr-birds
    [ die ]
    [
      if any? forest-here [

          let target one-of neighbors4 with [any? forest-here  and not any? birds-here]
          if target != nobody [
            hatch-birds 1 [ move-to target ]
          ]
      ]
    ]
end

;;
;; Birds procedure: birds select at random a patch to newborns
;;
to grow-birds-no-selection
  ifelse random-float 1 > gr-birds
    [ die ]
    [
      if any? forest-here [

        let target one-of neighbors4
        if (any? forest-on target and not any? birds-on target) [
          hatch-birds 1 [ move-to target ]
        ]

      ]
    ]
end

;;
;; Birds select a suitable patch for newborns and if the forest dies they select a new forest patch
;;
to grow-birds-adult-selection
  ifelse random-float 1 > gr-birds
    [ die ]
    [
      ifelse any? forest-here [

        let target one-of neighbors4 with [any? forest-here  and not any? birds-here]
        if target != nobody [
          hatch-birds 1 [ move-to target ]
        ]
      ]
      [
        ;;show (word "Se va a mover" pxcor pycor)
        let target one-of neighbors4 with [any? forest-here and not any? birds-here]
          if target != nobody [
            move-to target
            ;; show (word "se movio!!!!!!!!"  pxcor pycor)
          ]
      ]
    ]
end


to-report habitat-proportion
  report count forest / total-patches
end


to-report birds-proportion
  ;print "Calculate birds proportion"
  report count birds / total-patches
end

to calc-birds-mean
  ;if empty? cumul-birds-list
  ;; drop the first member of the list, but not until there are at least 100 items in the list
  if (length cumul-birds-list > 200) [ set cumul-birds-list but-first cumul-birds-list ]

  ;; add the number of birds-proportion in last tick to the end of the list
  set cumul-birds-list lput birds-proportion cumul-birds-list

end

to-report check-birds-steady-state
  if ticks > 500 [

    let up-birds mean cumul-birds-list + (  standard-deviation cumul-birds-list )
    let down-birds mean cumul-birds-list - ( standard-deviation cumul-birds-list )

    if birds-proportion > down-birds and birds-proportion < up-birds
    [ report true ]
  ]
  report false
end
@#$#@#$#@
GRAPHICS-WINDOW
231
10
744
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
17
55
112
88
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
121
94
216
127
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
761
186
936
231
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
1
10001
2411.0
10
1
NIL
HORIZONTAL

SLIDER
19
140
191
173
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
19
182
191
215
death-rate-forest
death-rate-forest
0
5
0.4
.1
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
19
94
112
127
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
120
55
217
88
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
761
39
933
72
birth-rate-birds
birth-rate-birds
0
5
5.0
.01
1
NIL
HORIZONTAL

SLIDER
762
80
934
113
death-rate-birds
death-rate-birds
0
5
1.0
0.1
1
NIL
HORIZONTAL

MONITOR
761
240
934
285
Proportion of birds
count birds / total-patches
6
1
11

MONITOR
762
121
862
166
lambda birds
birth-rate-birds / death-rate-birds
6
1
11

SWITCH
16
384
215
417
check-birds-extinction
check-birds-extinction
1
1
-1000

PLOT
760
313
1009
493
Populations Numbers
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
"default" 1.0 0 -13840069 true "" "plot count forest"
"pen-1" 1.0 0 -1184463 true "" "plot count birds "

BUTTON
20
430
134
463
Run profiler
\nsetup-center\nprofiler:start\nrepeat 1000 [go]\nprofiler:stop          ;; stop profiling\nprint profiler:report  ;; view the results\nprofiler:reset         ;; clear the data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
940
80
1092
125
birds-behavior
birds-behavior
"NoSelection" "BirthSelection" "AdultSelection"
0

@#$#@#$#@
## WHAT IS IT?

This is a model that explores how is the population dynamics of a species (birds) that lives in a dynamical habitat (forest), and how fragmentation or loss of habitat can influence the extinction of the species that lives within it. I call the habitat forest and birds are the organisms that live inside the forest. Then birds can reproduce only within the forest but survive equally outside the forest. The population of forest and birds have the same dynamics, they have a birth rate and a death rate. The birth of a new patch of forest is produced in the four closest neighbours if there is an empty site, the birth of a new bird is produced when there is an empty forest site in the 4 neighbours. We are assuming that a patch of forest is equivalent to the movement range of birds and that birds do not seek for a new forest patch if the forest where they live dies.  

We can calculate the relation between birth-rate-forest and death rate which is called lambda, so we have a lambda for forest and a lambda for birds. The question is: for which lambda-forest the birds survive and which lambda-birds is needed? Is there an interaction between lambda-forest and lambda-birds?

This is related to the fragmentation of the forest, when lambda-forest reaches a particular value the forest is not continuous but it is composed of fragments, the birds population it is confined inside these fragments and becomes fragmented so the birds get extinct, this is called the critical value, for each lambda-birds the critical lambda-forest could be determined and vice-versa for each lambda-birds there is a critical lambda-forest. 

## HOW IT WORKS

We have two types of agents birds which are turtles and forest which are patches. Both have two properties:  a birth-rate and a death-rate

We have a 2-dimensional discrete spatial environment defined by the NetLogo view.

Then the two types of agents have two actions, they can give birth to another individual and they can die. They die a constant rate regardless they position in the space, but they need an empty place in its four neighborhoods to give birth a new organism, additionally, the birds need that a forest patch that is not occupied by another bird, then only one bird per patch is allowed. The birds select the patch that is empty from the neighbors, but the forest select a patch at random and then if it is empty a new forest grows.

We first evaluate the events for the forest, and then we evaluate the events for the birds. For this we calculate the probability of forest birth relative to the total rate of forest events this is: birth-rate-forest / ( death-rate-forest + birth-rate-forest ).  And the probability of birds births in the same way: birth-rate-birds /( death-rate-birds + birth-rate-birds ) 

Thus, what we measure as output is the proportion of forest alive, and the proportion of birds alive. 

The only imputs that we need are the values of the parameters. 


## HOW TO USE IT

You need to seed an initial populations of forest and birds, this is to set the inital conditions to run the model.

There are different ways to set the initial conditions of the model:

 1) The setup button puts in random positions a number of forest with one bird inside, controlled by the slider initial-population.

 2) The setup-center button puts in the center of the view a square of 11 x 11 patches of forests with one bird.

 3) The setup-full button fills all the view with forest and birds.

Then we need to set the death-rate-forest and birth-rate-forest sliders that control the forest rates, and the death-rate-birds birth-rate-birds sliders that control the birds. 

Then the go button runs the model

The lambda-forest is birth-rate-forest/death-rate-forest, this has to be greater than 1 for the forest to survive (how much greater?)

The lambda-birds is birth-rate-birds/death-rate-birds, this has to be greater than 1, and probably greater than lambda-forest for the birds to survive (how much greater?)
 
The proportion of forest patches is the number of forest patches divided by the total number of patches in the view, and the proportion of birds is the number of birds divided by the total number of patches.

The plot shows in green the number of forest patches and in yellow the number of birds

## THINGS TO NOTICE

Starting the model with setup-full is better if you want to know the equilibrium of both populations, and starting with setup-center is better if you want to know if the population get extinct or not.


The fact the birds select the empty patches of forest makes them survive with lower lambda than the forest.

## THINGS TO TRY

You can start modelling a population of forest and birds that survive, i.e. both lambda-forest and lambda-birds greater than 2, and then move the birth-rate-forest slider down to observe when the birds population gets extinct.

## EXTENDING THE MODEL

Deforestation could be added, one way to simulate deforestation is increase the death-rate-forest of the forest but the patterns of deforestation produced by humans are very different from random patterns (because mortality is random). Generally, the deforested zones are used for agriculture/livestock and they need roads to transport the harvest. These roads are straight lines with ramifications at 90 degrees and then square parcels with plantations. So, one interesting extension of this model is to add a sub-model for deforestation.

Another extension is that birds could try to search for a new empty forest patch if the one where they live dies. 

Birds and forest can have a greater dispersal distance than the 4 neighbours patches, using 'in-radius' and a couple of sliders we can investigate the influence of the dispersal distance in the critical values for extinction.

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
NetLogo 6.1.0
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
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
    </enumeratedValueSet>
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
  <experiment name="CriticalValueBirds2.5-4.5forest2.5-4.5_w201_noSel" repetitions="5" runMetricsEveryStep="false">
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
    <steppedValueSet variable="birth-rate-birds" first="2.5" step="0.01" last="4.5"/>
    <enumeratedValueSet variable="death-rate-birds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="death-rate-forest">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="birth-rate-forest" first="2.5" step="0.01" last="4.5"/>
    <enumeratedValueSet variable="birds-behavior">
      <value value="&quot;NoSelection&quot;"/>
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
