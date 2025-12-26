import Foundation
import SwiftUI
import MetalKit
import Splash
import UniformTypeIdentifiers


enum ShaderModelOperation {
    case nop, addShader, remShader;
}


class ShaderEditorModel: ObservableObject {
    @Published var selectedExampleID: String? {
        didSet {
            if let selectedExampleID,
               let example = exampleStore.example(for: selectedExampleID),
               let source = example.fragmentShaderSource
            {
                renderer.example = example
                renderer.fragmentFunctionSource = example.fragmentShaderSource
                sourceString = sourceHighlighter.highlight(source)
            }
        }
    }
    
    @Published var sourceString = NSAttributedString(string: "") {
        didSet {
            renderer.fragmentFunctionSource = sourceString.string
        }
    }

    let theme: Theme
    let font = Splash.Font(name: "Monaco", size: 12.0)
    let grammar = MetalGrammar()
    let sourceHighlighter: SyntaxHighlighter<AttributedStringOutputFormat>
  
    
    let exampleStore = ShaderExampleStore()
    let device: MTLDevice
    let renderDelegate: MTKViewDelegate

    private let renderer: ShaderRenderer

    init() {
        device = MTLCreateSystemDefaultDevice()!
        renderer = ShaderRenderer(device: device)
        renderDelegate = renderer

        theme = Theme.wwdc18(withFont: font)
        sourceHighlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme),
                                              grammar: grammar)

        
        defer {
            // Auto-select the first available example
            selectedExampleID = exampleStore.sections.first?.examples.first?.id
        }
    }
    
    func ApplyOperation(_ operation: ShaderModelOperation,_ sectionName: String,_ selectedShader : String,_ fileNameURL: URL?) {
        switch operation {
            case .nop:
                break
            case .addShader:
                exampleStore.addSections(ShaderExampleSection(title: sectionName, examples: []))
                if let _fileNameURL = fileNameURL {
                    exampleStore.addShaderToSections(sectionName, ShaderExample(title: _fileNameURL.lastPathComponent.deletingPathExtension(), fileName: _fileNameURL.path()))
                }
            case .remShader:
                exampleStore.remShaderExample(selectedShader)
            
        }
    }
}

struct MetalView : NSViewRepresentable {
    typealias NSViewType = MTKView

    let device: MTLDevice
    let delegate: MTKViewDelegate

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.device = device
        view.delegate = delegate
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}

struct ShaderEditorView: View {
    @StateObject var context = ShaderTextEditorContext()
    @Binding var sourceString: NSAttributedString
    @State var compileError :String = "compile Error"

    let device: MTLDevice
    let renderDelegate: MTKViewDelegate
    let theme: Splash.Theme
    let sourceHighlighter: SyntaxHighlighter<AttributedStringOutputFormat>
   
    
    init(sourceString: Binding<NSAttributedString>,
         editorModel: ShaderEditorModel) {
        self._sourceString = sourceString
        self.device = editorModel.device
        self.renderDelegate = editorModel.renderDelegate
        self.theme = editorModel.theme
        self.sourceHighlighter = editorModel.sourceHighlighter
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading) {
                ShaderTextEditor(text: $sourceString, context: context) { textView in
                    textView.backgroundColor = theme.backgroundColor
                    textView.insertionPointColor = NSColor.white
                }
                .onChange(of: context.attributedString, perform: { newContents in
                    guard let newString = newContents?.string else { return }
                    // Re-highlight text on every keystroke. This might look like
                    // it leads to an infinite loop, but updates via the context
                    // are designed not to cause changes to be published back to us
                    context.attributedString = sourceHighlighter.highlight(newString)
                })
                Text(compileError)
                    .onReceive(NotificationCenter.default.publisher(for: .didFragmentShaderCompiled)) {
                        notification in
                        self.compileError = "No Error"
                        if let compileError = notification.userInfo?["Error"] as? String {
                            self.compileError = compileError
                        }
                    }
            }
            MetalView(device: device, delegate: renderDelegate)
                .frame(width: 200.0, height: 200.0)
                .cornerRadius(4.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 5.0)
                        .inset(by: -1.0)
                        .stroke(.white, lineWidth: 2.0)
                )
                .padding(EdgeInsets(top: 5.0, leading: 0.0, bottom: 0.0, trailing: 20.0))
        }
    }
}

struct OptionsPicker: View {
    @Binding var selection: String
    let options: [String]
    @Binding var isPresented: Bool

    var body: some View {
        // On macOS we normally use a simple window / sheet with a toolbar.
        // No NavigationView is needed because the toolbar is the natural place
        // for the “Done” button.
        VStack(spacing: 0) {
            List(options, id: \.self) { option in
                Button(action: {
                    selection = option
                    isPresented = false          // dismiss after selection
                }) {
                    HStack {
                        Text(option)
                        if option == selection {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())   // keep the row look as a list item
            }
            .listStyle(SidebarListStyle())        // macOS‑style sidebar list
        }
        .frame(minWidth: 300, maxWidth: 400, minHeight: 200, maxHeight: 400)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Done") {
                    isPresented = false
                }
            }
        }
        //.windowStyle(.plain) // optional: removes title bar if presented as a sheet
    }
}

struct DropdownWithEditField: View {
    /// The value that is edited by the user or selected from the list.
    @Binding var selection: String

    /// The list of options that the user can pick from.
    let options: [String]
    let label : String
    /// Controls whether the “picker” sheet is presented.
    @State private var isPickerPresented = false

    var body: some View {
        HStack {
            // The editable text field – shows whatever the user types.
            TextField(label, text: $selection)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Button that toggles the picker sheet.
            Button(action: { isPickerPresented.toggle() }) {
                Image(systemName: "chevron.down")
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $isPickerPresented) {
                // The picker sheet – a simple list of options.
                OptionsPicker(selection: $selection,
                              options: options,
                              isPresented: $isPickerPresented)
            }
        }
    }
}


struct FilePickerTextField: View {
    @Binding var selectedFileURL: URL?
    @State private var isFileImporterPresented: Bool = false
    // A computed property to display the path in the TextField
    var filePath: String {
        selectedFileURL?.path ?? "No file selected for \(label) "
    }
    
    let label : String
    
    var body: some View {
        HStack {
            TextField(label, text: .constant(filePath))
                .textFieldStyle(RoundedBorderTextFieldStyle()) // Use a distinct style for clarity
                .disableAutocorrection(true)
                .padding(.horizontal)
            
            Button("Select File") {
                isFileImporterPresented = true
            }
            .padding(.trailing)
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.sourceCode ], // Specify allowed file types
            allowsMultipleSelection: false // Set to true for multiple file selection
        ) { result in
            switch result {
            case .success(let urls):
                // For a single file, take the first URL
                if let firstURL = urls.first {
                    self.selectedFileURL = firstURL
                    // Note: You might need to call firstURL.startAccessingSecurityScopedResource()
                    // in sandboxed apps to access the file's contents.
                }
            case .failure(let error):
                print("File import error: \(error.localizedDescription)")
            }
        }
    }
}



struct NewShaderExample : View {
    @Environment(\.dismiss) var dismiss // For iOS 15+


    @State var sectionName: String = ""
    @State var selectedShader : String = ""
    @State var fileNameURL : URL? = nil
    
    var _shaderEditorModel : ShaderEditorModel
    @Binding var shaderModelOperation:ShaderModelOperation

    var body: some View {
        
        switch shaderModelOperation {
            case .addShader:
            VStack(alignment: .leading) {
                DropdownWithEditField(selection: $sectionName, options: _shaderEditorModel.exampleStore.existingSectionNames, label: "Section's Name" )
                FilePickerTextField(selectedFileURL: $fileNameURL, label: "Fragment Shader's file")
            }.padding()
            case .remShader:
                DropdownWithEditField(selection: $selectedShader, options: _shaderEditorModel.exampleStore.existingShaderNames, label: "Fragment's name" )
                .padding()
            case .nop:
                Text("nop")
                .padding()
        }
        
        HStack() {
            Button("Cancel") {
                dismiss() // Dismiss the view when the button is tapped
            }
            .padding()
            .buttonStyle(.bordered)
            Button("Apply") {
                _shaderEditorModel.ApplyOperation(shaderModelOperation, sectionName, selectedShader, fileNameURL )
                dismiss()
            }
            .padding()
            .buttonStyle(.bordered)
        }
    }
}
