# Manufacturing Operation-Sequence Modelling (OMS)

How parts gain value or lose it as their Features are produced, inspected, reworked or scrapped under manufacturing variation, and how controllable Mean Settings affect Expected Profit.

## Parts and features

**Feature**:
One inspectable, measurable dimension of a part, judged against its Specification Limits.
_Avoid_: variable, characteristic, quality characteristic, dimension

**Specification Limits**:
The lower (L) and upper (U) bounds that a Feature's measured value must lie within for the Feature to conform.
_Avoid_: tolerance band, spec

**Rework Side**:
The side of a Feature's Specification Limits where an out-of-spec value can still be corrected by further processing. The other side is the Scrap Side. It depends on the Operation, so it is always defined for each Feature and never assumed. It may be *none*, in which case both sides scrap and the Feature never appears in a Rework State.
_Avoid_: rework direction

## Production structure

**Operation**:
The processing that produces one Feature, such as turning, drilling or milling. Its name is the Feature's name. Every Operation produces a Feature; processing that produces nothing inspected is counted in a neighbouring Operation's Processing Cost. Rework repeats the Operation; it is not a separate Operation.
_Avoid_: process, machining step, step

**Stage**:
One or more Operations followed by one Inspection, together with the rework and scrap loop that Inspection triggers.
_Avoid_: station

**Sequence**:
The ordered list of a part's Operations and Inspections; each Inspection closes a Stage made of the Operations before it.
_Avoid_: operation sequence, step list, route, process plan

**Serial**:
A Sequence arrangement in which each Stage contains a single Feature.

**Parallel**:
A Sequence arrangement in which a Stage contains several Features made before one shared Inspection. It does not mean parallel machines or branching flows.

**Inspection**:
The 100%, error-free measurement of every Feature of a Stage. It decides whether the part conforms, is reworked, or is scrapped.
_Avoid_: measurement, check, gauge

## Stage states

**Initial State**:
The state of a part when it first enters a Stage, before any of the Stage's Features have been inspected.

**Rework State**:
A state in which a particular non-empty subset of a Stage's Features is being re-processed. There is one Rework State for each such subset.
_Avoid_: rework loop, rework stage

**Rework Group Size**:
The number of Features reworked together in a Rework State.

**Conforming**:
The absorbing state reached when every Feature of the Stage is within its Specification Limits.
_Avoid_: good, passed, accepted

**Scrapped**:
The absorbing state reached when any Feature falls on its Scrap Side. One scrapped Feature scraps the whole part.
_Avoid_: rejected, failed

**Pass**:
One Inspection of a part at a Stage; the k-th Pass is the part's k-th Inspection there. A part leaves a Pass Conforming, Scrapped, or in a Rework State for the next Pass.
_Avoid_: cycle, iteration, round

**Final Conformance Probability**:
The probability that a part entering a Stage (or a Sequence) eventually reaches Conforming, counting every Pass.
_Avoid_: yield, pass rate

**Reach Probability**:
The probability r_i that a part started reaches Stage i of a Sequence: the product of the Final Conformance Probabilities of the Stages before it.

## Process settings

**Mean Setting**:
The controllable target value around which a process produces a Feature. A Feature may have different Mean Settings for its Operation (from the Initial State) and for each Rework State.
_Avoid_: target, nominal, mu

**Process Variation**:
The uncontrollable random spread, including correlation between Features, in the values a process produces around its Mean Settings.
_Avoid_: noise, uncertainty, sigma

## Economics

**Selling Price**:
The revenue earned for each part that conforms at the end of the Sequence.

**Processing Cost**:
The cost of a Stage's Operations, incurred by every part that reaches the Stage. It may be given for each Operation, in which case the Stage's Processing Cost is their sum.

**Rework Cost**:
The cost incurred each time a part passes through a given Rework State.

**Material Value**:
The value of a part's raw material, paid for every part started. A part that conforms recovers it through the Selling Price; a scrapped part loses it.

**Scrap Cost**:
The cost incurred when a part is scrapped from a given state, on top of the Material Value and the Processing and Rework Costs the part has already been charged. For a user's own Sequence it is the extra cost of scrapping, such as disposal, and may be negative for material recovered, down to minus the Material Value. In the thesis cases it is cumulative: it includes the value added in earlier Stages, so it accumulates along the Sequence.
_Avoid_: scrap value

**Inspection Cost**:
The cost of an Inspection: a fixed amount per Stage plus an amount per inspected Feature.

**Expected Profit**:
Selling Price times the Final Conformance Probability of the Sequence, minus the Material Value and the expected Processing, Rework and Scrap Costs per part started. Inspection Cost is reported beside it as Expected Profit less Inspection Cost (thesis E(PR) − I); it doesn't depend on the Mean Settings, so both have the same optimum.
_Avoid_: EP, profit function
