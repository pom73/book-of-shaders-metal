import SwiftUI


struct ContentView: View {
    @EnvironmentObject var editorModel: ShaderEditorModel
    @State private var showModal            = false
    @State var shaderModelOperation = ShaderModelOperation.nop
    @State var sectionExpanded : [String : Bool] = [:]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(editorModel.exampleStore.sections) { section in
                    Section(section.title,isExpanded: Binding<Bool> (
                        get: {sectionExpanded[section.id] ?? false},
                        set: {sectionExpanded[section.id] = $0} )) {
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
        .onAppear(perform: { editorModel.exampleStore.sections.forEach{ sectionExpanded[$0.id] = false }} )
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
            ToolbarItem(placement: .navigation) {
                Button(action: exportShaderExample, label: { Image(systemName: "square.and.arrow.down")
                })
            }
            ToolbarItem(placement: .navigation) {
                Button(action: newShaderExample, label: { Image(systemName: "plus.square.on.square")
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

    private func newShaderExample() {
        shaderModelOperation = .newShader
        showModal.toggle()
    }

    
    private func exportShaderExample() {
        editorModel.exampleStore.serializeToFragments()
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
