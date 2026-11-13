import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings

ApplicationWindow {
    id: window
    width: 1240
    height: 780
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: "Puntos Vuela Toolkit"
    property string activePage: "Inicio"
    property color accent: "#FAD100"
    property string themeMode: appSettings.savedThemeMode
    property bool darkTheme: themeMode === "dark" || (themeMode === "system" && systemPalette.window.hslLightness < 0.5)

    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }
    Settings {
        id: appSettings
        category: "appearance"
        property string savedThemeMode: "dark"
    }

    readonly property color backgroundColor: darkTheme ? "#252B31" : "#F3F4F6"
    readonly property color sidebarColor: "#FAD100"
    readonly property color panel: darkTheme ? "#303740" : "#FFFFFF"
    readonly property color panelBorder: darkTheme ? "#3A424C" : "#E1E3E8"
    readonly property color primaryText: darkTheme ? "#F7F8FA" : "#202226"
    readonly property color secondaryText: darkTheme ? "#C2C8D0" : "#555B65"
    readonly property color muted: darkTheme ? "#929BA6" : "#737984"
    readonly property color searchColor: darkTheme ? "#252B31" : "#FFFFFF"
    readonly property color selectedNavigation: darkTheme ? "#343126" : "#FFF6D2"
    readonly property color heroStart: darkTheme ? "#34303D" : "#FFF1B8"
    readonly property color heroEnd: darkTheme ? "#292F38" : "#F8E7A0"

    property bool previewVisible: false
    property bool dataProtectionRead: false
    property bool privacyPolicyRead: false
    property var appImageItems: []
    property var catalogItems: []
    property bool catalogLoading: false
    property var selectedCatalogApp: null
    property string catalogCategory: "Todas"
    property var filteredCatalogItems: catalogItems.filter(item => catalogCategory === "Todas" || item.category === catalogCategory)
    property string selectedCategory: "Todas"
    property string selectedAppName: ""
    property var puntoVuelaTools: []
    property var toolkitRelease: ({})
    property bool puntoVuelaLoading: false
    property string puntoVuelaStatus: "Consultando repositorios públicos de GitHub…"
    property var featuredApps: puntoVuelaTools.map(item => ({
        title:item.name, category:item.category, kind:item.kind,
        desc:item.description, url:item.repositoryUrl, repository:item.repository, image:"", tag:"PUNTO VUELA",
        version:item.version, releaseUrl:item.releaseUrl, downloadUrl:item.downloadUrl
    }))
    property var allHomeApps: featuredApps.concat(catalogItems.map(item => ({title:item.name,category:item.category,kind:"AppImage oficial",desc:item.description||"Aplicación del catálogo oficial.",url:item.catalogUrl,image:item.iconUrl,tag:"CATÁLOGO OFICIAL",official:true})))
    property var visibleFeaturedApps: allHomeApps.filter(item => selectedCategory === "Todas" || item.category === selectedCategory)

    Component.onCompleted: {
        puntoVuelaLoading = true
        appImageManager.loadPuntoVuelaTools()
        appImageManager.loadToolkitRelease()
    }

    function refreshCatalog() {
        catalogLoading = true
        appImageManager.loadCatalog(catalogSearch.text.trim())
    }

    Connections {
        target: appImageManager
        function onEmailSent(payload) {
            const result = JSON.parse(payload)
            emailStatus.text = result.message || "Resultado del envío"
            emailStatus.color = result.ok ? "#62B47A" : "#D65A5A"
            if (result.ok) previewVisible = false
        }
        function onPuntoVuelaToolsLoaded(payload) {
            const result = JSON.parse(payload)
            if (result.ok) puntoVuelaTools = result.items || []
            puntoVuelaStatus = result.message || "Catálogo de GitHub actualizado."
            puntoVuelaLoading = false
        }
        function onToolkitReleaseLoaded(payload) { toolkitRelease = JSON.parse(payload) }
        function onCatalogLoaded(payload) {
            const result = JSON.parse(payload)
            catalogItems = result.items || []
            catalogStatus.text = result.message || ""
            catalogLoading = false
        }
        function onCatalogInstallFinished(payload) {
            const result = JSON.parse(payload)
            catalogStatus.text = result.message || "La operación ha terminado."
            if (result.ok) refreshAppImages()
        }
        function onAppImageDownloadFinished(payload) {
            const result = JSON.parse(payload)
            appImageStatus.text = result.message || ""
            if (result.ok) { appImageUrl.text = ""; refreshAppImages() }
        }
        function onAppImageUpdateCheckFinished(payload) {
            const result = JSON.parse(payload)
            appImageStatus.text = result.path.split("/").pop() + ": " + result.message
            if (result.available) appImageStatus.text += " · Hay una actualización. Pulsa Actualizar."
        }
        function onAppImageUpdated(payload) {
            const result = JSON.parse(payload)
            appImageStatus.text = result.message || ""
            refreshAppImages()
        }
    }

    Dialog {
        id: removeDialog
        property string targetPath: ""
        title: "Eliminar AppImage"
        modal: true
        standardButtons: Dialog.Yes | Dialog.Cancel
        Label { text: "¿Quieres eliminar este archivo de la carpeta de aplicaciones? No se puede deshacer."; wrapMode: Text.WordWrap }
        onAccepted: {
            const result = JSON.parse(appImageManager.removeAppImage(targetPath))
            appImageStatus.text = result.message
            refreshAppImages()
        }
    }

    Dialog {
        id: dataProtectionDialog
        modal: true
        title: "Información sobre protección de datos"
        width: Math.min(window.width - 48, 680)
        height: Math.min(window.height - 48, 620)
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton
        contentItem: ColumnLayout {
            spacing: 12
            Label { Layout.fillWidth: true; text: "Responsable: Consorcio Puntos Vuela de Andalucía (CPV)."; font.bold: true; wrapMode: Text.WordWrap }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; color: secondaryText
                    text: "Finalidad: recibir, revisar y responder a propuestas profesionales de los AIL de los centros Puntos Vuela.\n\nDatos: centro, municipio, datos profesionales de contacto, aplicación propuesta, enlace, distribución, necesidad y observaciones.\n\nDestinatario: las propuestas se remiten a montejaque@puntosvuela.es. El correo indicado por el AIL recibe una copia.\n\nProveedores: Cloudflare Workers y Gmail API. La aplicación no mantiene una base de datos propia de propuestas ni crea expedientes; el contenido queda en los buzones de correo.\n\nMantenimiento técnico y gestión operativa del buzón: Francisco Javier Gallego Orellana, AIL del Punto Vuela de Montejaque.\n\nNo incluyas contraseñas, documentos de identidad ni datos personales innecesarios."
                }
            }
            Label { Layout.fillWidth: true; text: "La base jurídica aplicable es la que corresponda a las funciones del Consorcio y debe estar documentada por este."; color: muted; wrapMode: Text.WordWrap; font.pixelSize: 11 }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Cerrar"; onClicked: dataProtectionDialog.close() }
                Button { text: "He leído esta información"; highlighted: true; onClicked: { dataProtectionRead = true; dataProtectionDialog.close() } }
            }
        }
    }

    Dialog {
        id: privacyPolicyDialog
        modal: true
        title: "Política de privacidad"
        width: Math.min(window.width - 48, 680)
        height: Math.min(window.height - 48, 620)
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton
        contentItem: ColumnLayout {
            spacing: 12
            Label { Layout.fillWidth: true; text: "Puntos Vuela Toolkit · Consorcio Puntos Vuela de Andalucía"; font.bold: true; wrapMode: Text.WordWrap }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                Label {
                    width: parent.width; wrapMode: Text.WordWrap; color: secondaryText
                    text: "La política completa explica los datos tratados, finalidades, proveedores tecnológicos, conservación, seguridad y ejercicio de derechos.\n\nDelegado de Protección de Datos: delegadoprotecciondatos.cfr@puntosvuela.es\n\nBuzón central de propuestas: montejaque@puntosvuela.es"
                }
            }
            Label {
                Layout.fillWidth: true
                text: '<a href="https://github.com/Montejaque/punto-vuela-linux-toolkit/blob/main/privacy.md">Abrir política de privacidad completa</a>'
                textFormat: Text.RichText; color: accent
                onLinkActivated: Qt.openUrlExternally(link)
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button { text: "Cerrar"; onClicked: privacyPolicyDialog.close() }
                Button { text: "He leído la política"; highlighted: true; onClicked: { privacyPolicyRead = true; privacyPolicyDialog.close() } }
            }
        }
    }
    function refreshAppImages() {
        appImageItems = JSON.parse(appImageManager.listAppImages())
    }

    function setThemeMode(mode) {
        themeMode = mode
        appSettings.savedThemeMode = mode
    }
    color: backgroundColor
    Component.onCompleted: refreshCatalog()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 238
            Layout.fillHeight: true
            color: sidebarColor

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
                        Image { anchors.fill: parent; anchors.margins: 3; source: Qt.resolvedUrl("../assets/logo_toolkit.svg"); fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true; asynchronous: true; sourceSize.width: 512; sourceSize.height: 512; visible: status === Image.Ready }
                    }
                    Column {
                        spacing: 2
                        Text { text: "PUNTOS VUELA"; color: "#202226"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1.2 }
                        Text { text: "TOOLKIT"; color: "#51430A"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#E0AD00" }

                Text { text: "ESPACIO DE TRABAJO"; color: "#665400"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                Repeater {
                    model: [
                        {name:"Inicio", glyph:"⌂"},
                        {name:"Catálogo AppImage", glyph:"▦"},
                        {name:"Mis aplicaciones", glyph:"▣"},
                        {name:"Contacto e información", glyph:"✉"}
                    ]
                    delegate: Item {
                        Layout.fillWidth: true
                        height: 43
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: activePage === modelData.name ? "#292F36" : "transparent"
                            Rectangle { width: 3; height: 22; radius: 2; color: accent; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; visible: activePage === modelData.name }
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            spacing: 13
                            Text { text: modelData.glyph; color: activePage === modelData.name ? "#FFC400" : "#292F36"; font.pixelSize: 18; width: 18; horizontalAlignment: Text.AlignHCenter }
                            Text { text: modelData.name; color: activePage === modelData.name ? "#FFFFFF" : "#292F36"; font.pixelSize: 13; font.weight: activePage === modelData.name ? Font.DemiBold : Font.Normal }
                        }
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData.name; cursorShape: Qt.PointingHandCursor }
                    }
                }

                Item { Layout.fillHeight: true }
                Text { text: "SISTEMA"; color: "#665400"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.1 }
                Repeater {
                    model: ["Ayuda"]
                    delegate: Text {
                        Layout.fillWidth: true
                        text: "  ◦   " + modelData
                        color: activePage === modelData ? "#292F36" : "#292F36"
                        font.pixelSize: 13
                        padding: 10
                        MouseArea { anchors.fill: parent; onClicked: activePage = modelData; cursorShape: Qt.PointingHandCursor }
                    }
                }
                Text { text: "VERSIÓN 0.1.0 · PREVIEW"; color: "#665400"; font.pixelSize: 9; Layout.bottomMargin: 4 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: backgroundColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 24

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 5
                        Text { text: activePage; color: primaryText; font.pixelSize: 27; font.bold: true }
                        Text { text: "Tu espacio para descubrir y mantener aplicaciones Linux"; color: muted; font.pixelSize: 13 }
                    }
                    Item { Layout.fillWidth: true }
                    TextField {
                        id: globalSearch
                        Layout.preferredWidth: 270
                        placeholderText: "Buscar aplicaciones..."
                        onAccepted: {
                            catalogSearch.text = text
                            activePage = "Catálogo AppImage"
                            refreshCatalog()
                        }
                    }
                    ToolButton {
                        id: themeButton
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 40
                        text: themeMode === "system" ? "◐" : (themeMode === "dark" ? "☾" : "☀")
                        font.pixelSize: 20
                        palette.buttonText: primaryText
                        ToolTip.visible: hovered
                        ToolTip.text: "Apariencia: " + (themeMode === "system" ? "Sistema" : (themeMode === "dark" ? "Oscuro" : "Claro"))
                        background: Rectangle { radius: 10; color: themeButton.hovered ? panelBorder : searchColor; border.color: panelBorder }
                        onClicked: themeMenu.open()
                        Menu {
                            id: themeMenu
                            y: themeButton.height
                            MenuItem { text: "◐  Según el sistema"; checkable: true; checked: themeMode === "system"; onTriggered: setThemeMode("system") }
                            MenuItem { text: "☀  Claro"; checkable: true; checked: themeMode === "light"; onTriggered: setThemeMode("light") }
                            MenuItem { text: "☾  Oscuro"; checkable: true; checked: themeMode === "dark"; onTriggered: setThemeMode("dark") }
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: activePage === "Contacto e información" ? contactPage.implicitHeight : (activePage === "Mis aplicaciones" ? appImagesPage.implicitHeight : (activePage === "Ayuda" ? helpPage.implicitHeight : (activePage === "Catálogo AppImage" ? catalogPage.implicitHeight : contentColumn.implicitHeight)))
                    clip: true
                    ColumnLayout {
                        id: contentColumn
                        width: parent.width
                        spacing: 22
                        visible: activePage !== "Contacto e información" && activePage !== "Mis aplicaciones" && activePage !== "Ayuda" && activePage !== "Catálogo AppImage"

                        Rectangle {
                            Layout.fillWidth:true; Layout.preferredHeight:248; radius:22; clip:true
                            gradient:Gradient {
                                GradientStop { position:0; color:darkTheme?"#332D1B":"#FFF0AE" }
                                GradientStop { position:1; color:darkTheme?"#211F1A":"#F8E4A0" }
                            }
                            RowLayout {
                                anchors.fill:parent; anchors.margins:28; spacing:24
                                ColumnLayout {
                                    Layout.fillWidth:true; spacing:12
                                    Text { text:"PUNTO VUELA · SOFTWARE HUB"; color:darkTheme?"#FAD100":"#76601B"; font.pixelSize:10; font.bold:true; font.letterSpacing:1.7 }
                                    Text { text:"Todo tu software Linux.\nEn un solo lugar."; color:darkTheme?"#FFFFFF":"#202226"; font.pixelSize:29; font.bold:true }
                                    Text { text:"Descubre herramientas, aplicaciones y utilidades seleccionadas para tu entorno de trabajo."; color:darkTheme?"#D3D0C7":"#55504A"; font.pixelSize:13; wrapMode:Text.WordWrap; Layout.fillWidth:true }
                                    Button { text:"Explorar aplicaciones  →"; onClicked:activePage="Catálogo AppImage" }
                                }
                                Item {
                                    Layout.preferredWidth:300; Layout.fillHeight:true
                                    Repeater {
                                        model:[
                                            {image:"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/openai.png",x:10,y:30,rotation:-9},
                                            {image:"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/vscode.png",x:105,y:8,rotation:7},
                                            {image:"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude.png",x:205,y:46,rotation:8}
                                        ]
                                        delegate:Rectangle {
                                            x:modelData.x;y:modelData.y;width:82;height:82;radius:19;rotation:modelData.rotation;color:"#FFFFFF";border.color:"#E6E2D5"
                                            Image { anchors.fill:parent;anchors.margins:14;source:modelData.image;fillMode:Image.PreserveAspectFit;asynchronous:true }
                                            SequentialAnimation on y {
                                                loops: Animation.Infinite
                                                NumberAnimation { to: modelData.y - 8; duration: 1500 + index * 160; easing.type: Easing.InOutSine }
                                                NumberAnimation { to: modelData.y; duration: 1500 + index * 160; easing.type: Easing.InOutSine }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth:true
                            Text { text:"Aplicaciones destacadas"; color:primaryText; font.pixelSize:19; font.bold:true }
                            Item { Layout.fillWidth:true }
                            Text { text:allHomeApps.length+" herramientas"; color:muted; font.pixelSize:11 }
                        }
                        Flow {
                            Layout.fillWidth:true; spacing:8
                            Repeater {
                                model:["Todas","Herramientas Puntos Vuela","IA y desarrollo","Desarrollo","Sistema y periféricos"]
                                delegate:Button { text:modelData; highlighted:selectedCategory===modelData; onClicked:selectedCategory=modelData }
                            }
                        }
                        GridLayout {
                            Layout.fillWidth:true; columns:width>850?3:2; columnSpacing:14; rowSpacing:14
                            Repeater {
                                model:visibleFeaturedApps
                                delegate:Rectangle {
                                    Layout.fillWidth:true; Layout.preferredHeight:216; radius:16; color:panel; border.color:panelBorder
                                    ColumnLayout {
                                        anchors.fill:parent; anchors.margins:15; spacing:8
                                        RowLayout {
                                            Layout.fillWidth:true
                                            Rectangle {
                                                width:54;height:54;radius:13;color:"#FFFFFF";border.color:"#E8E8E8"
                                                Image { anchors.fill:parent;anchors.margins:7;source:modelData.image;asynchronous:true;fillMode:Image.PreserveAspectFit }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth:true;spacing:3
                                                Text { text:modelData.title;color:primaryText;font.pixelSize:14;font.bold:true;Layout.fillWidth:true;elide:Text.ElideRight }
                                                Text { text:modelData.category;color:muted;font.pixelSize:10 }
                                            }
                                        }
                                        Text { text:modelData.desc;color:secondaryText;font.pixelSize:11;wrapMode:Text.WordWrap;Layout.fillWidth:true;Layout.fillHeight:true }
                                        RowLayout {
                                            Layout.fillWidth:true
                                            Text { text:modelData.tag;color:accent;font.pixelSize:9;font.bold:true }
                                            Item { Layout.fillWidth:true }
                                            Button { text:"Ficha";onClicked:{selectedAppName=modelData.title;appDetailDialog.open()} }
                                            Button { text:"Abrir";onClicked:Qt.openUrlExternally(modelData.url) }
                                            Button { visible:!!modelData.downloadUrl; text:"Instalar"; onClicked:appImageManager.installPuntoVuelaTool(modelData.repository) }
                                        }
                                    }
                                }
                            }
                        }
                        Dialog {
                            id:appDetailDialog;modal:true;anchors.centerIn:Overlay.overlay;width:Math.min(window.width-80,520)
                            title:selectedAppName;standardButtons:Dialog.Close
                            contentItem:ColumnLayout {
                                spacing:10
                                Text {
                                    text:{
                                        const item=featuredApps.find(entry=>entry.title===selectedAppName)
                                        return item?item.desc+"\n\nCategoría: "+item.category+"\nTipo: "+item.kind+"\nOrigen: "+item.url:""
                                    }
                                    color:primaryText;wrapMode:Text.WordWrap;Layout.fillWidth:true
                                }
                                Button { text:"Abrir proyecto";onClicked:{
                                    const item=featuredApps.find(entry=>entry.title===selectedAppName)
                                    if(item)Qt.openUrlExternally(item.url)
                                }}
                            }
                        }
                        Text { text: "Fuentes de aplicaciones"; color: primaryText; font.pixelSize: 17; font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 14
                            Repeater {
                                model: [
                                    {title:"Catálogo oficial AppImage", desc:"Catálogo de aplicaciones AppImage", url:"https://appimage.github.io/"},
                                    {title:"AppImage Community", desc:"Catálogo comunitario oficial", url:"https://appimage.github.io/"}
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 88
                                    radius: 12; color: panel; border.color: panelBorder
                                    Column {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 7
                                        Text { text: modelData.title; color: primaryText; font.pixelSize: 13; font.bold: true }
                                        Text { text: modelData.desc; color: muted; font.pixelSize: 11 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.openUrlExternally(modelData.url) }
                                }
                            }
                        }

                    }



                    ColumnLayout {
                        id: catalogPage
                        width: parent.width
                        spacing: 14
                        visible: activePage === "Catálogo AppImage"

                        Text { text: "Catálogo de aplicaciones"; color: primaryText; font.pixelSize: 21; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: "Busca en el catálogo comunitario AppImage. Se muestran los requisitos de glibc cuando el editor los ha declarado; las aplicaciones que requieren una versión superior a Ubuntu 20.04 quedan bloqueadas para evitar instalaciones incompatibles."
                            color: secondaryText; font.pixelSize: 12; wrapMode: Text.WordWrap
                        }
                        Rectangle {
                            Layout.fillWidth: true; radius: 12; color: panel; border.color: panelBorder
                            implicitHeight: 66
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 8
                                TextField {
                                    id: catalogSearch
                                    Layout.fillWidth: true
                                    placeholderText: "Buscar por nombre, descripción, categoría o autor"
                                    onAccepted: refreshCatalog()
                                }
                                Button { text: "Buscar"; onClicked: refreshCatalog() }
                                Button { text: "Actualizar catálogo"; enabled: !catalogLoading; onClicked: { catalogLoading = true; appImageManager.refreshCatalog() } }
                            }
                        }
                        Text {
                            id: catalogStatus
                            Layout.fillWidth: true
                            text: catalogLoading ? "Cargando catálogo…" : "El catálogo se cargará al abrir esta sección."
                            color: accent; font.pixelSize: 11; wrapMode: Text.WordWrap
                        }
                        Flow {
                            Layout.fillWidth:true;spacing:8
                            Repeater {
                                model:["Todas"].concat(Array.from(new Set(catalogItems.map(item=>item.category).filter(Boolean))).sort())
                                delegate:Button { text:modelData;highlighted:catalogCategory===modelData;onClicked:catalogCategory=modelData }
                            }
                        }
                        GridView {
                            id:officialCatalogGrid
                            Layout.fillWidth:true
                            Layout.preferredHeight:Math.max(360,Math.ceil(filteredCatalogItems.length/3)*236)
                            cellWidth:width/3
                            cellHeight:226
                            interactive:false
                            model:filteredCatalogItems
                            delegate:Rectangle {
                                width:officialCatalogGrid.cellWidth-12;height:214
                                radius:16;color:panel;border.color:panelBorder
                                ColumnLayout {
                                    anchors.fill:parent;anchors.margins:13;spacing:7
                                    RowLayout {
                                        Layout.fillWidth:true;spacing:10
                                        Rectangle {
                                            width:58;height:58;radius:13;color:"#FFFFFF";border.color:"#E8EAF0"
                                            Image { anchors.fill:parent;anchors.margins:6;source:modelData.iconUrl||"";asynchronous:true;cache:true;fillMode:Image.PreserveAspectFit;visible:status===Image.Ready }
                                            Text { anchors.centerIn:parent;text:(modelData.name||"?").charAt(0).toUpperCase();color:"#303740";font.pixelSize:21;font.bold:true;visible:parent.children[0].status!==Image.Ready }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth:true;spacing:3
                                            Text { text:modelData.name;color:primaryText;font.pixelSize:12;font.bold:true;wrapMode:Text.WordWrap;maximumLineCount:2;Layout.fillWidth:true }
                                            Text { text:modelData.category;color:accent;font.pixelSize:9 }
                                        }
                                    }
                                    Text { text:modelData.description||"Aplicación publicada en el catálogo oficial AppImage.";color:secondaryText;font.pixelSize:10;wrapMode:Text.WordWrap;maximumLineCount:3;elide:Text.ElideRight;Layout.fillWidth:true;Layout.fillHeight:true }
                                    Text { text:modelData.compatibility;color:modelData.compatibleUbuntu20?"#62B47A":"#D65A5A";font.pixelSize:9;wrapMode:Text.WordWrap;Layout.fillWidth:true }
                                    RowLayout {
                                        Layout.fillWidth:true
                                        Button { text:"Ficha";onClicked:{selectedCatalogApp=modelData;catalogDetailDialog.open()} }
                                        Item { Layout.fillWidth:true }
                                        Button { text:"Instalar";enabled:modelData.compatibleUbuntu20 && (modelData.repository!=="" || modelData.downloadUrl!=="");onClicked:{selectedCatalogApp=modelData;appImageManager.installCatalogApp(modelData.name);catalogStatus.text="Instalando "+modelData.name+"…"} }
                                    }
                                }
                            }
                        }
                        Dialog {
                            id:catalogDetailDialog;modal:true;anchors.centerIn:Overlay.overlay;width:Math.min(window.width-48,620)
                            title:selectedCatalogApp?selectedCatalogApp.name:"Ficha de aplicación";standardButtons:Dialog.Close
                            contentItem:ColumnLayout {
                                spacing:10
                                Text { text:selectedCatalogApp?(selectedCatalogApp.description||"El catálogo oficial no proporciona descripción para esta aplicación."):"";color:primaryText;wrapMode:Text.WordWrap;Layout.fillWidth:true }
                                Text { text:selectedCatalogApp?"Categoría: "+selectedCatalogApp.category+"\nAutor: "+selectedCatalogApp.author+"\nLicencia: "+selectedCatalogApp.license+"\nCompatibilidad: "+selectedCatalogApp.compatibility+"\nRequisito glibc: "+selectedCatalogApp.glibc:"";color:secondaryText;wrapMode:Text.WordWrap;Layout.fillWidth:true }
                                RowLayout {
                                    Layout.fillWidth:true
                                    Button {
                                        text:"Instalar"
                                        enabled:selectedCatalogApp && selectedCatalogApp.compatibleUbuntu20 && (selectedCatalogApp.repository!=="" || selectedCatalogApp.downloadUrl!=="")
                                        onClicked:{catalogStatus.text="Descargando e integrando "+selectedCatalogApp.name+"…";appImageManager.installCatalogApp(selectedCatalogApp.name);catalogDetailDialog.close()}
                                    }
                                    Button { text:"Ver ficha oficial";onClicked:if(selectedCatalogApp)Qt.openUrlExternally(selectedCatalogApp.catalogUrl||"https://appimage.github.io/") }
                                }
                            }
                        }
                        Text { Layout.fillWidth:true;text:"Catálogo oficial: appimage.github.io/feed.json. Las aplicaciones se descargan desde los enlaces publicados por sus autores y se integran en el menú del usuario, sin permisos de administrador. Las actualizaciones dependen de que la AppImage incluya metadatos compatibles con AppImageUpdate.";color:muted;font.pixelSize:10;wrapMode:Text.WordWrap }
                    }

                    ColumnLayout {
                        id: appImagesPage
                        width: parent.width
                        spacing: 16
                        visible: activePage === "Mis aplicaciones"
                        Text { text: "Tus aplicaciones AppImage"; color: primaryText; font.pixelSize: 20; font.bold: true }
                        Text { Layout.fillWidth: true; text: "Descarga aplicaciones desde enlaces HTTPS. Se guardan en tu carpeta personal y reciben permisos de ejecución automáticamente."; color: secondaryText; font.pixelSize: 12; wrapMode: Text.WordWrap }
                        Rectangle {
                            Layout.fillWidth: true; radius: 14; color: panel; border.color: panelBorder
                            implicitHeight: downloadForm.implicitHeight + 30
                            ColumnLayout {
                                id: downloadForm
                                anchors.fill: parent; anchors.margins: 16; spacing: 10
                                Text { text: "Descargar AppImage"; color: primaryText; font.pixelSize: 14; font.bold: true }
                                TextField { id: appImageUrl; Layout.fillWidth: true; placeholderText: "Enlace HTTPS directo al archivo .AppImage" }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Button {
                                        text: "Descargar"
                                        onClicked: {
                                            if (!appImageUrl.text.trim()) {
                                                appImageStatus.text = "Introduce un enlace HTTPS directo a una AppImage."
                                                return
                                            }
                                            appImageStatus.text = "Descargando y comprobando la aplicación…"
                                            appImageManager.downloadAppImage(appImageUrl.text.trim())
                                        }
                                    }
                                    Button { text: "Catálogo oficial"; onClicked: { activePage = "Catálogo AppImage"; refreshCatalog() } }
                                    Button { text: "Abrir carpeta"; onClicked: appImageManager.openAppImageFolder() }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Aplicaciones descargadas"; color: primaryText; font.pixelSize: 15; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Button { text: "Actualizar lista"; onClicked: refreshAppImages() }
                        }
                        Text { id: appImageStatus; Layout.fillWidth: true; color: secondaryText; wrapMode: Text.WordWrap; font.pixelSize: 11 }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(150, appImageItems.length * 100)
                            interactive: false
                            model: appImageItems
                            spacing: 8
                            delegate: Rectangle {
                                width: ListView.view.width; height: 92
                                radius: 12; color: panel; border.color: panelBorder
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 8
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { text: modelData.name; color: primaryText; font.pixelSize: 12; font.bold: true; elide: Text.ElideMiddle; Layout.fillWidth: true }
                                        Text { text: modelData.executable ? "Permisos de ejecución activos" : "Sin permisos de ejecución"; color: muted; font.pixelSize: 10 }
                                    }
                                    Button {
                                        text: "Abrir"
                                        onClicked: {
                                            const result = JSON.parse(appImageManager.launchAppImage(modelData.path))
                                            appImageStatus.text = modelData.name + ": " + result.message
                                        }
                                    }
                                    Button {
                                        text: "Permisos"
                                        visible: !modelData.executable
                                        onClicked: {
                                            const result = JSON.parse(appImageManager.makeAppImageExecutable(modelData.path))
                                            appImageStatus.text = modelData.name + ": " + result.message
                                            refreshAppImages()
                                        }
                                    }
                                    Button {
                                        text: modelData.customUpdater ? "Abrir gestor" : "Comprobar"
                                        onClicked: {
                                            if (modelData.customUpdater) {
                                                const result = JSON.parse(appImageManager.launchAppImage(modelData.path))
                                                appImageStatus.text = "Este instalador gestiona sus propias versiones: " + result.message
                                            } else {
                                                appImageStatus.text = "Comprobando actualizaciones de " + modelData.name + "…"
                                                appImageManager.checkAppImageUpdate(modelData.path)
                                            }
                                        }
                                    }
                                    Button {
                                        text: modelData.customUpdater ? "Abrir actualizador" : "Actualizar"
                                        onClicked: {
                                            if (modelData.customUpdater) {
                                                const result = JSON.parse(appImageManager.launchAppImage(modelData.path))
                                                appImageStatus.text = "Se ha abierto el actualizador propio: " + result.message
                                            } else {
                                                appImageStatus.text = "Actualizando " + modelData.name + "…"
                                                appImageManager.updateAppImage(modelData.path)
                                            }
                                        }
                                    }
                                    Button {
                                        text: "Eliminar"
                                        onClicked: {
                                            removeDialog.targetPath = modelData.path
                                            removeDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                        Text { Layout.fillWidth: true; text: "La comprobación requiere información de actualización compatible dentro de la AppImage. Si no encuentra AppImageUpdate, el Toolkit descarga el actualizador oficial en tu perfil y verifica su SHA-256; no necesita root. Si no existe esa información, consulta la web del desarrollador y descarga la nueva versión manualmente."; color: muted; font.pixelSize: 11; wrapMode: Text.WordWrap }
                        Component.onCompleted: refreshAppImages()
                    }

                    ColumnLayout {
                        id: helpPage
                        width: parent.width
                        spacing: 16
                        visible: activePage === "Ayuda"
                        Text { text: "Guía de ayuda"; color: primaryText; font.pixelSize: 22; font.bold: true }
                        Text { text: "PUNTO VUELA LINUX TOOLKIT"; color: accent; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                        Rectangle {
                            Layout.fillWidth: true; radius: 14; color: heroStart; border.color: panelBorder
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 18; spacing: 8
                                Text { text: "Tus aplicaciones, organizadas en un solo lugar"; color: "#202226"; font.pixelSize: 17; font.bold: true }
                                Text { text: "Las AppImages se guardan en ~/.local/share/punto-vuela-linux-toolkit/AppImages. No necesitas permisos de administrador para descargarlas o gestionarlas."; color: "#343434"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                            }
                        }
                        Repeater {
                            model: [
                                {title:"1. Descargar", body:"En Mis aplicaciones, introduce el enlace HTTPS directo al archivo .AppImage. El Toolkit valida que el archivo sea ELF y lo guarda en tu carpeta personal."},
                                {title:"2. Ejecutar", body:"Al finalizar la descarga, el archivo recibe permisos de ejecución automáticamente. Pulsa Abrir carpeta para localizarlo."},
                                {title:"3. Actualizar", body:"Pulsa Comprobar. Si la AppImage incluye información compatible, AppImageUpdate consulta el origen del autor. Si existe una versión nueva, pulsa Actualizar."},
                                {title:"4. Sin actualizador", body:"No todas las AppImages del catálogo incluyen información de actualización. En ese caso no se puede confirmar automáticamente si hay una versión posterior: consulta la web del desarrollador."},
                                {title:"5. Seguridad", body:"Una AppImage es un programa ejecutable. Descarga software de fuentes fiables. La validación ELF no es un análisis antivirus ni verifica la identidad del autor. Las actualizaciones requieren una acción explícita."}
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true; radius: 12; color: panel; border.color: panelBorder
                                implicitHeight: helpText.implicitHeight + 30
                                ColumnLayout {
                                    id: helpText
                                    anchors.fill: parent; anchors.margins: 15; spacing: 6
                                    Text { text: modelData.title; color: primaryText; font.pixelSize: 13; font.bold: true }
                                    Text { text: modelData.body; color: secondaryText; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                }
                            }
                        }
                        Text { Layout.fillWidth: true; text: "Guía completa: docs/GUIA-DE-AYUDA.md en el repositorio."; color: muted; font.pixelSize: 10; wrapMode: Text.WordWrap }
                    }

                    ColumnLayout {
                        id: contactPage
                        width: parent.width
                        spacing: 18
                        visible: activePage === "Contacto e información"

                        Text { text: "Solicita incorporar una aplicación"; color: primaryText; font.pixelSize: 22; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: "Envía una propuesta para estudiar su inclusión en el catálogo Punto Vuela Linux Toolkit. Puedes enviar la solicitud directamente por correo corporativo o compartirla por WhatsApp."
                            color: secondaryText; font.pixelSize: 12; wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true; radius: 16; color: panel; border.color: panelBorder
                            implicitHeight: requestForm.implicitHeight + 36
                            ColumnLayout {
                                id: requestForm
                                anchors.fill: parent; anchors.margins: 18; spacing: 12
                                Text { text: "Datos del centro y del/de la AIL"; color: primaryText; font.pixelSize: 15; font.bold: true }
                                GridLayout {
                                    Layout.fillWidth: true; columns: width > 680 ? 2 : 1; columnSpacing: 12; rowSpacing: 9
                                    TextField { id: puntoVuelaField; Layout.fillWidth: true; placeholderText: "Nombre del Punto Vuela *" }
                                    TextField { id: municipioField; Layout.fillWidth: true; placeholderText: "Municipio *" }
                                    TextField { id: ailField; Layout.fillWidth: true; placeholderText: "Nombre y apellidos del/de la AIL *" }
                                    TextField { id: telefonoField; Layout.fillWidth: true; placeholderText: "Teléfono de contacto *" }
                                    TextField { id: correoField; Layout.fillWidth: true; placeholderText: "Correo electrónico *" }
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: panelBorder }
                                Text { text: "Aplicación propuesta"; color: primaryText; font.pixelSize: 15; font.bold: true }
                                GridLayout {
                                    Layout.fillWidth: true; columns: width > 680 ? 2 : 1; columnSpacing: 12; rowSpacing: 9
                                    TextField { id: softwareField; Layout.fillWidth: true; placeholderText: "Nombre de la aplicación *" }
                                    TextField { id: enlaceField; Layout.fillWidth: true; placeholderText: "Web oficial o descarga" }
                                    ComboBox { id: distroField; Layout.fillWidth: true; model: ["Ubuntu", "Debian", "Linux Mint", "Fedora", "Otra distribución", "Cualquier distribución"] }
                                }
                                TextArea { id: motivoField; Layout.fillWidth: true; Layout.preferredHeight: 90; placeholderText: "Utilidad y necesidad que cubriría *"; wrapMode: TextEdit.Wrap }
                                TextArea { id: observacionesField; Layout.fillWidth: true; Layout.preferredHeight: 64; placeholderText: "Observaciones (opcional)"; wrapMode: TextEdit.Wrap }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Button { text: "Protección de datos"; onClicked: dataProtectionDialog.open() }
                                    Button { text: "Política de privacidad"; onClicked: privacyPolicyDialog.open() }
                                }
                                CheckBox {
                                    id: privacyAcknowledged
                                    Layout.fillWidth: true
                                    text: "Confirmo que he leído la información de protección de datos y la política de privacidad."
                                    checked: false
                                    enabled: dataProtectionRead && privacyPolicyRead
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: dataProtectionRead && privacyPolicyRead ? "Ya has consultado ambos documentos. Marca la casilla para continuar." : "Abre y lee los dos documentos para habilitar la confirmación."
                                    color: muted; wrapMode: Text.WordWrap; font.pixelSize: 11
                                }
                                Button {
                                    text: "Generar solicitud y vista previa"
                                    onClicked: {
                                        if (!puntoVuelaField.text.trim() || !municipioField.text.trim() || !ailField.text.trim() ||
                                            !telefonoField.text.trim() || !correoField.text.trim() || !softwareField.text.trim() || !motivoField.text.trim()) {
                                            formError.text = "Completa los campos obligatorios para continuar."; formError.visible = true; return
                                        }
                                        if (!dataProtectionRead || !privacyPolicyRead || !privacyAcknowledged.checked) {
                                            formError.text = "Debes confirmar que has leído la información de protección de datos."; formError.visible = true; return
                                        }
                                        formError.visible = false
                                        previewText.text =
                                            "SOLICITUD DE INCORPORACIÓN DE APLICACIÓN\n\n" +
                                            "PUNTO VUELA\nCentro: " + puntoVuelaField.text.trim() + "\nMunicipio: " + municipioField.text.trim() + "\n\n" +
                                            "PERSONA DE CONTACTO\nNombre: " + ailField.text.trim() + "\nTeléfono: " + telefonoField.text.trim() +
                                            "\nCorreo: " + correoField.text.trim() + "\n\n" +
                                            "APLICACIÓN\nNombre: " + softwareField.text.trim() + "\nEnlace: " + (enlaceField.text.trim() || "No indicado") +
                                            "\nDistribución: " + distroField.currentText + "\nUtilidad: " + motivoField.text.trim() +
                                            "\nObservaciones: " + (observacionesField.text.trim() || "Ninguna")
                                        previewVisible = true
                                    }
                                }
                                Text { id: formError; visible: false; color: "#D65A5A"; font.pixelSize: 11; wrapMode: Text.WordWrap }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; visible: previewVisible; radius: 16; color: panel; border.color: panelBorder
                            implicitHeight: previewColumn.implicitHeight + 36
                            ColumnLayout {
                                id: previewColumn
                                anchors.fill: parent; anchors.margins: 18; spacing: 10
                                Text { text: "Vista previa editable"; color: primaryText; font.pixelSize: 15; font.bold: true }
                                TextArea {
                                    id: previewText; Layout.fillWidth: true; Layout.preferredHeight: 260
                                    wrapMode: TextEdit.Wrap; selectByMouse: true; color: primaryText
                                    background: Rectangle { color: searchColor; border.color: panelBorder; radius: 8 }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Button {
                                        text: "Enviar por WhatsApp"
                                        onClicked: {
                                            if (!dataProtectionRead || !privacyPolicyRead || !privacyAcknowledged.checked) {
                                                emailStatus.text = "Debes confirmar que has leído la información de protección de datos."; emailStatus.color = "#D65A5A"; return
                                            }
                                            if (previewText.text.trim()) Qt.openUrlExternally("https://wa.me/34633402959?text=" + encodeURIComponent(previewText.text))
                                        }
                                    }
                                    Button {
                                        text: "Enviar solicitud por email"
                                        onClicked: {
                                            if(!puntoVuelaField.text.trim() || !municipioField.text.trim() || !ailField.text.trim() || !telefonoField.text.trim() || !correoField.text.trim() || !softwareField.text.trim() || !motivoField.text.trim()) {
                                                emailStatus.text="Completa los campos obligatorios antes de enviar."; emailStatus.color="#D65A5A"; return
                                            }
                                            if (!dataProtectionRead || !privacyPolicyRead || !privacyAcknowledged.checked) {
                                                emailStatus.text="Debes confirmar que has leído la información de protección de datos."; emailStatus.color="#D65A5A"; return
                                            }
                                            const payload={
                                                center:puntoVuelaField.text.trim(),municipality:municipioField.text.trim(),
                                                contact:ailField.text.trim(),phone:telefonoField.text.trim(),reply_email:correoField.text.trim(),
                                                application:softwareField.text.trim(),url:enlaceField.text.trim(),
                                                distribution:distroField.currentText,purpose:motivoField.text.trim(),notes:observacionesField.text.trim()
                                            }
                                            emailStatus.text="Enviando solicitud HTML…"; emailStatus.color=secondaryText
                                            appImageManager.sendApplicationRequest(JSON.stringify(payload))
                                        }
                                    }
                                }
                                Text { id: emailStatus; text: "El envío se realizará de forma segura mediante el servicio corporativo de correo."; color: muted; font.pixelSize: 10; wrapMode: Text.WordWrap }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; radius: 16; color: panel; border.color: panelBorder
                            implicitHeight: 154
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 20; spacing: 18
                                Rectangle { width: 72; height: 72; radius: 18; color: accent
                                    Image { anchors.fill: parent; anchors.margins: 5; source: Qt.resolvedUrl("../assets/logotipovuela.svg"); fillMode: Image.PreserveAspectFit }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 5
                                    Text { text: "Desarrollo y mantenimiento"; color: primaryText; font.pixelSize: 16; font.bold: true }
                                    Text { text: "Punto Vuela Montejaque"; color: secondaryText; font.pixelSize: 13; font.bold: true }
                                    Text { text: "Desarrollador: Francisco Javier Gallego Orellana"; color: secondaryText; font.pixelSize: 12 }
                                    Text { text: "Proyecto comunitario de herramientas y aplicaciones para Linux."; color: muted; font.pixelSize: 11; wrapMode: Text.WordWrap }
                                    Text { text: "Repositorio oficial: github.com/Montejaque/punto-vuela-linux-toolkit"; color: accent; font.pixelSize: 10; wrapMode: Text.WordWrap }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
