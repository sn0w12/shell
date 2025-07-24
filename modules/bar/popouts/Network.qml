import qs.widgets
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.normal

    StyledText {
        text: {
            if (!Network.active) {
                return qsTr("Connected to: None");
            } else {
                return qsTr("Connected to: %1").arg(
                    Network.active.type === "wifi"
                        ? Network.active.ssid
                        : Network.active.connection
                );
            }
        }
    }

    StyledText {
        visible: !!Network.active
        text: {
            if (!Network.active) return "";
            if (Network.active.type === "wifi")
                return qsTr("Type: Wi‑Fi");
            else if (Network.active.type === "ethernet")
                return qsTr("Type: Ethernet");
            else
                return qsTr("Type: %1").arg(Network.active.type);
        }
    }

    StyledText {
        visible: Network.active?.type === "wifi"
        text: qsTr("Strength: %1/100").arg(Network.active?.strength ?? 0)
    }

    StyledText {
        visible: Network.active?.type === "wifi"
        text: qsTr("Frequency: %1 MHz").arg(Network.active?.frequency ?? 0)
    }
}
