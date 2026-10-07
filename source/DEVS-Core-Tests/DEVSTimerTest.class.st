"
The timer the real-time solvers wait on: it waits until a value of the millisecond clock, and an #unschedule wakes it earlier - also one that came before the wait.
"
Class {
	#name : 'DEVSTimerTest',
	#superclass : 'TestCase',
	#category : 'DEVS-Core-Tests',
	#package : 'DEVS-Core-Tests'
}

{ #category : 'running' }
DEVSTimerTest >> millisecondsToWaitOn: aTimer [

	^ Time millisecondsToRun: [ aTimer wait ]
]

{ #category : 'tests' }
DEVSTimerTest >> testATimeInThePastDoesNotWait [

	| timer |
	timer := DEVSTimer at: Time millisecondClockValue - 1000.
	self assert: (self millisecondsToWaitOn: timer) < 500
]

{ #category : 'tests' }
DEVSTimerTest >> testAnUnscheduleBeforeTheWaitIsNotLost [
	"The solver injects while the previous step is still running; the next wait must
	not sleep through it."

	| timer |
	timer := DEVSTimer at: Time millisecondClockValue + 10000.
	timer unschedule.
	self assert: (self millisecondsToWaitOn: timer) < 500
]

{ #category : 'tests' }
DEVSTimerTest >> testItWaitsUntilItsTime [

	| timer |
	timer := DEVSTimer at: Time millisecondClockValue + 100.
	timer wait.
	self assert: Time millisecondClockValue >= timer resumptionTime
]

{ #category : 'tests' }
DEVSTimerTest >> testUnscheduleWakesAWaiter [

	| timer |
	timer := DEVSTimer at: Time millisecondClockValue + 10000.
	[
	(Delay forMilliseconds: 20) wait.
	timer unschedule ] fork.
	self assert: (self millisecondsToWaitOn: timer) < 5000
]
