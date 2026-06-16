"""Pure-unit checks of the request state machine (no DB)."""

from app.models.enums import RequestStatus
from app.services.request_service import _STATUS_TIMESTAMP, _TERMINAL, _TRANSITIONS


def test_forward_transitions_are_linear():
    assert _TRANSITIONS[RequestStatus.accepted] == RequestStatus.on_the_way
    assert _TRANSITIONS[RequestStatus.on_the_way] == RequestStatus.arrived
    assert _TRANSITIONS[RequestStatus.arrived] == RequestStatus.completed


def test_completed_has_no_forward_transition():
    assert RequestStatus.completed not in _TRANSITIONS
    assert RequestStatus.requested not in _TRANSITIONS  # requested -> accepted is via accept()


def test_terminal_states():
    assert _TERMINAL == {RequestStatus.completed, RequestStatus.cancelled}


def test_each_forward_status_records_a_timestamp():
    for target in (RequestStatus.on_the_way, RequestStatus.arrived, RequestStatus.completed):
        assert target in _STATUS_TIMESTAMP
        assert _STATUS_TIMESTAMP[target].endswith("_at")
