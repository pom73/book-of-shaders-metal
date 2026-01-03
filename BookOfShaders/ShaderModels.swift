
import SwiftUI

// under this shaderImportDirName every directory is a section and metal files under are shaders to be loaded
let shaderImportDirName = String("ShadersForBookofShaders")
let defaultFragmentShader = """
   #include <metal_stdlib>
   using namespace metal;

   [[fragment]]
   float4 fragment_main() {
       // Return a solid color for every pixel (magenta by default).
       // The fourth component of the color is alpha, representing
       // opacity. It has no effect because blending isn't enabled.
       // But try changing the other values to change the color!
       return float4(1.0f, 0.0f, 1.0f, 1.0f);
   }
"""

struct ShaderExample : Identifiable {
    var id: String { return title }
    let title: String
    let fileName: String
    let entryPoint: String = "fragment_main"
    var fragmentShaderSource : String?
    var compileShader : String?
    
    init(title: String, fileName: URL) {
        self.title = title
        self.fileName = fileName.path()
        fragmentShaderSource =  try? String(contentsOf: fileName, encoding: .utf8)
    }
    
    
    init(title: String, fileName: String) {
        self.title = title
        self.fileName = fileName
        
        if let sourceURL = Bundle.main.url(forResource: fileName, withExtension: "metal") {
            fragmentShaderSource =  try? String(contentsOf: sourceURL, encoding: .utf8)
        } else {
            if FileManager.default.fileExists(atPath: fileName) == false {
                fragmentShaderSource =  try? String(contentsOfFile: fileName, encoding: .utf8)
            }
        }
    }
    
    
    mutating func updateFragmentShader(_ newSource: String) {
        fragmentShaderSource = newSource
    }
    
    mutating func updateErrorShader(_ compileError: String) {
        compileShader = compileError
    }

}

struct ShaderExampleSection : Identifiable {
    var id: String { return title }
    let title: String
    var examples: [ShaderExample]
}

class ShaderExampleStore : ObservableObject {
    
    var existingSectionNames : [String] {
        sections.map({$0.title})
    }
    
    var existingShaderNames : [String] {
        sections.flatMap(\.examples).map(\.id)
    }
  
    var defaultStorePath: URL? {
        return createShadersFolderIfNeeded()
    }
    
    private func createShadersFolderIfNeeded() -> URL? {
        guard let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
              ).first
        else {
            print("Could not locate the Documents directory.")
            fatalError()
        }
     
        let shadersFolderURL = documentsURL.appendingPathComponent(shaderImportDirName)

        do {
            try FileManager.default.createDirectory(
                at: shadersFolderURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            return shadersFolderURL
        } catch {
            print("❌ Could not create Shaders folder: \(error)")
        }

        return shadersFolderURL
    }
    
    func serializeToFragments() {
        if let _shadersFolderURL = createShadersFolderIfNeeded() {
           
            for section in sections {
                let sectionFolder = _shadersFolderURL.appendingPathComponent(section.title);
                do { try FileManager.default.createDirectory(at: sectionFolder,withIntermediateDirectories: true,attributes: nil) }
                catch( let error ) { print("creating sections folder: \(error)") }
                
                for exampleItem in section.examples {
                    if let data = exampleItem.fragmentShaderSource?.data(using: .utf8) {
                        do {
                            let filePath = sectionFolder.appending(component: exampleItem.title + ".metal")
                            try data.write(to: filePath)
                        } catch( let error ) {
                            print("Error while fragmentSerialize: \(error)")

                        }
                    }
                }
            }
        }
    }
    
    func newShaderExample(_ toSection : String, _ newShaderName : String ) {
        addSections(ShaderExampleSection(title: toSection, examples: []))
        
        if let sectionIdx = sections.firstIndex(where: {$0.title == toSection}),
           let _storeShaders = createShadersFolderIfNeeded() {
            
            let existingcount   = existingShaderNames.count(where: {$0.contains(newShaderName) })
            
            let finalShaderName = (existingcount != 0) ? newShaderName + "\(existingcount)" : newShaderName
            let fragmentSource  = (existingcount != 0) ?
            sections.first(where: {$0.examples.contains(where: {$0.title == newShaderName})})?.examples.first(where: {$0.title == newShaderName})!.fragmentShaderSource! :  defaultFragmentShader
            
            let toFileURL  = _storeShaders.appendingPathComponent(finalShaderName+".metal")
            let dataToFile = fragmentSource!.data(using: .utf8)
            
            do
            {
                try dataToFile?.write(to: toFileURL)
                sections[sectionIdx].examples.append(ShaderExample(title: finalShaderName,fileName :toFileURL))
            }
            catch(let error) {
                print("Error creating shader : \(error)")
            }
        }
    }
    
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(onShaderCompiled), name: .didFragmentShaderCompiled, object: nil)
        if let _shadersFolderURL = createShadersFolderIfNeeded() {
            sections.removeAll(keepingCapacity: true)
            
            do
            {
                let files = try FileManager.default.contentsOfDirectory( at: _shadersFolderURL, includingPropertiesForKeys: [.nameKey, .isDirectoryKey], options: [.skipsHiddenFiles] )
                
                // every directory is a section and metal files under are shaders to be loaded
                
                for urlDir in files {
                    if urlDir.hasDirectoryPath{
                        addSections(ShaderExampleSection(title: urlDir.lastPathComponent, examples: []))

                        let shaders = try FileManager.default.contentsOfDirectory( at: urlDir, includingPropertiesForKeys: [.nameKey, .isDirectoryKey], options: [.skipsHiddenFiles] )

                        for urlShader in shaders {
                            if urlShader.pathExtension == "metal" {
                                print("Found a shader source:", urlShader.lastPathComponent)
                                addShaderToSections(urlDir.lastPathComponent, ShaderExample(title: urlShader.deletingPathExtension().lastPathComponent, fileName: urlShader))
                            }
                        }
                    }
                }
            }
            catch(let error) {
                print("\(error)")
            }
        }
        
    }
    
    @objc func onShaderCompiled(shaderCompiledNotif : NSNotification ){
        
        if let example = shaderCompiledNotif.object as? ShaderExample {
            
            if let newSource = shaderCompiledNotif.userInfo?["NewSource"] as? String {
                updateFragment(shaderExample: example,fragment: newSource)
            }

            if let compileError = shaderCompiledNotif.userInfo?["Error"] as? String {
                updateError(shaderExample: example,compileError: compileError)
            }
        }
    }
    
    func addSections(_ newSection : ShaderExampleSection)  {
        if sections.contains(where:{ $0.id == newSection.id} ) == false {
           sections.append(newSection)
        }
    }

    func addShaderToSections(_ toSection : String, _ shaderExample : ShaderExample) {
        
        if let _sectionsidx = sections.firstIndex(where: { $0.id == toSection } ) {
            sections[_sectionsidx].examples.append(shaderExample)
        }
    }

    func remShaderExample(_ shaderName : String ) {
        
        if let _sectionsidx = sections.firstIndex(where: { $0.examples.contains(where: { $0.id == shaderName }) } ) {
            sections[_sectionsidx].examples.removeAll(where: { example in example.id == shaderName } )
        }
    }

    
    @Published var sections : [ShaderExampleSection] = [
//        ShaderExampleSection(title: "Hello World", examples: [
//            ShaderExample(title: "Solid Color", fileName: "02-hello-world")
//        ]),
//        ShaderExampleSection(title: "Uniforms", examples: [
//            ShaderExample(title: "Time", fileName: "03a-uniforms-time"),
//            ShaderExample(title: "Fragment Coordinates", fileName: "03b-fragment-coord")
//        ]),
//        ShaderExampleSection(title: "Shaping Functions", examples: [
//            ShaderExample(title: "Line", fileName:"05a-shape-line"),
//            ShaderExample(title: "Quintic Curve", fileName:"05b-shape-quintic"),
//            ShaderExample(title: "Step", fileName:"05c-shape-step"),
//            ShaderExample(title: "Smoothstep", fileName:"05d-shape-smoothstep")
//        ]),
//        ShaderExampleSection(title: "Colors", examples: [
//            ShaderExample(title: "Mixing Colors", fileName:"06a-color-mix"),
//            //ShaderExample(title: "Color Gradients", fileName:"06b-color-gradient"),
//            //ShaderExample(title: "HSB Color Space", fileName:"06c-color-hsb"),
//            //ShaderExample(title: "HSB in Polar Coordinates", fileName:"06d-color-polar")
//        ]),
        /*
        ShaderExampleSection(title: "Shapes", examples: [
            ShaderExample(title: "Rectangle", fileName: "07a-shape-rectangle"),
            ShaderExample(title: "Circle", fileName: "07b-shape-circle"),
            ShaderExample(title: "Circle SDF", fileName: "07c-sdf-circle"),
            ShaderExample(title: "Round Rect", fileName: "07d-sdf-circles"),
            ShaderExample(title: "Polar Shapes", fileName: "07e-sdf-lobes"),
            ShaderExample(title: "Triangle", fileName: "07f-sdf-triangle")
        ]),
        ShaderExampleSection(title: "Matrices", examples: [
            ShaderExample(title: "Translate", fileName: "08a-matrix-translate"),
            ShaderExample(title: "Rotate", fileName: "08b-matrix-rotate"),
            ShaderExample(title: "Scale", fileName: "08c-matrix-scale"),
            ShaderExample(title: "YUV Color Space", fileName: "08d-matrix-yuv")
        ]),
        ShaderExampleSection(title: "Patterns", examples: [
            ShaderExample(title: "Spaces", fileName: "09a-pattern-spaces"),
            ShaderExample(title: "Squares", fileName: "09b-pattern-squares"),
            ShaderExample(title: "Bricks", fileName: "09c-pattern-bricks"),
            ShaderExample(title: "Tiles", fileName: "09d-pattern-tiles"),
        ]),
        ShaderExampleSection(title: "Random", examples: [
            ShaderExample(title: "Random", fileName: "10a-random"),
            ShaderExample(title: "Random Grid", fileName: "10b-random-grid"),
            ShaderExample(title: "Random Truchet Tiles", fileName: "10c-random-truchet")
        ]),
        ShaderExampleSection(title: "Noise", examples: [
            ShaderExample(title: "Noise", fileName: "11a-noise"),
            ShaderExample(title: "Simplex Noise", fileName: "11b-noise-simplex")
        ]),
        ShaderExampleSection(title: "Cellular Noise", examples: [
            ShaderExample(title: "Point Distance", fileName: "12a-point-distance"),
            ShaderExample(title: "Cellular Noise", fileName: "12b-cellular-noise"),
            ShaderExample(title: "Voronoi", fileName: "12c-voronoi")
        ]),
        ShaderExampleSection(title: "Fractal Brownian Motion", examples: [
            ShaderExample(title: "fBm", fileName: "13a-fbm"),
            ShaderExample(title: "Domain Warping", fileName: "13b-fbm-domain-warping")
        ])
        */
    ]

    func example(for id: String) -> ShaderExample? {
        // Linear scan isn't great, but given that we'll never have more than a few dozen examples, it's fine.
        for section in sections {
            for example in section.examples {
                if example.id == id {
                    return example
                }
            }
        }
        return nil
    }
    
    func updateFragment(shaderExample : ShaderExample, fragment : String )
    {
        for idx in sections.indices {
            for idxSample in sections[idx].examples.indices {
                if  sections[idx].examples[idxSample].id == shaderExample.id {
                    sections[idx].examples[idxSample].updateFragmentShader(fragment)
                }
            }
        }
    }

    func updateError(shaderExample : ShaderExample, compileError : String )
    {
        for idx in sections.indices {
            for idxSample in sections[idx].examples.indices {
                if  sections[idx].examples[idxSample].id == shaderExample.id {
                    sections[idx].examples[idxSample].updateErrorShader(compileError)
                }
            }
        }
    }
}
