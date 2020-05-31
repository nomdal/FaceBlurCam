/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for this sample app.
*/

import UIKit
import AVFoundation

class APLViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    private var blurFace: BlurFace?
    
    @IBOutlet weak var blurCamButton: UIButton!
    
    @IBAction func blurCamButtonTapped(_ sender: UIButton) {
        showImagePickerForCamera()
    }
    
    /// An image picker controller instance.
	var imagePickerController = UIImagePickerController()
	
	var capturedImages = [UIImage]()
	
	// MARK: - View Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()

		imagePickerController.modalPresentationStyle = .currentContext
        /*
         Assign a delegate for the image picker. The delegate receives
         notifications when the user picks an image or movie, or exits the
         picker interface. The delegate also decides when to dismiss the picker
         interface.
        */
		imagePickerController.delegate = self

        /*
         This app requires use of the device's camera. The app checks for device
         availability using the `isSourceTypeAvailable` method. If the
         camera isn't available, the app removes the camera button from the
         custom user interface.
         */
    }
    
    func blurImageWithImage(image: UIImage) -> UIImage {
        if let blurFace = blurFace {
            blurFace.setImage(image: image)
        }
        else {
            blurFace = BlurFace(image: image)
        }
        var image = UIImage()
        if blurFace!.hasFaces() {
            print("this has faces")
            image = blurFace?.blurFaces() as! UIImage
        } else {
            print("this does not have faces")
        }
        return image
    }

	func finishAndUpdate() {
		dismiss(animated: true, completion: { [weak self] in
			guard let self = self else {
				return
			}

            self.showImagePickerForCamera()

		})
	}
	
    func showImagePickerForCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        if authStatus == AVAuthorizationStatus.denied {
            // The system denied access to the camera. Alert the user.

            /*
             The user previously denied access to the camera. Tell the user this
             app requires camera access.
            */
            let alert = UIAlertController(title: "Unable to access the Camera",
                                          message: "To turn on camera access, choose Settings > Privacy > Camera and turn on Camera access for this app.",
                                          preferredStyle: UIAlertController.Style.alert)
            
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(okAction)
            
            let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
                // Take the user to the Settings app to change permissions.
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        // The resource finished opening.
                    })
                }
            })
            alert.addAction(settingsAction)
            
            present(alert, animated: true, completion: nil)
        } else if authStatus == AVAuthorizationStatus.notDetermined {
            /*
             The user never granted or denied permission for media capture with
             the camera. Ask for permission.

             Note: The app must provide a `Privacy - Camera Usage Description`
             key in the Info.plist with a message telling the user why the app
             is requesting access to the device’s camera. See this app's
             Info.plist for such an example usage description.
            */
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.showImagePicker(sourceType: UIImagePickerController.SourceType.camera)
                    }
                }
            })
        } else {
            /*
             The user granted permission to access the camera. Present the
             picker for capture.

             Set the image picker `sourceType` property to
             `UIImagePickerController.SourceType.camera` to configure the picker
             for media capture instead of browsing saved media.
            */
            showImagePicker(sourceType: UIImagePickerController.SourceType.camera)
        }
    }
    
    func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        if !capturedImages.isEmpty {
            capturedImages.removeAll()
        }

        imagePickerController.sourceType = sourceType
        imagePickerController.modalPresentationStyle =
            (sourceType == UIImagePickerController.SourceType.camera) ?
                UIModalPresentationStyle.fullScreen : UIModalPresentationStyle.popover
        
        let presentationController = imagePickerController.popoverPresentationController
        // Display a popover from the UIBarButtonItem as an anchor.
        //presentationController?.barButtonItem = button
        presentationController?.permittedArrowDirections = UIPopoverArrowDirection.any

        if sourceType == UIImagePickerController.SourceType.camera {

            imagePickerController.showsCameraControls = true

        }
        
        /*
         The creation and configuration of the camera or media browser
         interface is now complete.

         Asynchronously present the picker interface using the
         `present(_:animated:completion:)` method.
        */
        present(imagePickerController, animated: true, completion: {
            // The block to execute after the presentation finishes.
        })
    }
	
	// MARK: - UIImagePickerControllerDelegate
    /**
    You must implement the following methods that conform to the
    `UIImagePickerControllerDelegate` protocol to respond to user interactions
    with the image picker.

    When the user taps a button in the camera interface to accept a newly
    captured picture, the system notifies the delegate of the user’s choice by
    invoking the `imagePickerController(_:didFinishPickingMediaWithInfo:)`
    method. Your delegate object’s implementation of this method can perform
    any custom processing on the passed media, and should dismiss the picker.
    The delegate methods are always responsible for dismissing the picker when
    the operation completes.
    */
    
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }
        
        let blurredImage = self.blurImageWithImage(image: image)
        
        capturedImages.append(blurredImage)
        
        UIImageWriteToSavedPhotosAlbum(blurredImage, nil, nil, nil)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        finishAndUpdate()

    }

    /**
    If the user cancels the operation, the system invokes the delegate's
    `imagePickerControllerDidCancel(_:)` method, and you should dismiss the
    picker.
    */
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: {
        /*
         The dismiss method calls this block after dismissing the image picker
         from the view controller stack. Perform any additional cleanup here.
        */
		})
	}
}

// MARK: - Utilities
private func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) })
}

private func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
