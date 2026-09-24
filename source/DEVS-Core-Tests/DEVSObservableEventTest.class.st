"
That what a simulation does can be listened to while it happens, not only read afterwards.

The DEVSLogger has always been a bucket: an event is stamped with the time of the model and put in a list, and nothing can react until the run is over. A scenario could therefore only be built before the run and inspected after it, and everything in between came down to waiting on the wall clock - which is what a simulator exists to get rid of.

With an announcer, a test is called inside the step that produced the event. What it does there - heal a partition, restart a node, inject a message - happens at that moment of the model's time.
"
Class {
	#name : 'DEVSObservableEventTest',
	#superclass : 'TestCase',
	#instVars : [
		'simulation'
	],
	#category : 'DEVS-Core-Tests',
	#package : 'DEVS-Core-Tests'
}

{ #category : 'running' }
DEVSObservableEventTest >> runTo: aTime [
	simulation runTo: aTime
]

{ #category : 'running' }
DEVSObservableEventTest >> setUp [
	"An atomic component that wakes every ten ticks, which is enough to produce
	internal transitions and nothing more."

	super setUp.
	simulation := DEVSSimulation new.
	simulation model: (DEVSTickingAtomic new
			 name: #ticker;
			 interval: 10;
			 yourself).
	simulation coordinator: DEVSRootSolver new
]

{ #category : 'tests' }
DEVSObservableEventTest >> testASubscriberHearsWhatTheSimulationDoes [
	"Once per tick, not twice. The solver used to log the root's outgoing on top of
	what the root had already logged itself, so a subscriber was called twice for one
	transition - which for a scenario that acts on an event is not a matter of taste."

	| heard |
	heard := OrderedCollection new.
	simulation
		when: DEVSInternalTransitionEvent
		do: [ :event | heard add: event time ].
	self runTo: 35.
	self assert: (heard first: 3) asArray equals: #( 10 20 30 )
]

{ #category : 'tests' }
DEVSObservableEventTest >> testTheEventIsStampedAndKeptBeforeAnybodyHearsIt [
	"A subscriber sees an event that already carries its time and already stands in
	the log - so what it reads there is what the run will have recorded."

	| seen |
	seen := OrderedCollection new.
	simulation when: DEVSInternalTransitionEvent do: [ :event |
		seen add: {
				event time.
				(simulation logger events includes: event) } ].
	self runTo: 15.
	self assert: seen first first equals: 10.
	self assert: seen first second
]

{ #category : 'tests' }
DEVSObservableEventTest >> testTheSubscriberRunsInsideTheStep [
	"The difference that makes this worth building. The block is called while the
	model stands at that time, so what it does takes effect there - not after the
	run, and not at a moment measured on a wall clock."

	| timesWhenCalled |
	timesWhenCalled := OrderedCollection new.
	simulation when: DEVSInternalTransitionEvent do: [ :event |
		timesWhenCalled add: event time -> simulation coordinator time ].
	self runTo: 25.
	self assert: (timesWhenCalled allSatisfy: [ :each | each key = each value ])
]

{ #category : 'tests' }
DEVSObservableEventTest >> testWithoutASubscriberNothingChanges [
	"A simulation nobody listens to behaves exactly as before, and still logs."

	self runTo: 35.
	self assert: simulation logger events notEmpty
]
