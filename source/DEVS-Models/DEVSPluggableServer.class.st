"
I represent application server that can consume incoming messages. I have a hook method - a block that is defined outside of me that I can execute during generating output when incoming message is for me. 
"
Class {
	#name : 'DEVSPluggableServer',
	#superclass : 'DEVSServer',
	#instVars : [
		'block',
		'heartbeat',
		'heartbeatBlock',
		'nextHeartbeat'
	],
	#category : 'DEVS-Models-network',
	#package : 'DEVS-Models',
	#tag : 'network'
}

{ #category : 'accessing' }
DEVSPluggableServer >> every: ticks do: aBlock [
	"Have this server do something of its own every ticks, on top of answering
	what arrives. Without it a server only ever reacts, so a protocol whose second
	round builds on what the first one learned cannot be run at all: everything
	stirred up before the simulation starts happens at time zero, in lock step."
	heartbeat := ticks.
	heartbeatBlock := aBlock.
	nextHeartbeat := ticks
]

{ #category : 'modeling' }
DEVSPluggableServer >> externalTransition [ 
	messages add: (self peekFrom: #in).
	state := #processing
]

{ #category : 'modeling' }
DEVSPluggableServer >> internalTransition [
	"timeLast still holds the previous transition; the one happening now is timeNext."
	(heartbeatBlock notNil and: [ timeNext >= nextHeartbeat ]) ifTrue: [
		nextHeartbeat := nextHeartbeat + heartbeat.
		heartbeatBlock cull: self ].
	messages ifEmpty: [
		state := #idle ]
]

{ #category : 'accessing' }
DEVSPluggableServer >> onIncomingDo: aBlock [ 
	"aBlock that is executed when incoming message is for me"
	block := aBlock
]

{ #category : 'modeling' }
DEVSPluggableServer >> outputFunction [ 
	| message |
	messages ifNotEmpty: [
		message := messages removeFirst. 
		(self isIncoming: message)
			ifTrue: [ 
				(block 
					cull: message 
					cull: self)
					ifNotNil: [ :reply | 
						self 
							poke: reply
							to: #out  ] ]
			ifFalse: [ 
				self 
					poke: message
					to: #out ] ]
]

{ #category : 'modeling' }
DEVSPluggableServer >> timeAdvance [
	"The earlier of the two reasons to wake up: a message waiting to go out, or
	the next heartbeat."
	| byMessages |
	byMessages := messages ifNotEmpty: [ 1 ] ifEmpty: [ self infinityTime ].
	heartbeatBlock ifNil: [ ^ byMessages ].
	^ byMessages min: ((nextHeartbeat - timeLast) max: 0)
]
