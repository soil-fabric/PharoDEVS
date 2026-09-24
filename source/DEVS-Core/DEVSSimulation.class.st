Class {
	#name : 'DEVSSimulation',
	#superclass : 'Object',
	#instVars : [
		'model',
		'coordinator',
		'logger',
		'announcer'
	],
	#category : 'DEVS-Core-Basic',
	#package : 'DEVS-Core',
	#tag : 'Basic'
}

{ #category : 'arithmetic' }
DEVSSimulation >> / aString [ 
	^ model / aString 
]

{ #category : 'accessing' }
DEVSSimulation >> coordinator [

	^ coordinator
]

{ #category : 'accessing' }
DEVSSimulation >> coordinator: anObject [

	coordinator := anObject
]

{ #category : 'as yet unclassified' }
DEVSSimulation >> defaultSimulationTime [
	^ 100 
]

{ #category : 'announcer' }
DEVSSimulation >> announcer [
	"Who is listening to what the simulation does. Built on demand, so a simulation
	nobody subscribes to carries nothing."

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'announcer' }
DEVSSimulation >> emitEvent: anEvent [
	"Stamped, kept, and only then said out loud - so a subscriber sees an event that
	already carries its time and already stands in the log.

	The announcement is synchronous and happens inside the step that produced it.
	That is the whole point: what a subscriber does - heal a partition, restart a
	node, inject a message - takes effect at this moment of the model's time, not
	after the run. Before this, a scenario could only be built before the run and
	read after it, and everything in between was a wall-clock wait."

	anEvent time: coordinator time.
	self logger addEvent: anEvent.
	self announcer announce: anEvent
]

{ #category : 'accessing' }
DEVSSimulation >> logger [ 
	^ logger ifNil: [ 
		logger := self newDefaultLogger ] 
]

{ #category : 'accessing' }
DEVSSimulation >> model [

	^ model
]

{ #category : 'accessing' }
DEVSSimulation >> model: anObject [
	anObject parent: self.
	model := anObject
]

{ #category : 'instance creation' }
DEVSSimulation >> newDefaultLogger [
	^ DEVSLogger new 
]

{ #category : 'printing' }
DEVSSimulation >> printPathOn: aStream [ 

]

{ #category : 'misc' }
DEVSSimulation >> rootSolver [
	^ self coordinator 
]

{ #category : 'running' }
DEVSSimulation >> run [ 
	self runTo: self defaultSimulationTime 
]

{ #category : 'running' }
DEVSSimulation >> runTo: aTime [ 
	self coordinator 
		component: self model;
		simulate: aTime 
]

{ #category : 'misc' }
DEVSSimulation >> simulation [ 
	
	^ self
]

{ #category : 'announcer' }
DEVSSimulation >> when: anEventClass do: aBlock [
	"Be called when the simulation does that, while it is doing it. The block takes
	the event - which knows its component and the time of the model - or nothing.

	It does not forward to Announcer>>when:do:, which is not the same message in
	every Pharo this is built on: it is gone in 13, and where it still exists it is
	deprecated with a rule that rewrites the calling method. #when:send:to: has not
	moved across 11 to 14, and #cull: is what lets the block decide whether it wants
	the event."

	^ self announcer when: anEventClass send: #cull: to: aBlock
]

{ #category : 'stepping' }
DEVSSimulation >> step [
	self coordinator simulationStep 
]
