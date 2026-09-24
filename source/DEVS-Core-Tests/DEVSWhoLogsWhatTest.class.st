"
Who writes down that something was sent - and that nobody writes it down twice.

A component produces output in #receiveMsgStarTime:, and that is where it says so. The root solver used to say it as well, on top of whatever the root had already said. For a coupled root that was the only record of the root's own output, so it looked necessary; for an atomic root it was a second copy of what the component had just logged.

Now every component logs what it sent, atomic and coupled alike, and the solver only drives. The coupled root still appears in the log, and the atomic one appears once.
"
Class {
	#name : 'DEVSWhoLogsWhatTest',
	#superclass : 'TestCase',
	#category : 'DEVS-Core-Tests',
	#package : 'DEVS-Core-Tests'
}

{ #category : 'running' }
DEVSWhoLogsWhatTest >> eventsOf: aModel [
	| simulation |
	simulation := DEVSSimulation new.
	simulation model: aModel.
	simulation coordinator: DEVSRootSolver new.
	simulation runTo: 25.
	^ simulation logger events
]

{ #category : 'running' }
DEVSWhoLogsWhatTest >> tickerNamed: aSymbol [
	^ DEVSTickingAtomic new
		  name: aSymbol;
		  interval: 10;
		  yourself
]

{ #category : 'tests' }
DEVSWhoLogsWhatTest >> testAnAtomicRootIsWrittenDownOnce [
	"It was twice: the component logged itself at the end of #receiveMsgStarTime:
	and the solver logged it again straight after."

	| times |
	times := (self eventsOf: (self tickerNamed: #ticker)) collect: [ :each |
		         each time ].
	self assert: times asArray equals: (times asSet asSortedCollection asArray)
]

{ #category : 'tests' }
DEVSWhoLogsWhatTest >> testACoupledRootIsStillWrittenDown [
	"What the solver used to do is now done by the coupled component itself, so
	nothing is lost: the root still says what it sent."

	| net names |
	net := DEVSCoupledComponent new
		       name: #net;
		       yourself.
	net addComponent: (self tickerNamed: #inner).
	names := (self eventsOf: net) collect: [ :each |
		         [ each component name ] on: Error do: [ :e | nil ] ].
	self assert: (names includes: #net).
	self assert: (names includes: #inner)
]
