/*
Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var plane: SCNPlane?
    
    @IBOutlet weak var filterMenu: UIStackView!
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the AR experience
        resetTracking()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        //Find max number of images that can be tracked simultaneously
        if #available(iOS 12.0, *) {
            configuration.maximumNumberOfTrackedImages = 9
            print(configuration.maximumNumberOfTrackedImages)
        } else {
            // Fallback on earlier versions
        }
        
        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        updateQueue.async {
            
            // Create a plane to visualize the initial position of the detected image.
            
            self.plane = SCNPlane(width: referenceImage.physicalSize.width,
                                 height: referenceImage.physicalSize.height)
//            let plane = SCNPlane(width: 0.05,
//                                 height: 0.09)
//
            self.plane?.firstMaterial?.diffuse.contents = UIImage(named: "recyclable.png")
            
        
            let planeNode = SCNNode(geometry: self.plane)
            planeNode.opacity = 0.98
            
           //stuff
            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            planeNode.eulerAngles.x = -.pi / 2
            
            /*
             Image anchors are not tracked after initial detection, so create an
             animation that limits the duration for which the plane visualization appears.
             */
            planeNode.runAction(self.imageHighlightAction)
            
            // Add the plane visualization to the scene.
            node.addChildNode(planeNode)
        }

        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("Detected image “\(imageName)”")
        }
    }

    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0),
            .fadeOpacity(to: 1, duration: 1000),
//            .fadeOpacity(to: 0.15, duration: 0.25),
//            .fadeOpacity(to: 0.85, duration: 1000),
//            .fadeOut(duration: 0.5),
            .removeFromParentNode()
        ])
    }
    

    
    
    
    @IBAction func fairtradeClicked(_ sender: Any) {
        self.plane?.firstMaterial?.diffuse.contents = UIImage(named: "fairtrade.png")
        self.statusViewController.showMessage("Fairtrade")
    }
    
    @IBAction func nonGmoClicked(_ sender: Any) {
        self.plane?.firstMaterial?.diffuse.contents = UIImage(named: "nonGMO.png")
    }
    
    @IBAction func recyclableClicked(_ sender: Any) {
        self.plane?.firstMaterial?.diffuse.contents = UIImage(named: "recyclable.png")
    }
    
    @IBAction func organicClicked(_ sender: Any) {
        self.plane?.firstMaterial?.diffuse.contents = UIImage(named: "organic.png")
    }
    
    @IBAction func rainforestClicked(_ sender: Any) {
        self.plane?.firstMaterial?.diffuse.contents = UIImage(named: "rainforest-alliance.png")
    }
    
    
    
    //    @IBAction func menuToggle(_ sender: Any)
//    {
//        self.filterMenu.isHidden = !self.filterMenu.isHidden
//    }
    
}
