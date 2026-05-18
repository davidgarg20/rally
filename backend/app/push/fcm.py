from __future__ import annotations
from dataclasses import dataclass

from app.config import settings


@dataclass
class PushMessage:
    firebase_uid: str
    title: str
    body: str
    data: dict[str, str]


_sent: list[PushMessage] = []


def sent_messages() -> list[PushMessage]:
    return list(_sent)


def clear_sent_messages() -> None:
    _sent.clear()


async def send_to_uid(uid: str, title: str, body: str,
                     data: dict[str, str] | None = None) -> None:
    msg = PushMessage(firebase_uid=uid, title=title, body=body, data=data or {})

    if settings.env == "dev" or not settings.firebase_credentials_path:
        _sent.append(msg)
        return

    import firebase_admin
    from firebase_admin import credentials, messaging
    if not firebase_admin._apps:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        firebase_admin.initialize_app(cred)
    fcm_msg = messaging.Message(
        topic=f"user-{uid}",
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
    )
    messaging.send(fcm_msg)
