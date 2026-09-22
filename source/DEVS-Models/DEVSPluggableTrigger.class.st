"
A participant that acts on its own rather than only in reply: every period ticks it evaluates a block.

Without it a model can only be stirred from outside the run, before the solver starts - and then everything that was stirred up happens at time zero, in lock step. A protocol that needs a second round to build on what the first one learned cannot be shown that way. This is what lets rounds happen one after another in simulated time.

It has no ports and sends nothing. What it triggers, it triggers directly on the objects the block holds, which is also how a scenario can change the world mid-run - taking a partition back out, for instance.
"
Class {
	#name : 'DEVSPluggableTrigger',
	#superclass : 'DEVSAtomicComponent',
	#instVars : [
		'period',
		'block'
	],
	#category : 'DEVS-Models',
	#package : 'DEVS-Models'
}

{ #category : 'modeling' }
DEVSPluggableTrigger >> externalTransition [
	"Nothing reaches this component either; it has no input port."
]

{ #category : 'initialization' }
DEVSPluggableTrigger >> initialize [
	super initialize.
	period := 1
]

{ #category : 'modeling' }
DEVSPluggableTrigger >> internalTransition [
	"timeLast still holds the previous transition; the one happening now is timeNext."
	block cull: self timeNext cull: self
]

{ #category : 'accessing' }
DEVSPluggableTrigger >> onTickDo: aBlock [
	"aBlock is evaluated on every tick. It may take the current simulation time,
	and the trigger itself, as arguments."
	block := aBlock
]

{ #category : 'modeling' }
DEVSPluggableTrigger >> outputFunction [
	"Nothing leaves this component."
]

{ #category : 'accessing' }
DEVSPluggableTrigger >> period [
	^ period
]

{ #category : 'accessing' }
DEVSPluggableTrigger >> period: aNumber [
	"Ticks between two evaluations of the block."
	period := aNumber
]

{ #category : 'modeling' }
DEVSPluggableTrigger >> timeAdvance [
	"A trigger without a block has nothing to do and must not keep the simulation
	awake."
	^ block
		ifNil: [ self infinityTime ]
		ifNotNil: [ period ]
]
