//
//  AppDelegate.swift
//  SpeedyDemo
//
//  Created by Lynch Wong on 3/14/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import UIKit
import Speedy

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
//        Speedy.request(
//            Method.POST,
//            "http://192.168.129.120/V1/Students/login",
//            parameters: [
//                "androidVersion": 25,
//                "appVername": "2.3.3",
//                "networkStatus": 1,
//                "password": "200820e3227815ed1756a6b531e7e0d2",
//                "phoneModel": "Simulator",
//                "source": 3,
//                "username": "18580897856",
//            ],
//            encoding: ParameterEncoding.URL,
//            headers: nil
//        ).responseString {
//                if $0.result.isFailure {
//                    let error = $0.result.error!
//                    print(error.localizedDescription)
//                    return
//                } else {
//                    let value = $0.result.value!
//                    print(value)
//                }
//        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
