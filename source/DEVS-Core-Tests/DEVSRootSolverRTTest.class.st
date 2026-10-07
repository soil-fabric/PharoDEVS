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
DEVSRootSolverRTTest >> continuousRootWithTicker [
	"A continuous root with one ticker, due at 1, 2, 3 ... Answers the root."

	| net simulation |
	net := DEVSCoupledDESS new
		       name: #net;
		       yourself.
	net addComponent: (DEVSTickingAtomic new
			 name: #ticker;
			 interval: 1;
			 yourself).
	solver := DEVnDESSRootSolverRT new.
	simulation := DEVSSimulation new.
	simulation model: net.
	simulation coordinator: solver.
	solver
		component: net;
		rtFactor: 10;
		reset.
	^ net
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
DEVSRootSolverRTTest >> testAContinuousRunInTheBackgroundMakesTheEventAtItsStopTime [
	"The numeric step brought the clock to 2, the stop time, and the discrete step was
	left for the next round, which the run loop did not start. The run ended at 2
	without the tick at 2."

	| net |
	net := self continuousRootWithTicker.
	solver stopTime: 2.
	self runInBackground.

	self assert: (self timesOfOutputOf: net) equals: #( 1 2 )
]

{ #category : 'tests' }
DEVSRootSolverRTTest >> testAContinuousRunToItsStopTimeEnds [
	"#simulate: ran while clock <= stopTime, so after the tick at 2 it came round once
	more, found the next tick at 3 and failed the assertion clock = tn."

	| net |
	net := self continuousRootWithTicker.
	[ solver simulate: 2 ]
		valueWithin: 5 seconds
		onTimeout: [ self fail: 'The run did not end' ].

	self assert: (self timesOfOutputOf: net) equals: #( 1 2 )
]

{ #category : 'tests' }
DEVSRootSolverRTTest >> testARunWithoutRealTimeCanBeContinued [
	"With rtFactor 0 the solver steps like DEVSRootSolver, and the clock goes to infinity
	once nothing is planned. A second run sent #receiveMsgInitTime: at that clock, the idle
	component's timeLast became infinity minus infinity, and the assertion that timeNext
	lies ahead failed. DEVSNetworkTest>>testRunToCalledTwiceContinuesTheRun is the same
	case for DEVSRootSolver."

	| idle net simulation |
	idle := DEVSTickingAtomic new
		        name: #idle;
		        interval: Float infinity;
		        yourself.
	net := DEVSCoupledComponent new
		       name: #net;
		       yourself.
	net addComponent: idle.
	solver := DEVSRootSolverRT new.
	solver rtFactor: 0.
	simulation := DEVSSimulation new.
	simulation model: net.
	simulation coordinator: solver.

	simulation runTo: 10.
	self shouldnt: [ simulation runTo: 20 ] raise: Error.
	self deny: idle timeLast isNaN
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

{ #category : 'tests' }
DEVSRootSolverRTTest >> testTheContinuousRootSaysOnceWhatItSent [
	"The continuous variant had its own discrete step, which logged the root's output
	once more after the root had logged it itself. The ticker is due at 1 and 2."

	| net ticker simulation |
	ticker := DEVSTickingAtomic new
		          name: #ticker;
		          interval: 1;
		          yourself.
	net := DEVSCoupledDESS new
		       name: #net;
		       yourself.
	net addComponent: ticker.
	solver := DEVnDESSRootSolverRT new.
	simulation := DEVSSimulation new.
	simulation model: net.
	simulation coordinator: solver.
	solver
		component: net;
		rtFactor: 10;
		reset;
		stopTime: 2.5.

	self runInBackground.

	self
		assert: ((simulation logger events select: [ :each |
				   (each isKindOf: DEVSInternalTransitionEvent) and: [
					   each component == net ] ]) collect: [ :each | each time ])
				asArray
		equals: #( 1 2 )
]

{ #category : 'running' }
DEVSRootSolverRTTest >> timesOfOutputOf: aComponent [

	^ ((aComponent simulation logger events select: [ :each |
		    (each isKindOf: DEVSInternalTransitionEvent) and: [
			    each component == aComponent ] ]) collect: [ :each | each time ])
		  asArray
]
