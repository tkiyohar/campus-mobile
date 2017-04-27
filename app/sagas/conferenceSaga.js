import { put, select, takeLatest } from 'redux-saga/effects';

const getConference = (state) => (state.conference);

function* addConference(action) {
	const conference = yield select(getConference);
	const saved = conference.saved.slice(); // copy array
	const schedule = conference.data;
	let contains = false;
	let addIndex = 0;
	// Make sure stop hasn't already been saved
	for (let i = 0;  i < saved.length; ++i) {
		if (saved[i] === action.id) {
			contains = true;
			break;
		}
		// figure out where to insert with respect to start time
		if (schedule[action.id]['time-start'] > schedule[saved[i]]['time-start']) {
			addIndex = i + 1;
		}
	}
	if (!contains) {
		yield put({ type: 'CHANGED_CONFERENCE_SAVED',
			saved: [...saved.slice(0, addIndex), action.id, ...saved.slice(addIndex)] });
	}
}

function* removeConference(action) {
	const conference = yield select(getConference);
	const saved = conference.saved.slice(); // copy array

	let i;
	// Remove stop from saved array
	for (i = 0; i < saved.length; ++i) {
		if (saved[i] === action.id) {
			saved.splice(i, 1);
			break;
		}
	}

	yield put({ type: 'CHANGED_CONFERENCE_SAVED', saved });
}

function* conferenceSaga() {
	yield takeLatest('ADD_CONFERENCE', addConference);
	yield takeLatest('REMOVE_CONFERENCE', removeConference);
}

export default conferenceSaga;
