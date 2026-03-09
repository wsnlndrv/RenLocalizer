// ToolsPage.qml - Araçlar Sayfası (Restored)
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: toolsPage
    color: Material.background

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: 24
            spacing: 24

            Label {
                text: "🛠 " + (backend.uiTrigger, backend.getTextWithDefault("nav_tools", "Tools"))
                font.pixelSize: 24
                font.bold: true
                color: root.mainTextColor
            }

            // Araç Grupları
            Flow {
                Layout.fillWidth: true
                spacing: 15
                padding: 5
                Layout.alignment: Qt.AlignHCenter

                // --- RPA Araçları ---
                ToolCard {
                    title: (backend.uiTrigger, backend.getTextWithDefault("unrpa_title", "RPA Archive Management"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("unrpa_desc", "Extract or pack .rpa files."))
                    icon: "📦"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_manage", "Manage"))
                    onClicked: backend.runUnRen() // Backend'de tanımlanmalı veya dialog açmalı
                }

                // --- Sağlık Kontrolü ---
                ToolCard {
                    title: (backend.uiTrigger, backend.getTextWithDefault("health_check_title", "Health Check"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("diagnostics_desc", "Scan project for errors, missing files."))
                    icon: "🩺"
                     btnText: (backend.uiTrigger, backend.getTextWithDefault("run_check", "Start Scan"))
                    onClicked: backend.runHealthCheck()
                }

                // --- Font Kontrolü ---
                ToolCard {
                    title: (backend.uiTrigger, backend.getTextWithDefault("font_check_title", "Font Compatibility"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("font_check_desc", "Test if the selected language is supported by the font."))
                    icon: "🔤"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("font_check_now_button", "Test Now"))
                    onClicked: backend.runFontCheck()
                }

                // --- Otomatik Font Enjeksiyonu ---
                ToolCard {
                    title: "🅰️ " + (backend.uiTrigger, backend.getTextWithDefault("font_injector_title", "Automatic Font Fixer"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("font_injector_desc", "Download and integrate a compatible font for the selected language (resolves box characters)."))
                    icon: "🪄"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_fix_now", "Fix Now"))
                    onClicked: backend.autoInjectFont()
                }

                // --- Manuel Font Seçimi (YENİ) ---
                ToolCard {
                    title: "🔠 " + (backend.uiTrigger, backend.getTextWithDefault("font_manual_title", "Manual Font Selection"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("font_manual_desc", "You can select and download a Google Font from the list instead of auto-matching."))
                    icon: "📑"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_open", "Select"))
                    onClicked: manualFontDialog.open()
                }

                // --- Runtime Hook Oluşturucu ---
                ToolCard {
                    title: "🪝 " + (backend.uiTrigger, backend.getTextWithDefault("tool_runtime_hook_title", "Runtime Hook Generator"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("settings_hook_desc", "Create the Runtime Hook mode for the game to recognize translations."))
                    icon: "🪄"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("generate_hook_btn", "Generate"))
                    onClicked: backend.generateRuntimeHook()
                }
                
                // --- Sözde Çeviri (Test) ---
                ToolCard {
                    title: (backend.uiTrigger, backend.getTextWithDefault("pseudo_engine_name", "Pseudo Translation (Test)"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("pseudo_desc", "Translate with random characters for testing purposes (to see UI overflows)."))
                    icon: "🧪"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("start", "Başlat"))
                    onClicked: {
                        backend.setEngine("pseudo")
                        backend.startTranslation()
                    }
                }

                // --- TL Klasörünü Çevir ---
                ToolCard {
                    title: "📂 " + (backend.uiTrigger, backend.getTextWithDefault("tl_translate_title", "Translate TL Folder"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("tl_translate_desc", "Allows you to directly translate existing translation files in the game's 'tl' folder."))
                    icon: "🌐"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_select_and_start", "Select Folder and Start"))
                    onClicked: tlDialog.open()
                }

                // --- Çeviri Doğrulama (Lint) ---
                ToolCard {
                    title: "🔍 " + (backend.uiTrigger, backend.getTextWithDefault("tool_lint_title", "Translation Lint"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("tool_lint_desc", "Validate translation files for common errors and inconsistencies."))
                    icon: "✅"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_lint", "Run Lint"))
                    onClicked: backend.runTranslationLint()
                }

                // --- Proje Dışa Aktarma ---
                ToolCard {
                    title: "📤 " + (backend.uiTrigger, backend.getTextWithDefault("tool_project_export_title", "Project Export"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("tool_project_export_desc", "Export current project settings, glossary and cache as a portable archive (.rlproj)."))
                    icon: "💾"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_export", "Export"))
                    onClicked: backend.exportProject()
                }

                // --- Proje İçe Aktarma ---
                ToolCard {
                    title: "📥 " + (backend.uiTrigger, backend.getTextWithDefault("tool_project_import_title", "Project Import"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("tool_project_import_desc", "Import project settings, glossary and cache from a .rlproj archive file."))
                    icon: "📂"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_import", "Import"))
                    onClicked: backend.importProject()
                }

                // --- Çeviri Şifreleme ---
                ToolCard {
                    title: "🔒 " + (backend.uiTrigger, backend.getTextWithDefault("tool_encrypt_title", "Translation Encryption"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("tool_encrypt_desc", "Obfuscate translation files to protect your work from casual copying."))
                    icon: "🛡️"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_encrypt", "Encrypt"))
                    onClicked: backend.encryptTranslations()
                }

                // --- RPA Paketleme ---
                ToolCard {
                    title: "📦 " + (backend.uiTrigger, backend.getTextWithDefault("tool_rpa_pack_title", "RPA Packing"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("tool_rpa_pack_desc", "Pack translation files into a Ren'Py-compatible .rpa archive."))
                    icon: "🗜️"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_pack", "Pack"))
                    onClicked: backend.packRPA()
                }

                // --- Harici Çeviri Belleği (TM) ---
                ToolCard {
                    title: "🧠 " + (backend.uiTrigger, backend.getTextWithDefault("tm_import_title", "External Translation Memory"))
                    desc: (backend.uiTrigger, backend.getTextWithDefault("tm_import_desc", "Import translations from another game's tl/ folder to reuse as Translation Memory."))
                    icon: "📚"
                    btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_import", "Import"))
                    onClicked: tmImportDialog.open()
                }
            }
        }
    }

    // Manuel Font Diyaloğu
    Dialog {
        id: manualFontDialog
        title: (backend.uiTrigger, backend.getTextWithDefault("font_manual_title", "Manual Font Selection"))
        anchors.centerIn: parent
        modal: true
        width: 400
        
        background: Rectangle { color: root.cardBackground; radius: 12; border.color: root.borderColor }
        header: Label { text: (backend.uiTrigger, backend.getTextWithDefault("font_manual_title", "Manual Font Selection")); padding: 20; font.bold: true; color: root.mainTextColor; font.pixelSize: 18 }
        
        contentItem: ColumnLayout {
            spacing: 15
            Label { 
                text: (backend.uiTrigger, backend.getTextWithDefault("font_manual_desc", "Select a font from the list:")); 
                color: root.secondaryTextColor; 
                wrapMode: Text.Wrap; 
                Layout.fillWidth: true 
            }
            
            ComboBox {
                id: manualFontCombo
                Layout.fillWidth: true
                model: backend.getGoogleFontsList()
                editable: true // Kullanıcı yazarak arayabilsin
            }
        }
        
        footer: DialogButtonBox {
            background: Rectangle { color: "transparent" }
            Button { text: (backend.uiTrigger, backend.getTextWithDefault("btn_cancel", "Cancel")); DialogButtonBox.buttonRole: DialogButtonBox.RejectRole; flat: true }
            Button { 
                text: (backend.uiTrigger, backend.getTextWithDefault("btn_download_inject", "Download and Apply")); 
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; 
                highlighted: true
                onClicked: {
                    backend.manualInjectFont(manualFontCombo.currentText)
                    manualFontDialog.close()
                }
            }
        }
    }

    // TL Çeviri Diyaloğu
    Dialog {
        id: tlDialog
        title: (backend.uiTrigger, backend.getTextWithDefault("tl_dialog_title", "TL Translation"))
        anchors.centerIn: parent
        modal: true
        width: 520
        
        background: Rectangle { color: root.cardBackground; radius: 12; border.color: root.borderColor }
        header: Label { text: (backend.uiTrigger, backend.getTextWithDefault("tl_dialog_header", "📂 TL Folder Translation")); padding: 20; font.bold: true; color: root.mainTextColor; font.pixelSize: 18 }
        
        contentItem: ColumnLayout {
            spacing: 15
            Label { text: (backend.uiTrigger, backend.getTextWithDefault("tl_select_folder_instruction", "Select the folder to be translated (e.g. game/tl/turkish):")); color: root.secondaryTextColor; wrapMode: Text.Wrap; Layout.fillWidth: true }
            
            RowLayout {
                TextField { id: tlPathField; Layout.fillWidth: true; placeholderText: (backend.uiTrigger, backend.getTextWithDefault("path_not_selected_placeholder", "Path not selected...")); color: root.mainTextColor; background: Rectangle { color: root.inputBackground; border.color: root.borderColor; radius: 6 } }
                Button { text: "📁"; onClicked: tlPathDialog.open() }
            }
            
            // Kaynak Dil
            RowLayout {
                Label { text: (backend.uiTrigger, backend.getTextWithDefault("source_lang_label", "Source Language:")); color: root.secondaryTextColor; Layout.preferredWidth: 130 }
                ComboBox {
                    id: tlSourceCombo
                    Layout.fillWidth: true
                    model: backend.getSourceLanguages()
                    textRole: "name"
                    valueRole: "code"
                    currentIndex: 0
                    Component.onCompleted: {
                        var idx = indexOfValue(backend.getSourceLanguage())
                        if (idx >= 0) currentIndex = idx
                    }
                }
            }

            // Hedef Dil
            RowLayout {
                Label { text: (backend.uiTrigger, backend.getTextWithDefault("target_lang_label", "Target Language:")); color: root.secondaryTextColor; Layout.preferredWidth: 130 }
                ComboBox {
                    id: tlTargetCombo
                    Layout.fillWidth: true
                    model: backend.getTargetLanguages()
                    textRole: "name"
                    valueRole: "code"
                    Component.onCompleted: {
                        var idx = indexOfValue(backend.getTargetLanguage())
                        if (idx >= 0) currentIndex = idx
                    }
                }
            }

            // Çeviri Motoru
            RowLayout {
                Label { text: (backend.uiTrigger, backend.getTextWithDefault("translation_engine_label", "Translation Engine:")); color: root.secondaryTextColor; Layout.preferredWidth: 130 }
                ComboBox {
                    id: tlEngineCombo
                    Layout.fillWidth: true
                    model: backend.getAvailableEngines()
                    textRole: "name"
                    valueRole: "code"
                    Component.onCompleted: {
                        var idx = indexOfValue(backend.selectedEngine)
                        if (idx >= 0) currentIndex = idx
                    }
                }
            }

            // Proxy
            RowLayout {
                spacing: 10
                CheckBox {
                    id: tlProxyCheck
                    text: (backend.uiTrigger, backend.getTextWithDefault("proxy_enabled", "Use Proxy"))
                    checked: settingsBackend.getProxyEnabled()
                    Material.accent: root.Material.accent
                }
            }
        }
        
        footer: DialogButtonBox {
            background: Rectangle { color: "transparent" }
            Button { text: (backend.uiTrigger, backend.getTextWithDefault("btn_cancel", "Cancel")); DialogButtonBox.buttonRole: DialogButtonBox.RejectRole; flat: true }
            Button { 
                text: (backend.uiTrigger, backend.getTextWithDefault("start_translation", "Start Translation")); DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole; highlighted: true
                onClicked: backend.startTLTranslation(tlPathField.text, tlTargetCombo.currentValue, tlSourceCombo.currentValue, tlEngineCombo.currentValue, tlProxyCheck.checked)
            }
        }
    }

    FolderDialog {
        id: tlPathDialog
        title: (backend.uiTrigger, backend.getTextWithDefault("select_tl_folder_title", "Select TL Folder"))
        currentFolder: "file:///" + backend.get_app_path()
        onAccepted: tlPathField.text = selectedFolder.toString().replace("file:///", "")
    }

    // ==================== TM Import Dialog ====================
    Dialog {
        id: tmImportDialog
        title: (backend.uiTrigger, backend.getTextWithDefault("tm_import_title", "External Translation Memory"))
        anchors.centerIn: parent
        modal: true
        width: 480

        background: Rectangle { color: root.cardBackground; radius: 12; border.color: root.borderColor }
        header: Label { text: "🧠 " + (backend.uiTrigger, backend.getTextWithDefault("tm_import_title", "External Translation Memory")); padding: 20; font.bold: true; color: root.mainTextColor; font.pixelSize: 18 }

        contentItem: ColumnLayout {
            spacing: 15

            Label {
                text: (backend.uiTrigger, backend.getTextWithDefault("tm_import_instruction", "Select a tl/<language> folder from another Ren'Py game to import as Translation Memory:"))
                color: root.secondaryTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            // Kaynak Adı
            RowLayout {
                Label { text: (backend.uiTrigger, backend.getTextWithDefault("tm_source_name_label", "Source Name:")); color: root.secondaryTextColor; Layout.preferredWidth: 100 }
                TextField {
                    id: tmSourceNameField
                    Layout.fillWidth: true
                    placeholderText: (backend.uiTrigger, backend.getTextWithDefault("tm_source_name_placeholder", "e.g. GameA, MyOtherProject"))
                    color: root.mainTextColor
                    background: Rectangle { color: root.inputBackground; border.color: root.borderColor; radius: 6 }
                }
            }

            // Klasör Seçimi
            RowLayout {
                TextField {
                    id: tmPathField
                    Layout.fillWidth: true
                    placeholderText: (backend.uiTrigger, backend.getTextWithDefault("path_not_selected_placeholder", "Path not selected..."))
                    color: root.mainTextColor
                    background: Rectangle { color: root.inputBackground; border.color: root.borderColor; radius: 6 }
                }
                Button { text: "📁"; onClicked: tmFolderDialog.open() }
            }

            // Dil Seçimi
            RowLayout {
                Label { text: (backend.uiTrigger, backend.getTextWithDefault("target_lang_label", "Target Language:")); color: root.secondaryTextColor; Layout.preferredWidth: 100 }
                ComboBox {
                    id: tmLangCombo
                    Layout.fillWidth: true
                    model: backend.getTargetLanguages()
                    textRole: "name"
                    valueRole: "code"
                }
            }

            // TM Kaynak Listesi
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(tmSourcesCol.height + 20, 200)
                radius: 8
                color: root.inputBackground
                border.color: root.borderColor
                visible: tmSourcesRepeater.count > 0

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true

                    ColumnLayout {
                        id: tmSourcesCol
                        width: parent.width
                        spacing: 6

                        Label {
                            text: (backend.uiTrigger, backend.getTextWithDefault("tm_existing_sources", "Existing TM Sources:"))
                            font.bold: true
                            color: root.mainTextColor
                            font.pixelSize: 13
                        }

                        Repeater {
                            id: tmSourcesRepeater
                            model: tmImportDialog.visible ? backend.getAvailableTMSources() : []

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Label {
                                    text: "📚 " + modelData.name + " (" + modelData.language + ") — " + modelData.entry_count + " entries"
                                    color: root.secondaryTextColor
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Button {
                                    text: "🗑️"
                                    flat: true
                                    implicitWidth: 32
                                    implicitHeight: 28
                                    onClicked: {
                                        backend.deleteTMSource(modelData.file_path)
                                        tmSourcesRepeater.model = backend.getAvailableTMSources()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        footer: DialogButtonBox {
            background: Rectangle { color: "transparent" }
            Button {
                text: (backend.uiTrigger, backend.getTextWithDefault("btn_cancel", "Cancel"))
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                flat: true
            }
            Button {
                text: (backend.uiTrigger, backend.getTextWithDefault("tm_btn_import", "Import TM"))
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                highlighted: true
                enabled: tmPathField.text.length > 0
                onClicked: {
                    backend.importExternalTM(tmPathField.text, tmSourceNameField.text, tmLangCombo.currentValue)
                    tmImportDialog.close()
                }
            }
        }
    }

    FolderDialog {
        id: tmFolderDialog
        title: (backend.uiTrigger, backend.getTextWithDefault("tm_select_folder_title", "Select tl/<language> Folder"))
        currentFolder: "file:///" + backend.get_app_path()
        onAccepted: tmPathField.text = selectedFolder.toString().replace("file:///", "")
    }

    component ToolCard: Rectangle {
        id: toolCardRoot
        property string title: ""
        property string desc: ""
        property string icon: ""
        property string btnText: (backend.uiTrigger, backend.getTextWithDefault("btn_open", "Open"))
        signal clicked()

        width: 280
        height: 250
        radius: 12
        color: root.cardBackground
        border.color: actionButton.hovered ? Material.accent : root.borderColor
        border.width: actionButton.hovered ? 2 : 1
        
        Behavior on border.color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            RowLayout {
                spacing: 15
                Layout.fillWidth: true
                Label { text: icon; font.pixelSize: 28; Layout.alignment: Qt.AlignVCenter }
                Label { 
                    text: title
                    font.bold: true
                    font.pixelSize: 16
                    color: root.mainTextColor
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            Rectangle { Layout.fillWidth: true; height: 1; color: root.separatorColor }

            // Açıklama Metni (Esnek alan)
            Label { 
                text: desc; 
                color: root.secondaryTextColor; 
                font.pixelSize: 13; 
                Layout.fillWidth: true; 
                wrapMode: Text.Wrap; 
                Layout.fillHeight: true 
                verticalAlignment: Text.AlignTop
                elide: Text.ElideNone
                clip: true
            }

            // Buton (En altta)
            Button {
                id: actionButton
                // Use backend.isBusy to disable ALL tools when one is running + local visual timer
                text: (busyTimer.running || backend.isBusy) ? "..." : btnText
                enabled: !busyTimer.running && !backend.isBusy
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                onClicked: {
                    toolCardRoot.clicked()
                    busyTimer.start()
                }
                highlighted: true
                Material.elevation: 0
                
                Timer {
                    id: busyTimer
                    interval: 1000 // Short visual feedback only
                    running: false
                }
                
                contentItem: Label {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.bold: true
                }
            }
        }
    }
}
