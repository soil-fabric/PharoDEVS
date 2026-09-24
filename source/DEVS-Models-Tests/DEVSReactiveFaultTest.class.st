"
A fault whose moment is decided by the run, not before it.

This is what the two gaps were in the way of, and it took both of them. A subscriber has to be called while the simulation is going - DEVSSimulation>>when:do: - and the run has to be able to carry on afterwards, which it could not: every #runTo: used to re-send #receiveMsgInitTime: to the model, so a second one was a second start rather than a continuation.

The scenario written down in PharoDEVS doc.md since 2026-08-04: build a network as a running base simulation, and inject faults reactively - 'when host A has sent a message, the network fails'. The moment is not in the model, it follows from what the model did.
"
Class {
	#name : 'DEVSReactiveFaultTest',
	#superclass : 'TestCase',
	#instVars : [
		'network',
		'serverA',
		'serverB',
		'received',
		'simulation'
	],
	#category : 'DEVS-Models-Tests',
	#package : 'DEVS-Models-Tests'
}

{ #category : 'running' }
DEVSReactiveFaultTest >> router [
	^ network router
]

{ #category : 'running' }
DEVSReactiveFaultTest >> setUp [
	"A sends every ten ticks from inside the model, so that sending is part of the
	run rather than something done to it from outside."

	super setUp.
	received := OrderedCollection new.
	network := DEVSNetwork new
		           name: #net;
		           yourself.
	network router: DEVSFaultInjectingNetworkRouter new.
	serverA := DEVSPluggableServer new
		           name: #serverA;
		           port: 1;
		           yourself.
	serverB := DEVSPluggableServer new
		           name: #serverB;
		           port: 1;
		           yourself.
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
	serverB onIncomingDo: [ :message :each |
		received add: message payload.
		nil ].
	serverA every: 10 do: [ :each | each send: 'ping' to: 'b' port: 1 ].
	simulation := DEVSSimulation new.
	simulation model: network.
	simulation coordinator: DEVSRootSolver new
]

{ #category : 'tests' }
DEVSReactiveFaultTest >> testAFaultCanBeDecidedByTheRun [
	"Cut the network the moment the first message has arrived, and nothing arrives
	afterwards - although A keeps sending every ten ticks."

	simulation when: DEVSInternalTransitionEvent do: [ :event |
		received isEmpty ifFalse: [
			self router simulateNetworkPartition: 'a' and: 'b' ] ].
	simulation runTo: 100.
	self assert: received size equals: 1
]

{ #category : 'tests' }
DEVSReactiveFaultTest >> testWithoutAFaultEverythingArrives [
	"The same run with nobody interfering, so that the test above is about the
	fault rather than about the model falling silent on its own."

	simulation runTo: 100.
	self assert: received size > 5
]

{ #category : 'tests' }
DEVSReactiveFaultTest >> testARunContinuesWhereItStopped [
	"And it can be taken up again, which is what lets a scenario look at the model
	between two stretches of time instead of only at the end."

	simulation runTo: 30.
	self assert: received notEmpty.
	self assert: (simulation coordinator time between: 30 and: 45).
	simulation runTo: 100.
	self assert: received size > 5
]
