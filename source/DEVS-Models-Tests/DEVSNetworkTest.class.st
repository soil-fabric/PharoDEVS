Class {
	#name : 'DEVSNetworkTest',
	#superclass : 'TestCase',
	#category : 'DEVS-Models-Tests',
	#package : 'DEVS-Models-Tests'
}

{ #category : 'as yet unclassified' }
DEVSNetworkTest >> echoNetwork [ 
	| network  |
	network := DEVSNetwork new name: 'network'.

	network addHost: ((DEVSNetworkHost new 
		name: 'host1';
		address: '10.0.0.1')
			addServer: (DEVSPluggableServer new 
		name: 'server1';
		port: 7001);
			yourself).

	network addHost: ((DEVSNetworkHost new 
		name: 'host2';
		address: '10.0.0.2')
			addServer: (DEVSEchoServer new 
				name: 'server2';
				port: 7001);
			yourself).
	^ network 

]

{ #category : 'as yet unclassified' }
DEVSNetworkTest >> simulation: model [ 
	^ DEVSSimulation new 
		model: model;
		coordinator: DEVSRootSolver new
]

{ #category : 'tests' }
DEVSNetworkTest >> testRoundtrip [
	| simulation received payload |
	simulation := self simulation: self echoNetwork.
	(simulation / #host1 / #server1)
		send: #foo to: '10.0.0.2' port: 7001;
		onIncomingDo: [ :message :server |
			received := true.
			payload := message payload.
			nil ].
	simulation
		runTo: 10.
	self assert: received.
	self assert: payload equals: #foo
]

{ #category : 'tests' }
DEVSNetworkTest >> testRunToCalledTwiceContinuesTheRun [
	"Was the reproduction of the gap and is now its proof. DEVSRootSolver>>prepareToStart
	used to resend #receiveMsgInitTime: on every #runTo:, so a second call on an
	already advanced model was a second start rather than a continuation - it failed
	the assertion that timeNext lies ahead, or ran and delivered nothing because
	savedTimeAdvance still held what the model was doing at the last transition.

	See PharoDEVS doc.md, 'Praxis-Erkenntnis: DEVSRootSolver unterstuetzt keine
	schrittweise Fortsetzung'."

	| simulation |
	simulation := self simulation: self echoNetwork.
	simulation runTo: 10.
	self shouldnt: [ simulation runTo: 20 ] raise: Error.
	self assert: simulation coordinator time >= 10
]
