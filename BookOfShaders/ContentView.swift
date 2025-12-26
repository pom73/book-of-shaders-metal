import SwiftUI

struct ContentView: View {
    @EnvironmentObject var editorModel: ShaderEditorModel
    @State private var showModal            = false
    @State var shaderModelOperation = ShaderModelOperation.nop
    
    var body: some View {
        NavigationView {
            List {
                ForEach(editorModel.exampleStore.sections) { section in
                    Section(section.title) {
                        ForEach(section.examples) { example in
                            NavigationLink(example.title,
                                           destination: ShaderEditorView(sourceString: $editorModel.sourceString,
                                               editorModel: editorModel),
                                           tag: example.id,
                                           selection: $editorModel.selectedExampleID)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(idealWidth: 225)
            Text("Select a shader")
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.leading")
                })
            }
            ToolbarItem(placement: .navigation) {
                Button(action: addShaderExample, label: { Image(systemName: "plus")
                })
            }
            ToolbarItem(placement: .navigation) {
                Button(action: remShaderExample, label: { Image(systemName: "minus")
                })
            }
        }
        .sheet(isPresented : $showModal ) {
            NewShaderExample(_shaderEditorModel: editorModel, shaderModelOperation: $shaderModelOperation)
        }
    }
    
    private func remShaderExample() {
        shaderModelOperation = .remShader
        showModal.toggle()
    }
    
    private func addShaderExample() {
        shaderModelOperation = .addShader
        showModal.toggle()
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)),
                                                      with: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ShaderEditorModel())
    }
}
