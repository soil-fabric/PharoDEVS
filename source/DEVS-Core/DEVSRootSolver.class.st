Class {
	#name : 'DEVSRootSolver',
	#superclass : 'DEVSBasicSolver',
	#instVars : [
		'component',
		'started'
	],
	#category : 'DEVS-Core-Basic',
	#package : 'DEVS-Core',
	#tag : 'Basic'
}

{ #category : 'modeling' }
DEVSRootSolver >> component [

	^ component



]

{ #category : 'modeling' }
DEVSRootSolver >> component: aComponent [

	component := aComponent.



]

{ #category : 'as yet unclassified' }
DEVSRootSolver >> doSteps: n [

	| tmp |
	tmp := self rtFactor.
	self rtFactor: 0.
	super doSteps: n.
	self rtFactor: tmp.

]

{ #category : 'modeling' }
DEVSRootSolver >> initializeModel [
	"Back to the beginning - the one place that undoes #prepareToStart."

	started := false.

	"let's initialize the model"
	component reset.	

	"let's initilalize simulation as well"
	clock := 0. stopTime := Float infinity.
	component receiveMsgInitTime: clock.	"it also starts processes in atomic devses"
	component receiveMsgSyncTime: clock.				"here we stop them"

	

]

{ #category : 'simulation' }
DEVSRootSolver >> prepareToStart [
	"Once, not once per run. #simulate: is called for every #runTo:, and this used to
	send #receiveMsgInitTime: again each time - which on a model that has already
	advanced is not a start but a second one.

	It did not merely re-stamp the clock. DEVSAtomicComponent>>receiveMsgInitTime:
	computes timeNext from savedTimeAdvance, the value cached at the last transition,
	and a component that was idle then is scheduled for infinity no matter what has
	been put in front of it since. So a second run either failed the assertion that
	timeNext lies ahead, or - worse - ran and delivered nothing.

	A continued run therefore continues: whatever the model was doing at the end of
	the last one, it is still doing. Something that has to enter a running simulation
	from outside belongs inside a step of it - a subscriber to DEVSSimulation>>when:do:
	runs in the step that produced its event, and what it does there is an ordinary
	part of the model's time."

	"== true rather than ifTrue:, because a solver that has never run has nil here."
	started == true ifTrue: [ ^ self ].
	started := true.
	component receiveMsgInitTime: clock
]

{ #category : 'simulation' }
DEVSRootSolver >> prepareToStop [

	component receiveMsgSyncTime: clock.

]

{ #category : 'simulation' }
DEVSRootSolver >> reset [

	super reset.
	self initializeModel.
]

{ #category : 'simulation' }
DEVSRootSolver >> simulationStep [

	clock := self component timeNext.
	clock isInfinite ifTrue: [^self].
	component receiveMsgStarTime: clock. 				"send (*, t) to root DEVS"
	
	clock := component timeLast.



]

{ #category : 'simulation' }
DEVSRootSolver >> time [

	^ clock

]
