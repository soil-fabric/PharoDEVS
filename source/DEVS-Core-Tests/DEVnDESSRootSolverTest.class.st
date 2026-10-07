"
The solver for continuous models that does not run in real time, which until now had no test of its own.

A run of it ends at its stop time: the last numeric step stops there, and an event planned for that moment is made in the same run.
"
Class {
	#name : 'DEVnDESSRootSolverTest',
	#superclass : 'TestCase',
	#instVars : [
		'simulation'
	],
	#category : 'DEVS-Core-Tests',
	#package : 'DEVS-Core-Tests'
}

{ #category : 'running' }
DEVnDESSRootSolverTest >> continuousRootWithTicker [
	"A continuous root with one ticker, due at 1, 2, 3 ... Answers the root."

	| net solver |
	net := DEVSCoupledDESS new
		       name: #net;
		       yourself.
	net addComponent: (DEVSTickingAtomic new
			 name: #ticker;
			 interval: 1;
			 yourself).
	solver := DEVnDESSRootSolver new.
	simulation := DEVSSimulation new.
	simulation model: net.
	simulation coordinator: solver.
	solver
		component: net;
		reset.
	^ net
]

{ #category : 'tests' }
DEVnDESSRootSolverTest >> testARunMakesTheEventAtItsStopTime [
	"The numeric step brought the clock to 2, the stop time, and the discrete step was
	left for the next round, which #simulate: did not start. The run ended at 2 without
	the tick at 2."

	| net |
	net := self continuousRootWithTicker.
	simulation runTo: 2.

	self assert: (self timesOfOutputOf: net) equals: #( 1 2 )
]

{ #category : 'tests' }
DEVnDESSRootSolverTest >> testARunStopsItsClockAtTheStopTime [
	"The numeric step was bounded by the next event only, so the last one before the stop
	time went a step size past it - to about 2.51 for a stop time of 2.5 - and the model
	was integrated over time the run was not asked for."

	self continuousRootWithTicker.
	simulation runTo: 2.5.

	self assert: simulation coordinator time equals: 2.5
]

{ #category : 'running' }
DEVnDESSRootSolverTest >> timesOfOutputOf: aComponent [

	^ ((aComponent simulation logger events select: [ :each |
		    (each isKindOf: DEVSInternalTransitionEvent) and: [
			    each component == aComponent ] ]) collect: [ :each | each time ])
		  asArray
]
