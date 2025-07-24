pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null

    reloadableId: "network"

    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: getNetworks
        running: true
        command: [
            "bash", "-c",
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device && echo '---' && nmcli -g ACTIVE,SIGNAL,FREQ,SSID,BSSID device wifi"
        ]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const [deviceText, wifiText] = text.split("\n---\n");

                const devices = deviceText.trim().split("\n").filter(Boolean).map(n => {
                    const net = n.split(":");
                    const device = net[0];
                    const type = net[1];
                    const state = net[2];
                    const connection = net.slice(3).join(":");
                    return {
                        active: state === "connected",
                        strength: 100,
                        frequency: 0,
                        ssid: type === "wifi" ? (connection || device) : "",
                        bssid: ""
                        device,
                        type,
                        connection: connection || device,
                    };
                });

                const rep = new RegExp("\\\\:", "g");
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const wifiInfo = (wifiText || "").trim().split("\n").filter(Boolean).map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3],
                        bssid: net[4]?.replace(rep2, ":") ?? ""
                    };
                });

                for (const wifi of wifiInfo) {
                    const entry = devices.find(d => d.type === "wifi" && d.connection === wifi.ssid);
                    if (entry) {
                        entry.strength = wifi.strength;
                        entry.frequency = wifi.frequency;
                        entry.bssid = wifi.bssid;
                        entry.active = wifi.active;
                    }
                }

                const rNetworks = root.networks;
                const destroyed = rNetworks.filter(
                    rn => !devices.find(d => d.device === rn.device)
                );
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const dev of devices) {
                    const match = rNetworks.find(n => n.device === dev.device);
                    if (match) {
                        match.lastIpcObject = dev;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: dev
                        }));
                    }
                }
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string device: lastIpcObject.device
        readonly property string type: lastIpcObject.type
        readonly property string connection: lastIpcObject.connection
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
    }

    Component {
        id: apComp

        AccessPoint {}
    }
}
