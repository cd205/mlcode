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
The side of a Feature's Specification Limits where an out-of-spec value can still be corrected by further processing. The other side is the Scrap Side. It depends on the operation, so it is always defined for each Feature and never assumed. It may be *none*, in which case both sides scrap and the Feature never appears in a Rework State.
_Avoid_: rework direction

## Production structure

**Stage**:
The processing of one or more Features, followed by one Inspection, together with the rework and scrap loop that Inspection triggers.
_Avoid_: operation, step, station

**Sequence**:
The ordered grouping of a part's Features into Stages, which fixes where Inspections happen relative to the order the Features are made.
_Avoid_: operation sequence, route, process plan

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
_Avoid_: good, pass, accepted

**Scrapped**:
The absorbing state reached when any Feature falls on its Scrap Side. One scrapped Feature scraps the whole part.
_Avoid_: rejected, failed

**Final Conformance Probability**:
The probability that a part entering a Stage (or a Sequence) eventually reaches Conforming, counting every rework cycle.
_Avoid_: yield, pass rate

## Process settings

**Mean Setting**:
The controllable target value around which a process produces a Feature. A Feature may have different Mean Settings for the initial operation and for each Rework State.
_Avoid_: target, nominal, mu

**Process Variation**:
The uncontrollable random spread, including correlation between Features, in the values a process produces around its Mean Settings.
_Avoid_: noise, uncertainty, sigma

## Economics

**Selling Price**:
The revenue earned for each part that conforms at the end of the Sequence.

**Processing Cost**:
The cost of a Stage's initial operation, incurred by every part that reaches the Stage.

**Rework Cost**:
The cost incurred each time a part passes through a given Rework State.

**Scrap Cost**:
The cost incurred when a part is scrapped from a given state. It already includes the value added in earlier Stages, so it accumulates along the Sequence.

**Inspection Cost**:
The cost of an Inspection: a fixed amount per Stage plus an amount per inspected Feature.

**Expected Profit**:
Selling Price times the Final Conformance Probability of the Sequence, minus the expected Processing, Rework, Scrap and Inspection Costs per part started.
_Avoid_: EP, profit function
