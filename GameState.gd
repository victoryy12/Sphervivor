extends Node

enum State {
	PLAY,
	PAUSED,
	UPGRADE
}

var state: State = State.PLAY
