//
//  ContentView.swift
//  SpaceKit
//
//  Created by Arthur Nsereko Kahwa on 5/11/23.
//

import SwiftUI
import RealityKit
import Combine

struct ContentView : View {
    let kitItems = ["habitat", "rover", "suit"]
    @State private var selectedItem: String?
    
    init() {
        selectedItem = kitItems.randomElement()
    }
    
    var body: some View {
        NavigationSplitView {
            List(kitItems, id: \.self, selection: $selectedItem) { item in
                Text(item)
            }
            .navigationTitle("Kit List")
        } detail: {
            if let selectedItem = selectedItem {
                Text("Tap to show a \(selectedItem)")
                    .font(.caption2)
                
                ARViewContainer(kitName: selectedItem)
                    .edgesIgnoringSafeArea(.bottom)
            }
            else {
                EmptyView()
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var kitName: String?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(from:)))
        arView.addGestureRecognizer(tapGestureRecogniser)
        
        return arView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        
        weak var arView: ARView?
        var cancellable: AnyCancellable?
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc
        func handleTap(from recogniser: UIGestureRecognizer) {
            // Make sure we have a view to work with
            guard let arView = arView
            else { return }
            
            // Make sure we do not have duplicates
            guard arView.scene.anchors.first(where: { $0.name == parent.kitName}) == nil
            else {
                return
            }
            
            // Make sure we have the name of kit we want to show
            if let kitName = parent.kitName {
                if let raycast = arView.raycast(from: arView.center,
                                                allowing: .estimatedPlane,
                                                alignment: .horizontal).first {
                    let anchor = AnchorEntity(raycastResult: raycast)
                    anchor.name = kitName
                    
                    cancellable = ModelEntity.loadAsync(named: kitName)
                        .sink(receiveCompletion: { fetchComplete in
                            if case let .failure(error) = fetchComplete {
                                print("Error: \(String(describing: error))")
                            }
                            
                            self.cancellable?.cancel()
                            
                        }, receiveValue: { modelEntity in
                            anchor.addChild(modelEntity)
                        })
                    
                    arView.scene.addAnchor(anchor)
                }
            }
        }
    }
}
