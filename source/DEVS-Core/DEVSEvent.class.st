"
Something the simulation did, at the time of the model it did it in.

An Announcement, so that a test can subscribe to it and be called while the simulation runs rather than reading a list afterwards. Nothing else changes: an event is still stamped and still kept by the DEVSLogger, and a simulation nobody listens to behaves exactly as before.
"
Class {
	#name : 'DEVSEvent',
	#superclass : 'Announcement',
	#instVars : [
		'time'
	],
	#category : 'DEVS-Core-Basic',
	#package : 'DEVS-Core',
	#tag : 'Basic'
}

{ #category : 'accessing' }
DEVSEvent >> time [

	^ time
]

{ #category : 'accessing' }
DEVSEvent >> time: anObject [

	time := anObject
]
