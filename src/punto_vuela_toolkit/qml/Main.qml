import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1240
    height: 780
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: "Punto Vuela Linux Toolkit"
    color: "#111214"

    property string activePage: "Inicio"
    property color accent: "#F3D54E"
    property color panel: "#1B1D20"
    property color muted: "#9A9DA3"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 238
            Layout.fillHeight: true
            color: "#17191C"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 18

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        width: 44; height: 44; radius: 14
                        color: accent
                        Image { anchors.fill: parent; anchors.margins: 7; source: Qt.resolvedUrl("../assets/logotipovuela.svg"); fillMode: Image.PreserveAspectFit; visible: status === Image.Ready }
                    }
                    Column {
                        spacing: 2
                        Text { text: "PUNTO VUELA"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1.2 }
                        Text { text: "LINUX TOOLKIT"; color: accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#303237" }

                Text { text: "ESPACIO DE TRABAJO"; color: muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                Repeater {
                    model: [
                        {name:"Inicio", glyph:"⌂"},
                        {name:"Punto Vuela", glyph:"V"},
                        {name:"Catálogo AppImage", glyph:"▦"},
                        {name:"Mis aplicaciones", glyph:"▣"},
                        {name:"Actualizaciones", glyph:"↻"}
                    ]
                    delegate: Item {
                        Layout.fillWidth: true
                        height: 43
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: activePage === modelData.name ? "#343126" : "transparent"
                            Rectangle { width: 3; height: 22; radius: 2; color: accent; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; visible: activePage === modelData.name }
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            spacing: 13
                            Text { text: modelData.glyph; color: activePage === modelData.name ? accent : "#B9BBC0"; font.pixelSize: 18; width: 18; horizontalAlignment: Text.AlignHCenter }
                            Text { text: modelData.name; color: activePage === modelData.name ? "#FFFFFF" : "#B9BBC0"; font.pixelSize: 13; font.weight: activePage === modelData.name ? Font.DemiBold : Font.Normal }
                        }
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData.name; cursorShape: Qt.PointingHandCursor }
                    }
                }

                Item { Layout.fillHeight: true }
                Text { text: "SISTEMA"; color: muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                Repeater {
                    model: ["Diagnóstico", "Configuración"]
                    delegate: Text {
                        Layout.fillWidth: true
                        text: "  ◦   " + modelData
                        color: activePage === modelData ? "#FFFFFF" : "#B9BBC0"
                        font.pixelSize: 13
                        padding: 10
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData; cursorShape: Qt.PointingHandCursor }
                    }
                }
                Text { text: "VERSIÓN 0.1.0 · PREVIEW"; color: "#686B71"; font.pixelSize: 9; Layout.bottomMargin: 4 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#111214"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 34
                spacing: 24

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 5
                        Text { text: activePage; color: "#FFFFFF"; font.pixelSize: 27; font.bold: true }
                        Text { text: "Tu espacio para descubrir y mantener aplicaciones Linux"; color: muted; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        radius: 10; color: "#202226"; border.color: "#34363B"
                        Layout.preferredWidth: 250; Layout.preferredHeight: 40
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                            Text { text: "⌕"; color: muted; font.pixelSize: 20 }
                            Text { text: "Buscar aplicaciones..."; color: "#777A80"; font.pixelSize: 12 }
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: contentColumn.implicitHeight
                    clip: true
                    ColumnLayout {
                        id: contentColumn
                        width: parent.width
                        spacing: 22

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 190
                            radius: 18
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#393321" }
                                GradientStop { position: 1.0; color: "#24211A" }
                            }
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 28; spacing: 20
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 12
                                    Text { text: "Bienvenido a tu centro de software"; color: "#FFFFFF"; font.pixelSize: 22; font.bold: true }
                                    Text { text: "Las herramientas de Punto Vuela y tus aplicaciones Linux,
en un solo lugar."; color: "#D2D0C7"; font.pixelSize: 13; lineHeight: 1.35 }
                                    Rectangle {
                                        radius: 9; color: accent; Layout.preferredWidth: 154; Layout.preferredHeight: 38
                                        Text { anchors.centerIn: parent; text: "Explorar catálogo  →"; color: "#171717"; font.pixelSize: 12; font.bold: true }
                                        MouseArea { anchors.fill: parent; onClicked: activePage = "Catálogo AppImage"; cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                                Rectangle {
                                    width: 116; height: 116; radius: 28; color: "#F3D54E"
                                    Image { anchors.fill: parent; anchors.margins: 18; source: Qt.resolvedUrl("../assets/logotipovuela.svg"); fillMode: Image.PreserveAspectFit; visible: status === Image.Ready }
                                }
                            }
                        }

                        Text { text: "Accesos destacados"; color: "#FFFFFF"; font.pixelSize: 17; font.bold: true }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: width > 850 ? 3 : 2
                            columnSpacing: 14; rowSpacing: 14
                            Repeater {
                                model: [
                                    {title:"Antigravity Installer", desc:"Instalación y mantenimiento de Antigravity", url:"https://github.com/Montejaque/antigravity-installer-linux", tag:"PUNTO VUELA"},
                                    {title:"Claude Desktop Linux", desc:"Instalador de Claude Desktop para Linux", url:"https://github.com/Montejaque/claude-desktop-linux", tag:"PUNTO VUELA"},
                                    {title:"ChatGPT Installer", desc:"ChatGPT Desktop y Codex CLI", url:"https://github.com/Montejaque/chatgpt-installer-linux", tag:"PUNTO VUELA"},
                                    {title:"VS Code Installer", desc:"Gestor de Visual Studio Code sin root", url:"https://github.com/Montejaque/vscode-installer-linux", tag:"PUNTO VUELA"},
                                    {title:"Brother MFC-J5740DW", desc:"Controlador y escáner sin root", url:"https://github.com/Montejaque/brother-mfc-j5740dw-sinroot", tag:"PUNTO VUELA"}
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 122
                                    radius: 13; color: panel; border.color: "#303237"
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 15; spacing: 7
                                        Text { text: modelData.tag; color: accent; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
                                        Text { text: modelData.title; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                                        Text { text: modelData.desc; color: muted; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                        Text { text: "Fuentes de aplicaciones"; color: "#FFFFFF"; font.pixelSize: 17; font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 14
                            Repeater {
                                model: [
                                    {title:"AppImageHub", desc:"Catálogo de aplicaciones AppImage", url:"https://www.appimagehub.com/"},
                                    {title:"AppImage Community", desc:"Catálogo comunitario oficial", url:"https://appimage.github.io/"}
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 88
                                    radius: 12; color: panel; border.color: "#303237"
                                    Column {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 7
                                        Text { text: modelData.title; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                                        Text { text: modelData.desc; color: muted; font.pixelSize: 11 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
