"
The real-time solver, which until now had no test of its own.

A step of it first accepts what came in from outside - injected input, state events - and then makes the discrete step that is due, in that order and in the same step. It used to do one or the other, so an input that arrived at the moment of a planned event pushed that event into a later step, and a run that ended at that moment ended without it.
"
Class {
	#name : 'DEVSRootSolverRTTest',
	#superclass : 'TestCase',
	#instVars : [
		'solver'
	],
	#category : 'DEVS-Core-Tests',
	#package : 'DEVS-Core-Tests'
}

{ #category : 'running' }
DEVSRootSolverRTTest >> componentsLoggingInputWhenInjectingInto: aRoot [
	"One input, injected before the run and taken in the step at 1. Answers who wrote
	it down, once per record."

	| simulation |
	solver := DEVSRootSolverRT new.
	simulation := DEVSSimulation new.
	simulation model: aRoot.
	simulation coordinator: solver.
	solver
		component: aRoot;
		rtFactor: 10;
		reset;
		stopTime: 1.

	solver inject: #ping to: #in.
	self runInBackground.

	^ (simulation logger events select: [ :each |
		   each isKindOf: DEVSExternalTransitionEvent ]) collect: [ :each |
		  each component name ]
]

{ #category : 'running' }
DEVSRootSolverRTTest >> runInBackground [
	"#start runs the solver in its own process, which is the way it is meant to be used.
	It ends by itself once the clock reaches the stop time."

	| deadline |
	solver start.
	deadline := Time millisecondClockValue + 5000.
	[ solver isIdle ] whileFalse: [
		Time millisecondClockValue > deadline ifTrue: [
			solver stop.
			self fail: 'The real-time run did not end' ].
		(Delay forMilliseconds: 10) wait ]
]

{ #category : 'running' }
DEVSRootSolverRTTest >> tearDown [

	solver ifNotNil: [ solver stop ].
	super tearDown
]

{ #category : 'tests' }
DEVSRootSolverRTTest >> testAnInputDoesNotPostponeADueEvent [
	"The ticker is due at 1, and the run stops at 1. The input is waiting when the solver
	wakes up for the tick, so both belong to the same step. Before, that step took the
	input only, the clock stood at the stop time, and the tick never happened."

	| net ticker simulation |
	ticker := DEVSTickingAtomic new
		          name: #ticker;
		          interval: 1;
		          yourself.
	net := DEVSCoupledComponent new
		       name: #net;
		       yourself.
	net addInputPortNamed: #in.
	net addComponent: ticker.
	solver := DEVSRootSolverRT new.
	simulation := DEVSSimulation new.
	simulation model: net.
	simulation coordinator: solver.
	solver
		component: net;
		rtFactor: 10;
		reset;
		stopTime: 1.

	solver inject: #ping to: #in.
	self runInBackground.

	self
		assert: ((simulation logger events select: [ :each |
				   each isKindOf: DEVSExternalTransitionEvent ]) collect: [ :each |
				 each time ]) asArray
		equals: #( 1 ).
	self assert: ticker timeLast equals: 1
]

{ #category : 'tests' }
DEVSRootSolverRTTest >> testAnInputToACoupledRootIsWrittenDownOnceByEachReceiver [
	"The root and the component it passes the input on to each say once that it came in.
	The root's record used to be the solver's; now the root writes it itself."

	| net ticker names |
	ticker := DEVSTickingAtomic new
		          name: #ticker;
		          interval: 1;
		          yourself.
	ticker addInputPortNamed: #in.
	net := DEVSCoupledComponent new
		       name: #net;
		       yourself.
	net addInputPortNamed: #in.
	net addComponent: ticker.
	net
		connectComponentNamed: #self
		port: #in
		toComponentNamed: #ticker
		port: #in
		ifFail: [ self fail: 'Could not couple the input' ].

	names := self componentsLoggingInputWhenInjectingInto: net.

	self assert: names asBag size equals: 2.
	self assert: (names asBag occurrencesOf: #net) equals: 1.
	self assert: (names asBag occurrencesOf: #ticker) equals: 1
]

{ #category : 'tests' }
DEVSRootSolverRTTest >> testAnInputToAnAtomicRootIsWrittenDownOnce [
	"It was twice: the atomic component logged the input at the end of #receiveMsgX:time:
	and the solver logged it again straight after."

	| ticker |
	ticker := DEVSTickingAtomic new
		          name: #ticker;
		          interval: 1;
		          yourself.
	ticker addInputPortNamed: #in.

	self
		assert: (self componentsLoggingInputWhenInjectingInto: ticker) asArray
		equals: #( #ticker )
]
