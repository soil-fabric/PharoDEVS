"
A server that also acts on its own: two hosts, one of which sends a message every so many ticks without having been asked.
"
Class {
	#name : 'DEVSPluggableServerTest',
	#superclass : 'TestCase',
	#instVars : [
		'network',
		'serverA',
		'serverB',
		'received'
	],
	#category : 'DEVS-Models-Tests',
	#package : 'DEVS-Models-Tests'
}

{ #category : 'running' }
DEVSPluggableServerTest >> runSimulationFor: ticks [
	| simulation |
	simulation := DEVSSimulation new.
	simulation model: network.
	simulation coordinator: DEVSRootSolver new.
	simulation runTo: ticks
]

{ #category : 'running' }
DEVSPluggableServerTest >> setUp [
	super setUp.
	received := OrderedCollection new.
	network := DEVSNetwork new name: #net; yourself.
	serverA := DEVSPluggableServer new name: #serverA; port: 1; yourself.
	serverB := DEVSPluggableServer new name: #serverB; port: 1; yourself.
	network addHost: (DEVSNetworkHost new
		name: #hostA;
		address: 'a';
		addServer: serverA;
		yourself).
	network addHost: (DEVSNetworkHost new
		name: #hostB;
		address: 'b';
		addServer: serverB;
		yourself).
	serverB onIncomingDo: [ :message :srv | received add: message payload. nil ]
]

{ #category : 'tests' }
DEVSPluggableServerTest >> testAServerWithoutAHeartbeatSendsNothingOfItsOwn [
	self runSimulationFor: 100.
	self assert: received isEmpty
]

{ #category : 'tests' }
DEVSPluggableServerTest >> testTheHeartbeatSendsOncePerPeriod [
	"Ten ticks apart over a hundred ticks: around ten messages, and certainly not
	one and not a hundred. The solver may run one event past the limit, so the
	count is checked as an interval."
	serverA every: 10 do: [ :srv | srv send: 'ping' to: 'b' port: 1 ].
	self runSimulationFor: 100.
	self assert: (received size between: 9 and: 11)
]

{ #category : 'tests' }
DEVSPluggableServerTest >> testWhatOneHeartbeatDoesTheNextOneSees [
	"The reason the heartbeat exists: a round that builds on the one before it.
	Stirring a model before the run puts everything at time zero instead."
	| sent |
	sent := 0.
	serverA every: 10 do: [ :srv |
		sent := sent + 1.
		srv send: sent printString to: 'b' port: 1 ].
	self runSimulationFor: 35.
	self assert: (received first: 3) asArray equals: #( '1' '2' '3' )
]
