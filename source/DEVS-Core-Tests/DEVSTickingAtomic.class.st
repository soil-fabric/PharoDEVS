"
An atomic component whose whole behaviour is to wake up at a steady interval.

DEVSTestAtomic answers a time advance but has no outputFunction, so it cannot be run - it is there to be asked, not to be simulated. This one can be run and does nothing while it runs, which is what a test about events needs: something that produces internal transitions and no other reason to fail.
"
Class {
	#name : 'DEVSTickingAtomic',
	#superclass : 'DEVSAtomicComponent',
	#instVars : [
		'interval'
	],
	#category : 'DEVS-Core-Tests',
	#package : 'DEVS-Core-Tests'
}

{ #category : 'accessing' }
DEVSTickingAtomic >> interval: anInteger [
	interval := anInteger
]

{ #category : 'modeling' }
DEVSTickingAtomic >> internalTransition [
]

{ #category : 'modeling' }
DEVSTickingAtomic >> outputFunction [
]

{ #category : 'modeling' }
DEVSTickingAtomic >> timeAdvance [
	^ interval ifNil: [ interval := 10 ]
]
