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
