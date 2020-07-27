//
//  ViewController.swift
//  StudentCardAR
//
//  Created by Marlon Lückert on 22.06.20.
//  Copyright © 2020 Marlon Lückert. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var placeholderImage: UIImageView!
    
    var cardModelNode: SCNNode!
    var boardingcardModelNode: SCNNode!
    var mileageModelNode: SCNNode!
    var textModelNode: SCNNode!
    var mapModelNode: SCNNode!
    var planeNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false

        let cardModelScene = SCNScene(named: "art.scnassets/CARD.scn")!
        cardModelNode =  cardModelScene.rootNode.childNode(withName: "CARD", recursively: true)
        boardingcardModelNode =  cardModelScene.rootNode.childNode(withName: "boardingcard", recursively: true)
        mileageModelNode = cardModelScene.rootNode.childNode(withName: "mileage", recursively: true)
        textModelNode = cardModelScene.rootNode.childNode(withName: "Text", recursively: true)
        mapModelNode = cardModelScene.rootNode.childNode(withName: "map", recursively: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARImageTrackingConfiguration()

        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            // failed to read them – crash immediately!
            fatalError("Couldn't load tracking images.")
        }

        configuration.trackingImages = trackingImages
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // make sure this is an image anchor, otherwise bail out
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        guard let imageName = imageAnchor.referenceImage.name else { return nil }
        
        DispatchQueue.main.async {
            self.placeholderImage.isHidden = true
        }
                
        let node = SCNNode()
        
        if imageName == "studentid" {
            cardModelNode.scale = SCNVector3(x: 0, y: 0, z: 0)
            cardModelNode.position.y = 0.015
            node.addChildNode(cardModelNode)
            
            textModelNode.scale = SCNVector3(x: 0.04, y: 0.04, z: 0.04)
            textModelNode.position.y = 0.01
            textModelNode.position.z = -0.045
            textModelNode.opacity = 0
            node.addChildNode(textModelNode)
            
            boardingcardModelNode.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
            boardingcardModelNode.eulerAngles.y = -.pi / 2
            boardingcardModelNode.position.y = 0.005
            boardingcardModelNode.position.x = 0.08
            boardingcardModelNode.opacity = 0
            node.addChildNode(boardingcardModelNode)
            
            mileageModelNode.scale = SCNVector3(x: 0.045, y: 0.045, z: 0.045)
            mileageModelNode.eulerAngles.y = .pi / 2
            mileageModelNode.position.y = 0.005
            mileageModelNode.position.x = -0.08
            mileageModelNode.opacity = 0
            node.addChildNode(mileageModelNode)
            
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width,
                                 height: imageAnchor.referenceImage.physicalSize.height)
            planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
        } else {
            mapModelNode.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
            mapModelNode.position.y = 0.01
            node.addChildNode(mapModelNode)
        }
        
        let spotLight = createSpotLight()
        
        node.addChildNode(spotLight)

        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        if (!imageAnchor.isTracked) {
            cardModelNode.scale = SCNVector3(x: 0, y: 0, z: 0)
            return
        }
        
        
        if cardModelNode.scale.x == 0 {
            boardingcardModelNode.opacity = 0
            mileageModelNode.opacity = 0
            textModelNode.opacity = 0
            let scaleAction = SCNAction.scale(to: 0.05, duration: 0.3)
            scaleAction.timingMode = SCNActionTimingMode.easeInEaseOut
            cardModelNode.runAction(scaleAction)
        }
        
        let (min, max) = planeNode.boundingBox
        let bottomLeft = SCNVector3(min.x, min.y, 0)
        let topRight = SCNVector3(max.x, max.y, 0)

        let topLeft = SCNVector3(min.x, max.y, 0)
        let bottomRight = SCNVector3(max.x, min.y, 0)
        
        let worldBottomLeft = planeNode.convertPosition(bottomLeft, to: sceneView.scene.rootNode)
        let worldTopRight = planeNode.convertPosition(topRight, to: sceneView.scene.rootNode)

        let worldTopLeft = planeNode.convertPosition(topLeft, to: sceneView.scene.rootNode)
        let worldBottomRight = planeNode.convertPosition(bottomRight, to: sceneView.scene.rootNode)
        
        let screenTopLeft = renderer.projectPoint(worldTopLeft)
        let screenTopRight = renderer.projectPoint(worldTopRight)
        let screenBottomRight = renderer.projectPoint(worldBottomRight)
        let screenBottomLeft = renderer.projectPoint(worldBottomLeft)
        
        
        let fadeIn = SCNAction.sequence([SCNAction.wait(duration: 0.4),  SCNAction.fadeOpacity(to: 1, duration: 0.2)])
        let fadeOut = SCNAction.fadeOpacity(to: 0, duration: 0.2)

        if (screenTopRight.y > screenBottomLeft.y) {
            //left
            cardModelNode.runAction(SCNAction.rotateTo(x: 0, y: .pi / 2, z: 0, duration: 0.3))
            boardingcardModelNode.runAction(fadeOut)
            mileageModelNode.runAction(fadeIn)
            textModelNode.runAction(fadeOut)
        } else if (screenTopLeft.y > screenBottomRight.y) {
            // right
            cardModelNode.runAction(SCNAction.rotateTo(x: 0, y: -.pi / 2, z: 0, duration: 0.3))
            boardingcardModelNode.runAction(fadeIn)
            mileageModelNode.runAction(fadeOut)
            textModelNode.runAction(fadeOut)
        } else {
            // top
            cardModelNode.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.3))
            boardingcardModelNode.runAction(fadeOut)
            mileageModelNode.runAction(fadeOut)
            textModelNode.runAction(fadeIn)
        }
            

    }
    
    func createSpotLight() -> SCNNode {
        let spotLight = SCNNode()
        spotLight.light = SCNLight()
        spotLight.scale = SCNVector3(1,1,1)
        spotLight.light?.intensity = 600
        spotLight.light?.shadowMode = .deferred
        spotLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.75)
        spotLight.light?.automaticallyAdjustsShadowProjection = true
        spotLight.castsShadow = true
        spotLight.position = SCNVector3Zero
        spotLight.eulerAngles.x = -.pi / 2
        spotLight.light?.type = SCNLight.LightType.directional
        spotLight.light?.color = UIColor.white
        
        return spotLight
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
