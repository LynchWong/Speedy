//
//  ViewController.swift
//  SpeedyDemo
//
//  Created by Lynch Wong on 3/14/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit
import Speedy
import MobileCoreServices

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        Speedy.request(Method.GET, "http://192.168.189.25:8080/get").responseString {
//            if $0.result.isFailure {
//                let error = $0.result.error!
//                print(error.localizedDescription)
//                return
//            } else {
//                let value = $0.result.value!
//                print(value)
//            }
//        }.responseJSON {
//            if $0.result.isFailure {
//                let error = $0.result.error!
//                print(error.localizedDescription)
//                return
//            } else {
//                if let value = $0.result.value as? NSDictionary {
//                    print(value["message"])
//                }
//            }
//        }.responseData {
//            if $0.result.isFailure {
//                let error = $0.result.error!
//                print(error.localizedDescription)
//                return
//            } else {
//                let value = $0.result.value!
//                print(value)
//            }
//        }.progress {
//            print($0)
//            print($1)
//            print($2)
//        }
        
//        var cacheURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.CachesDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask)[0]
//        cacheURL = cacheURL.URLByAppendingPathComponent("test.zip")
//        print(cacheURL)
//        
//        let progress = NSProgress(totalUnitCount: 0)
//        Speedy.download(Method.GET, "http://192.168.189.25:8080/upload/test.zip", destination: cacheURL).progress {
//            print($0)
//            print($1)
//            print($2)
//            print(Double($1)/Double($2))
//            progress.totalUnitCount = $2
//            progress.completedUnitCount = $1
//            print(progress)
//        }
        
//        let fileURL = NSBundle.mainBundle().URLForResource("back", withExtension: "png")
//        let request = NSMutableURLRequest(URL: NSURL(string: "http://192.168.189.25:8080/upload")!)
//        request.HTTPMethod = Method.POST.rawValue
//        Speedy.upload(request, file: fileURL!).progress {
//            print($0)
//            print($1)
//            print($2)
//        }
        
//        let file = NSBundle.mainBundle().URLForResource("back", withExtension: "png")
//        let multiData = MultipartFormData()
//        print(multiData.contentType)
//        print(multiData.contentLength)
//        multiData.addBodyPart(file!, name: "back", parameters: ["tid": 135887])
//        print(multiData.contentLength)
//        let data = multiData.encode()
//        print(data)
//        print(String(data: data, encoding: NSUTF8StringEncoding))
//        
//        print(String(data: multiData.encodeHeaders(["tid": "135887"]), encoding: NSUTF8StringEncoding))
        
//        if let
//            id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue(),
//            contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
//        {
//             contentType as String
//        }
        
        //日志文件上传
//        let time = NSNumber(double: 1458176707.405045)
//        let sid = NSNumber(integer: 135887)
//        let parameter = ["sid": sid, "time": time]
//        let file = NSBundle.mainBundle().URLForResource("fresh", withExtension: "zip")!
//        
//        Speedy.upload(
//            Method.POST,
//            "http://192.168.129.120/V1/Public/appLogUpload",
//            parameters: parameter,
//            headers: nil,
//            encodingMemoryThreshold: Manager.MultipartFormDataEncodingMemoryThreshold) {
//                $0.addBodyPart(file, name: "appLog")
//        }
        
        Speedy.upload(Method.POST, "http://192.168.189.25:8080/upload") {
            $0.addBodyPart(NSBundle.mainBundle().URLForResource("fresh", withExtension: "zip")!, name: "file")
            $0.addBodyPart(NSBundle.mainBundle().URLForResource("fresh1", withExtension: "zip")!, name: "file1")
        }
        
//        Speedy.upload(Method.POST, "http://192.168.189.25:8080/upload") {
//            $0.addBodyPart(NSBundle.mainBundle().URLForResource("ui", withExtension: "zip")!, name: "file")
//        }
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

