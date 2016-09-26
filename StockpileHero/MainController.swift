//
//  ViewController.swift
//  StockpileHero
//
//  Created by Mathew Wong on 23/09/2016.
//  Copyright © 2016 YidgetSoft. All rights reserved.
//

import UIKit
import DynamicColor
import SnapKit
import Alamofire
import SwiftyJSON
import RealmSwift
import AVFoundation
import CameraManager
import Photos

class MainController: UIViewController {
    
    let captureSession: AVCaptureSession = AVCaptureSession()
    let cameraManager: CameraManager = CameraManager()
    var captureDevice: AVCaptureDevice?
    let cameraView: UIView = UIView()
    let targetContainer: UIView = UIView()
    let crosshairHeight: Int = 30
    let crosshairWidth: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "StockpileHero"
        view.backgroundColor = DynamicColor(hexString:"#3497db").shaded()
        
        view.addSubview(cameraView)
        cameraManager.addPreviewLayerToView(cameraView)
        cameraManager.cameraDevice = .back
        cameraManager.cameraOutputMode = .stillImage
        //cameraManager.flashMode = .auto
        cameraManager.writeFilesToPhoneLibrary = false
        
        cameraView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        targetContainer.backgroundColor = UIColor.clear//UIColor(white: 1, alpha: 0.5)
        view.addSubview(targetContainer)
        
        targetContainer.snp.makeConstraints { (make) in
            make.height.width.equalTo(100)
            make.center.equalTo(self.view)
        }
        
        self.setupCrosshairs(crosshairColor: UIColor.white)
        
        let captureButton: UIButton = UIButton()
        captureButton.setTitle("Capture", for: UIControlState.normal)
        captureButton.addTarget(self, action: #selector(self.capturePhoto), for: UIControlEvents.touchUpInside)
        view.addSubview(captureButton)
        captureButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-30)
        }
    }
    
    func capturePhoto() -> Void {
        cameraManager.capturePictureWithCompletion { (image, error) in
            if let errorOccured = error {
                self.cameraManager.showErrorBlock("Error occurred", errorOccured.localizedDescription)
            } else {
                if let inventoryImage = image {
                    if let invImage = UIImagePNGRepresentation(inventoryImage.resizeWith(percentage: 0.1)!) {
                        self.handleRequest(imageData: invImage)
                        let imageURL: URL = URL(fileURLWithPath: NSTemporaryDirectory().appending("temp-image.png"))
                        try? invImage.write(to: imageURL)
                    }
                }

            }
        }
    }
    
    func handleRequest(imageData: Data) -> Void {
        print("Handling Request")

        let parameterJSON: JSON = JSON([
            "id_user": "test"
        ])

        let parameterString: String = parameterJSON.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions.prettyPrinted)!
        let jsonParameterData: Data = parameterString.data(using: String.Encoding.utf8, allowLossyConversion: true)!
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "file", fileName: "iosFile.png", mimeType: "image/png")
                multipartFormData.append(jsonParameterData, withName: "goesIntoForm")
            },
            to: "http://stockpilehero.gearfish.com/uploadFile",
            encodingCompletion: { encodingResult in
                switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseString(completionHandler: { (response) in
                            print("Success!")
                            print(response)
                        })
                    case .failure(let encodingError):
                        print("Epic Fail!")
                        print(encodingError)
                }
            }
        )

    }
    
    //delete latest camera roll photo
    func deleteLatestPhoto() -> Void {
        /* code for deleting shit from Camera Roll */
        let fetchOptions: PHFetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult: PHFetchResult =  PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        let lastImageAsset: PHAsset = fetchResult.firstObject!
        let assets: NSArray = NSArray(object: lastImageAsset)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }, completionHandler: { (Success, Error) in
            print("Finished deleting asset. Success: \(Success) or \(Error)")
        })
    }
    
    //another path to install photos but I don't know if this is a long term solution
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func setupCrosshairs(crosshairColor: UIColor) -> Void {
        
        let topLeft: UIView = UIView()
        topLeft.backgroundColor = crosshairColor
        view.addSubview(topLeft)
        topLeft.snp.makeConstraints { (make) in
            make.height.equalTo(crosshairWidth)
            make.top.left.equalTo(targetContainer)
            make.width.equalTo(crosshairHeight)
        }
        
        let leftLeftUpper: UIView = UIView()
        leftLeftUpper.backgroundColor = crosshairColor
        view.addSubview(leftLeftUpper)
        leftLeftUpper.snp.makeConstraints { (make) in
            make.width.equalTo(crosshairWidth)
            make.top.left.equalTo(targetContainer)
            make.height.equalTo(crosshairHeight)
        }
        
        let leftLeftLower: UIView = UIView()
        leftLeftLower.backgroundColor = crosshairColor
        view.addSubview(leftLeftLower)
        leftLeftLower.snp.makeConstraints { (make) in
            make.width.equalTo(crosshairWidth)
            make.bottom.left.equalTo(targetContainer)
            make.height.equalTo(crosshairHeight)
        }
        
        let lowerLeft: UIView = UIView()
        lowerLeft.backgroundColor = crosshairColor
        view.addSubview(lowerLeft)
        lowerLeft.snp.makeConstraints { (make) in
            make.width.equalTo(crosshairHeight)
            make.bottom.left.equalTo(targetContainer)
            make.height.equalTo(crosshairWidth)
        }
        
        let topRight: UIView = UIView()
        topRight.backgroundColor = crosshairColor
        view.addSubview(topRight)
        topRight.snp.makeConstraints { (make) in
            make.height.equalTo(crosshairWidth)
            make.top.right.equalTo(targetContainer)
            make.width.equalTo(crosshairHeight)
        }
        
        let rightRightUpper: UIView = UIView()
        rightRightUpper.backgroundColor = crosshairColor
        view.addSubview(rightRightUpper)
        rightRightUpper.snp.makeConstraints { (make) in
            make.width.equalTo(crosshairWidth)
            make.top.right.equalTo(targetContainer)
            make.height.equalTo(crosshairHeight)
        }
        
        let rightRightLower: UIView = UIView()
        rightRightLower.backgroundColor = crosshairColor
        view.addSubview(rightRightLower)
        rightRightLower.snp.makeConstraints { (make) in
            make.width.equalTo(crosshairWidth)
            make.bottom.right.equalTo(targetContainer)
            make.height.equalTo(crosshairHeight)
        }
        
        let lowerRight: UIView = UIView()
        lowerRight.backgroundColor = crosshairColor
        view.addSubview(lowerRight)
        lowerRight.snp.makeConstraints { (make) in
            make.width.equalTo(crosshairHeight)
            make.bottom.right.equalTo(targetContainer)
            make.height.equalTo(crosshairWidth)
        }
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

