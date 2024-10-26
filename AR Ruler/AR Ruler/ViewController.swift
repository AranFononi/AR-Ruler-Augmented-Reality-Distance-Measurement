//
//  ViewController.swift
//  AR Ruler
//
//  Created by AranApps on 23/10/2024.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var dotNodes = [SCNNode]()
    var textNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if dotNodes.count >= 2 {
            for dotNode in dotNodes {
                dotNode.removeFromParentNode()
            }
            dotNodes.removeAll()
        }
        
        if let touchLocation = touches.first?.location(in: sceneView) {
            if let hitTest = sceneView.raycastQuery(
                from: touchLocation,
                allowing: .existingPlaneInfinite,
                alignment: .any
            ) {
                if let result = raycast(query: hitTest) {
                    addDot(at: result)
                } else {
                    print("Raycast did not hit any planes.")
                }
            }
        }
    }
    
    func raycast(query: ARRaycastQuery) -> ARRaycastResult? {
        let results = sceneView.session.raycast(query)
        if results.isEmpty {
            print("No hit results found")
            return nil
        }
        return results.first
    }
    
    func addDot(at hitResult: ARRaycastResult) {
        let dotGeometry = SCNSphere(radius: 0.005)
        let dotMaterial = SCNMaterial()
        dotMaterial.diffuse.contents = UIColor.red
        dotGeometry.materials = [dotMaterial]
        
        let dotNode = SCNNode(geometry: dotGeometry)
        let transform = hitResult.worldTransform
        
        dotNode.position = SCNVector3(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
        
        sceneView.scene.rootNode.addChildNode(dotNode)
        dotNodes.append(dotNode)
        
        if dotNodes.count >= 2 {
            calculate()
        }
    }
    
    func calculate() {
        let start = dotNodes.first!
        let end = dotNodes.last!
    
        let distance = sqrt(
            pow(end.position.x - start.position.x, 2) +
            pow(end.position.y - start.position.y, 2) +
            pow(end.position.z - start.position.z, 2)
        )
    
        updateText(
            text: "\(String(format: "%.2f", abs(distance * 100))) CM",
            atPosition: end.position
        )
    }
    
    func updateText(text: String, atPosition position: SCNVector3) {
        textNode.removeFromParentNode()
        
        let textGeometry = SCNText(string: text, extrusionDepth: 1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.red
        
        textNode = SCNNode(geometry: textGeometry)
        
        textNode.position = SCNVector3(
            position.x,
            position.y + 0.05,
            position.z
        )
        
        textNode.scale = SCNVector3(0.02, 0.02, 0.02)
        sceneView.scene.rootNode.addChildNode(textNode)
    }
}
