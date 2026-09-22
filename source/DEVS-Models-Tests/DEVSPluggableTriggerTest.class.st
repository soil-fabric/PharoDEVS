"
The component that makes something happen in simulated time rather than only before the run.
"
Class {
	#name : 'DEVSPluggableTriggerTest',
	#superclass : 'TestCase',
	#instVars : [
		'network'
	],
	#category : 'DEVS-Models-Tests',
	#package : 'DEVS-Models-Tests'
}

{ #category : 'running' }
DEVSPluggableTriggerTest >> runSimulationFor: ticks [
	| simulation |
	simulation := DEVSSimulation new.
	simulation model: network.
	simulation coordinator: DEVSRootSolver new.
	simulation runTo: ticks
]

{ #category : 'running' }
DEVSPluggableTriggerTest >> setUp [
	super setUp.
	network := DEVSNetwork new name: #net; yourself
]

{ #category : 'tests' }
DEVSPluggableTriggerTest >> testTicksOncePerPeriod [
	"The solver stops after the first event at or beyond the limit, so the last
	tick may lie just past it - what is checked is the spacing."
	| times |
	times := OrderedCollection new.
	self triggerEvery: 10 do: [ :time | times add: time ].
	self runSimulationFor: 45.
	self assert: (times first: 4) asArray equals: #( 10 20 30 40 )
]

{ #category : 'tests' }
DEVSPluggableTriggerTest >> testWhatOneTickDoesTheNextOneSees [
	"This is the difference to stirring a model before the run: there everything
	happens at time zero, in lock step, and no round can build on the one before it."
	| seen counter |
	counter := 0.
	seen := OrderedCollection new.
	self triggerEvery: 10 do: [ :time | counter := counter + 1. seen add: counter ].
	self runSimulationFor: 35.
	self assert: (seen first: 3) asArray equals: #( 1 2 3 )
]

{ #category : 'tests' }
DEVSPluggableTriggerTest >> testWithoutABlockItHasNothingToDo [
	"A trigger nobody gave work to must not keep the simulation awake."
	| trigger |
	trigger := DEVSPluggableTrigger new.
	self assert: trigger timeAdvance equals: trigger infinityTime
]

{ #category : 'running' }
DEVSPluggableTriggerTest >> triggerEvery: aNumber do: aBlock [
	| trigger |
	trigger := DEVSPluggableTrigger new
		name: #tick;
		period: aNumber;
		yourself.
	trigger onTickDo: aBlock.
	network addComponent: trigger.
	^ trigger
]
