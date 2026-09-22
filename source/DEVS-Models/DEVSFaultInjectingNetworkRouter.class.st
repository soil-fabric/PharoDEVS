"
A DEVSNetworkRouter that can be told to misbehave: drop messages between a pair of addresses while they are partitioned, drop a counted number of messages in one direction, or delay a pair by a number of ticks.

With nothing configured it behaves exactly like its superclass - empty partition set, empty tables - so a model pays nothing for the ability until it uses it. Latency rides in its own pending queue rather than a variable timeAdvance, so a delayed pair does not hold up unrelated traffic.
"
Class {
	#name : 'DEVSFaultInjectingNetworkRouter',
	#superclass : 'DEVSNetworkRouter',
	#instVars : [
		'partitions',
		'dropCounts',
		'pendingLatencies',
		'latencyTable'
	],
	#category : 'DEVS-Models',
	#package : 'DEVS-Models'
}

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> dropNextNMessagesBetween: sourceAddress and: destinationAddress count: anInteger [
	dropCounts at: (Array with: sourceAddress with: destinationAddress) put: anInteger
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> externalTransition [
	| msg delay |
	msg := self peekFrom: #in.
	(self shouldDropMessage: msg) ifTrue: [ ^ self ].
	delay := self latencyFor: msg.
	delay > 0
		ifTrue: [ pendingLatencies add: msg -> delay ]
		ifFalse: [ messages add: msg ].
	state := #processing
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> healPartition: addr1 and: addr2 [
	partitions remove: (Array with: addr1 with: addr2) ifAbsent: [ ].
	partitions remove: (Array with: addr2 with: addr1) ifAbsent: [ ]
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> initialize [
	super initialize.
	partitions := Set new.
	dropCounts := Dictionary new.
	pendingLatencies := OrderedCollection new.
	latencyTable := Dictionary new
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> internalTransition [
	| ready |
	pendingLatencies := pendingLatencies collect: [ :assoc | assoc key -> (assoc value - 1) ].
	ready := pendingLatencies select: [ :assoc | assoc value <= 0 ].
	ready do: [ :assoc | messages add: assoc key ].
	pendingLatencies := pendingLatencies reject: [ :assoc | assoc value <= 0 ].
	(messages isEmpty and: [ pendingLatencies isEmpty ])
		ifTrue: [ state := #idle ]
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> isPartitionedFrom: sourceAddress to: destinationAddress [
	^ partitions includes: (Array with: sourceAddress with: destinationAddress)
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> latencyFor: aMessage [
	^ latencyTable 
		at: (Array with: aMessage sourceAddress with: aMessage destinationAddress) 
		ifAbsent: [ 0 ]
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> outputFunction [
	| msg |
	state = #processing ifFalse: [ ^ self ].
	messages ifEmpty: [ ^ self ].
	msg := messages removeFirst.
	self poke: msg to: (hostMapping at: msg destinationAddress) name
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> setLatencyBetween: sourceAddress and: destinationAddress delay: ticks [
	latencyTable at: (Array with: sourceAddress with: destinationAddress) put: ticks
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> shouldDropMessage: aMessage [
	| key remaining |
	(self isPartitionedFrom: aMessage sourceAddress to: aMessage destinationAddress)
		ifTrue: [ ^ true ].
	key := Array with: aMessage sourceAddress with: aMessage destinationAddress.
	remaining := dropCounts at: key ifAbsent: [ ^ false ].
	remaining <= 0 ifTrue: [ ^ false ].
	dropCounts at: key put: remaining - 1.
	^ true
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> simulateNetworkPartition: addr1 and: addr2 [
	partitions add: (Array with: addr1 with: addr2).
	partitions add: (Array with: addr2 with: addr1)
]
