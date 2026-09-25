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
	"Both directions again, because #simulateNetworkPartition:and: cut both."

	self healPartitionFrom: addr1 to: addr2.
	self healPartitionFrom: addr2 to: addr1
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> healPartitionFrom: sourceAddress to: destinationAddress [

	partitions remove: (Array with: sourceAddress with: destinationAddress) ifAbsent: [  ]
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
	"The ordinary case, both directions at once. For one direction alone see
	#simulateNetworkPartitionFrom:to:."

	self simulateNetworkPartitionFrom: addr1 to: addr2.
	self simulateNetworkPartitionFrom: addr2 to: addr1
]

{ #category : 'as yet unclassified' }
DEVSFaultInjectingNetworkRouter >> simulateNetworkPartitionFrom: sourceAddress to: destinationAddress [
	"One direction only: nothing gets from the source to the destination, while
	everything the other way still arrives.

	The mechanism could always do this - #partitions holds ordered pairs and
	#isPartitionedFrom:to: asks directionally - only the two ways of setting it up
	both cut both directions, so it was there and unreachable.

	Worth having because an asymmetric partition is the case where a node thinks
	itself healthy while others have given up on it: it keeps hearing them, so
	nothing looks wrong from where it stands, and it keeps sending into a void. A
	failure detector that is only ever shown symmetric cuts is never shown its
	hardest case."

	partitions add: (Array with: sourceAddress with: destinationAddress)
]
