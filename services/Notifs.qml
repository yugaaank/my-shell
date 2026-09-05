pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Session notification history + DND. Wraps NotificationServer in lightweight
// QtObject records (ii Notifications.qml:19-43 pattern) instead of live
// Notification refs, so the center survives dismissal. No popups here —
// center only; toasts are the follow-up.
// ponytail: session-only list, in-memory DND; persist both when it hurts.
Singleton {
    id: root

    property list<Notif> list: []
    property int unread: 0
    property bool dnd: false
    property var toastItem: null
    property bool toastVisible: false

    // {appName, items[]} newest-first, ii TaskbarApps grouping shape.
    readonly property var groups: {
        const map = new Map();
        for (const n of root.list) {
            const key = n.appName || "Unknown";
            if (!map.has(key))
                map.set(key, { appName: key, items: [] });
            map.get(key).items.push(n);
        }
        return Array.from(map.values());
    }

    function markRead(): void {
        root.unread = 0;
    }

    function hideToast(): void {
        root.toastVisible = false;
        root.toastItem = null;
    }

    Timer {
        id: toastTimer
        interval: 5000
        onTriggered: root.hideToast()
    }

    function dismiss(id: int): void {
        const target = root.list.find(n => n.notificationId === id);
        if (target?.notification)
            target.notification.dismiss();
        if (root.toastItem?.notificationId === id)
            root.hideToast();
        root.list = root.list.filter(n => n.notificationId !== id);
    }

    function clearApp(appName: string): void {
        for (const n of root.list.filter(n => (n.appName || "Unknown") === appName))
            n.notification?.dismiss();
        root.list = root.list.filter(n => (n.appName || "Unknown") !== appName);
    }

    function clearAll(): void {
        for (const n of root.list.slice())
            n.notification?.dismiss();
        root.list = [];
        root.unread = 0;
        root.hideToast();
    }

    function toggleDnd(): void {
        root.dnd = !root.dnd;
    }

    component Notif: QtObject {
        required property int notificationId
        property Notification notification
        property string summary: notification?.summary ?? ""
        property string body: notification?.body ?? ""
        property string appName: notification?.appName ?? ""
        property string appIcon: notification?.appIcon ?? ""
        property string image: notification?.image ?? ""
        property string time: Qt.formatDateTime(new Date(), "HH:mm")
        property list<var> actions: notification?.actions.map(a => ({
                    identifier: a.identifier,
                    text: a.text,
                    invoke: () => a.invoke()
                })) ?? []
    }

    Component {
        id: notifComp

        Notif {}
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;
            const rec = notifComp.createObject(root, {
                notificationId: notif.id,
                notification: notif
            });
            root.list = [rec, ...root.list];
            if (!root.dnd) {
                root.unread++;
                root.toastItem = rec;
                root.toastVisible = true;
                toastTimer.restart();
            }
        }
    }
}
