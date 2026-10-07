"
This class needs refactoring!

TO DO:

Move RT scheduling to AbstractSimulation.

Lots of operations are not thread safe !


"
Class {
	#name : 'DEVSRootSolverRT',
	#superclass : 'DEVSRootSolver',
	#instVars : [
		'rtTimer',
		'startTime',
		'inputQueue',
		'seQueue',
		'rtFactor',
		'lastTime'
	],
	#category : 'DEVS-Core-RT',
	#package : 'DEVS-Core',
	#tag : 'RT'
}

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> asyncRtFactor: f [

	self asyncSafelyDo: [ rtFactor := f ]

]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> initialize [

	super initialize.	
	inputQueue := SharedQueue new.
	seQueue := SharedQueue new.	
	startTime := Time millisecondClockValue.
	lastTime := startTime.
	rtFactor := 1.


]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> initializeModel [

	super initializeModel.
	inputQueue := SharedQueue new.
	seQueue := SharedQueue new.	
	startTime := Time millisecondClockValue.
	lastTime:=startTime.
	
]

{ #category : 'asynchronous interrupts' }
DEVSRootSolverRT >> inject: value to: port [

	inputQueue isNil ifFalse: [ inputQueue nextPut: { port. value. } ].
	rtTimer isNil ifFalse: [ rtTimer unschedule ].		"wake up"

]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> nonRTStep [

	^ super simulationStep

]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> prepareToStart [
	"The pacing is set up on every start, because real time goes on while the solver is
	stopped. The model is initialised once, in DEVSRootSolver>>prepareToStart.

	This used to send #receiveMsgInitTime: on every start as well. In real time that did
	no harm: the clock stays finite, and #receiveMsgSyncTime: at stop followed by Init at
	the same clock gives every component back its timeLast and timeNext. Without real time
	- rtFactor 0, or #doSteps: - the solver steps like DEVSRootSolver, and like it puts
	the clock to infinity once nothing is planned. Init at that clock computed an idle
	component's timeLast as infinity minus infinity, and the next run failed the assertion
	that timeNext lies ahead - the gap #runTo: had until 2026-09-25.

	What a component resumes in #prepareToStart is therefore resumed once, as with
	DEVSRootSolver; #receiveMsgSyncTime: still suspends it at every stop."

	rtFactor = 0 
		ifFalse: [ startTime := Time millisecondClockValue - (clock / rtFactor * 1000) ]
		ifTrue: [ startTime := Time millisecondClockValue - (clock  * 1000) ].
	super prepareToStart
]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> realTime [
	"returns real time in seconds"
	(self isRunning) 
		ifTrue: [ ^ (Time millisecondClockValue - startTime)  * rtFactor / 1000 ]
		ifFalse: [ ^ clock ].

]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> receiveMsgSETime: t [
	"nothing to do here"


]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> rtFactor [
  ^rtFactor
]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> rtFactor: f [

	self safelyDo: [ rtFactor := f ]

]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> simulate: t [
	"Performs the simulation. For simulation in background use start/stop instead.

	Runs while clock < stopTime, like #start (DEVSBasicSolver>>processBody). It was
	clock <= stopTime, which leaves a step that brought the clock exactly to the stop
	time one more round. The discrete solver let real time push the clock past it;
	DEVnDESSRootSolverRT moves its clock only by a step, and at the stop time there is
	none left to make."

	startTime := Time millisecondClockValue.
	stopTime := t.	"in seconds"
	clock := self realTime min: component timeNext.		"isn't this redundant ???"
	self prepareToStart.
	startStopSemaphore initSignals.	"running simulation indication"
	[ clock < stopTime ] whileTrue: [ self simulationStep ].
	startStopSemaphore signal.
	self prepareToStop.

	self finalize.	"stops processes in atomic submodels"


]

{ #category : 'realtime simulation' }
DEVSRootSolverRT >> simulationStep [
	"First accept interrupts, then make the discrete step - the order DEVnDESSRootSolverRT
	already had. This used to be either-or: a step that found input in the queue made
	the external transition and skipped the event planned for the same moment. When the
	run ended at that moment, the event was gone for this run; with input arriving at
	every wake-up, it never came.

	What was sent is logged by the component that sent it, as in DEVSRootSolver; the
	solver no longer adds a record of its own after every step, transition or not."

	| msg aSubModel inputOccured input |

	rtFactor = 0 ifTrue: [ ^ self nonRTStep ].

	"Synchronize with real time"
	rtTimer := DEVSTimer at: ((startTime + ((component timeNext min: stopTime) / rtFactor * 1000)) min: SmallInteger maxVal) rounded.
	rtTimer wait.		"Waiting can be interrupted by asynchronous internal or external event."
	
	startStopSemaphore isSignaled ifTrue: [^self].	"No step, return immediately."

	clock := self realTime min: component timeNext.

	"Accept interrupts"
	inputOccured := false.
	input := Dictionary new.
	[ (msg := inputQueue nextOrNil) == nil ] whileFalse: [ 
		input at: (component inputPortNamed: msg first) put: msg second.
		inputOccured := true ].
	[ (aSubModel := seQueue nextOrNil) == nil ] whileFalse: [ 
		aSubModel sendMsgSETime: clock ].
	inputOccured ifTrue: [
		component receiveMsgX: input time: clock.	 "... put input & update event lists"
		component logIncoming ].

	"Discrete step, if one is due now - also after an input, which may have moved it."
	((component timeNext - clock) closeTo: 0) 
		ifTrue: [ component receiveMsgStarTime: clock ]

]

{ #category : 'as yet unclassified' }
DEVSRootSolverRT >> startUnprotected [

	super startUnprotected.
	rtFactor = 0 ifTrue: [ process priority: process priority - 1 ].	
	"Non-RT simulation should have lower priority."

]

{ #category : 'asynchronous interrupts' }
DEVSRootSolverRT >> stateEventIn: aSubmodel [

	seQueue isNil ifFalse: [ seQueue nextPut: aSubmodel ].
	rtTimer isNil ifFalse: [ rtTimer unschedule ].		"wake up"

]

{ #category : 'asynchronous interrupts' }
DEVSRootSolverRT >> stopUnprotected [

	| r |
	r := false.
	startStopSemaphore isSignaled ifFalse: [
		startStopSemaphore signal.	"A signal to stop."

		rtTimer isNil ifFalse: [ rtTimer unschedule ].		"wake up"
		lastTime:=Time millisecondClockValue.

		idleSemaphore wait.	"Waiting for current step finishing." 
		idleSemaphore initSignals; signal. "Initialize the semaphore."
		r := true ].
	^ r

]

{ #category : 'as yet unclassified' }
DEVSRootSolverRT >> timeToShow [

	^ rtFactor = 0 ifTrue: [ self time ] ifFalse: [ self realTime ] 	


]
