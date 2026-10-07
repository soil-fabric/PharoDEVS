Class {
	#name : 'DEVnDESSRootSolverRT',
	#superclass : 'DEVSRootSolverRT',
	#instVars : [
		'tn',
		'h',
		'dh',
		'seDetected'
	],
	#category : 'DEVS-Core-RT',
	#package : 'DEVS-Core',
	#tag : 'RT'
}

{ #category : 'as yet unclassified' }
DEVnDESSRootSolverRT >> discreteStep [
	"After an input the event may lie ahead now; then there is nothing to do yet."

	self assert: [ clock <= tn ].
	(clock = tn) & (tn <= stopTime) ifTrue: [ 
		component receiveMsgStarTime: clock ]				"send (*, t) to root DEVS"
]

{ #category : 'as yet unclassified' }
DEVnDESSRootSolverRT >> initialize [
	"a pure copy of the same method form non-RT  DEVnDESSRootSolver"

	super initialize.
	h := 0.01.

]

{ #category : 'as yet unclassified' }
DEVnDESSRootSolverRT >> numericStep [
	"a pure copy of the same method from non-RT  DEVnDESSRootSolver"

	clock + h < tn ifTrue: [ dh := h ] ifFalse: [ dh := tn - clock ].
	seDetected := false.
	component receiveNMsgStarTime: clock step: dh.		"send (*, t, h) to root DEVS"
	component receiveNMsgX: {} time: clock step: dh.		"send (x, t, h) to root DEVS"
	seDetected ifTrue: [ 	| dhmin dhmax | dhmin := 0. dhmax := dh.
		[ seDetected & ((dhmax - dhmin) < 0.001) ] whileFalse: [ 
			seDetected ifTrue: [ dhmax := dh ] ifFalse: [ dhmin := dh ].
			dh := (dhmax + dhmin)/2.
			seDetected := false.
			component receiveNMsgStarTime: clock step: dh.		
			component receiveNMsgX: {} time: clock step: dh.
				"Note: rootDEVS and consequently an AtomicDEVnDESS is repeatedly called 
				 for the same time. It is supposed that it remembers state and time 
				 from which last step was made. It must check time for which it is called
				 and either revert to previous state or save current state before making a
				 step." ] ].
	clock := clock + dh

]

{ #category : 'as yet unclassified' }
DEVnDESSRootSolverRT >> receiveMsgSETime: tnc [
	"a pure copy of the same method form non-RT  DEVnDESSRootSolver"

	seDetected := true.
	tnc < tn ifTrue: [ tn := tnc ] ifFalse: [ ((tnc - tn) closeTo: 0) ifFalse: [ self error: 'Bad sync !'] ]


]

{ #category : 'as yet unclassified' }
DEVnDESSRootSolverRT >> simulationStep [
	"Probably full of bugs.

	What was sent is logged by the component that sent it, as in DEVSRootSolverRT;
	the discrete step no longer adds a second record of the root's output.

	A numeric step that brings the clock to the next event is followed by that event
	in the same step, after a second wait and a second look at the interrupts - the
	order of DEVSRootSolverRT. These used to be two steps, and the run loop could end
	the run between them: with the event exactly at the stop time, #start stopped
	without it, and #simulate: made it and then asserted clock = tn against the one
	after it."

	rtFactor = 0 ifTrue: [ ^ self nonRTStep ].

	self synchronizeAndAcceptInterrupts.
	tn := component timeNext.
	(clock < tn) & (clock < stopTime) ifFalse: [ ^ self discreteStep ].

	self numericStep.	"Note: We do not consider numeric input."
	clock = component timeNext ifFalse: [ ^ self ].
	self synchronizeAndAcceptInterrupts.
	tn := component timeNext.	"an input at this moment may have moved it"
	self discreteStep
]

{ #category : 'as yet unclassified' }
DEVnDESSRootSolverRT >> synchronizeAndAcceptInterrupts [

	| inputOccured input msg aSubModel interruptTime |

	"Synchronize clock with real time"
	rtTimer := DEVSTimer at: ((startTime + ((clock min: stopTime) / rtFactor * 1000)) min: SmallInteger maxVal) rounded.
	rtTimer wait.		"Waiting can be interrupted by asynchronous internal or external event."

	"Accept potential interrupts"
	interruptTime := self realTime min: clock. 
	inputOccured := false.
	input := Dictionary new.
	[ (msg := inputQueue nextOrNil) == nil ] whileFalse: [ 
			input at: (component inputPortNamed: msg first) put: msg second.
			inputOccured := true ].
	[ (aSubModel := seQueue nextOrNil) == nil ] whileFalse: [ 
			aSubModel sendMsgSETime: interruptTime ].
	inputOccured  ifTrue: [
			component receiveMsgX: input time: interruptTime.	 "... put input & update event lists"
			component logIncoming ]
]
