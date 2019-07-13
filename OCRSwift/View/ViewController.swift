import UIKit
import SwiftyJSON
import AVFoundation
import Alamofire
import TwitterKit

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate{
    
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var takeButton: UIBarButtonItem!
    
    @IBOutlet weak var statusLabel: UIBarButtonItem!
    
    var captureSession: AVCaptureSession!
    
    var capturePhotoOutput: AVCapturePhotoOutput?
    
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        captureSession = AVCaptureSession()
        capturePhotoOutput = AVCapturePhotoOutput()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice!)
            if (captureSession.canAddInput(captureDeviceInput)){
                captureSession.addInput(captureDeviceInput)
                if (captureSession.canAddOutput(capturePhotoOutput!)){
                    captureSession.addOutput(capturePhotoOutput!)
                    captureSession.startRunning()
                    
                    captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    captureVideoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
                    captureVideoPreviewLayer?.connection!.videoOrientation = AVCaptureVideoOrientation.portrait
                    
                    cameraView.layer.addSublayer(captureVideoPreviewLayer!)
                    
                    captureVideoPreviewLayer?.position = CGPoint(x: self.cameraView.frame.width/2, y: self.cameraView.frame.height/2)
                    captureVideoPreviewLayer?.bounds = cameraView.frame
                }
            }
        } catch {
            print(error)
        }
    }
    @IBAction func takePicture(_ sender: Any) {
        statusLabel.title = "処理中..."
        let capturePhotoSettings = AVCapturePhotoSettings()
        capturePhotoSettings.flashMode = .auto
        capturePhotoSettings.isAutoStillImageStabilizationEnabled = true
        capturePhotoSettings.isHighResolutionPhotoEnabled = false
        
        capturePhotoOutput!.capturePhoto(with: capturePhotoSettings, delegate: self)
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        statusLabel.title = "撮影しました"
        if let imageData = photo.fileDataRepresentation(){
            readText(imageData)
        }
    }
    
    fileprivate func readText(_ imageData: Data){
        Alamofire.upload(imageData,
                         to: "https://japaneast.api.cognitive.microsoft.com/vision/v1.0/ocr?language=ja&detectOrientation=true",
                         method: .post,
                         headers: [
                            "Content-Type": "application/octet-stream",
                            "Ocp-Apim-Subscription-Key": "use Api key1"
            ]).validate(statusCode: 200...226)
            .responseJSON { response in self.readTextResponse(response: response)}
    }
    
    fileprivate func readTextResponse(response: DataResponse<Any>) {
        guard let result = response.result.value else {
            statusLabel.title = "テキスト化失敗"
            return
        }
        
        statusLabel.title = "テキスト化成功"
        
        var text: String = ""
        let json = JSON(result)
        json["regions"].forEach { (_, region) in
            region["lines"].forEach { (_, line) in
                line["words"].forEach { (_, word) in
                    text.append(word["text"].string!)
                }
                text.append("\n")
            }
        }
        
        print(text)
        
        
    }
    
}
