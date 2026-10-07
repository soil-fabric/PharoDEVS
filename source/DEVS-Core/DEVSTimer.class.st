"
Waiting for a real time value, and being woken up before it. How to use:

	| t |
	t := DEVSTimer at: Time millisecondClockValue + 10000.
	t wait.

	""waiting can be stopped by t unschedule""

This used to be a Delay that scheduled itself through Delay's class variables (TimerEventLoop, AccessProtect, ActiveDelay, SuspendedDelays). They are gone since Delay got its scheduler, so the real-time solvers could not make a single step. A semaphore with a timeout does the same with public protocol only.

An #unschedule that comes before #wait is not lost: the wait returns at once. That is what the real-time solver needs when an input is injected while it is still busy with the previous step.
"
Class {
	#name : 'DEVSTimer',
	#superclass : 'Object',
	#instVars : [
		'semaphore',
		'resumptionTime'
	],
	#category : 'DEVS-Core-RT',
	#package : 'DEVS-Core',
	#tag : 'RT'
}

{ #category : 'instance creation' }
DEVSTimer class >> at: time [
	"time is a value of Time millisecondClockValue. SmallInteger maxVal means never."

	^ self new setResumptionTime: time
]

{ #category : 'initialization' }
DEVSTimer >> initialize [

	super initialize.
	semaphore := Semaphore new
]

{ #category : 'accessing' }
DEVSTimer >> resumptionTime [

	^ resumptionTime
]

{ #category : 'initialization' }
DEVSTimer >> setResumptionTime: time [

	resumptionTime := time
]

{ #category : 'waiting' }
DEVSTimer >> unschedule [

	semaphore signal
]

{ #category : 'waiting' }
DEVSTimer >> wait [

	| remaining |
	resumptionTime >= SmallInteger maxVal ifTrue: [ ^ semaphore wait ].
	remaining := resumptionTime - Time millisecondClockValue.
	remaining > 0 ifTrue: [ semaphore waitTimeoutMilliseconds: remaining ]
]
