//
//  AppDelegate.swift
//  Mission Dharma
/*
The MIT License (MIT)

Copyright (c) 2014 David Brunow

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
import CoreData
import UIKit

@UIApplicationMain
@objc (AppDelegate) class AppDelegate: UIResponder, UIApplicationDelegate
{
    struct Constants
    {
        static let ModelPath = "DHBPodcastEpisodeModel"
        static let CoreDataUbiquitousContentNameKey = "MissionDharmaStore"
        static let EpisodesFetchedFromLocalDatabaseNotification = "Episodes Fetched From Local Database"
    }
    
    static let barTintColor = UIColor(red: CGFloat(0) / 255, green: CGFloat(152) / 255, blue: CGFloat(172) / 255, alpha: CGFloat(1))
    static let lightColor = UIColor(red: CGFloat(0) / 255, green: CGFloat(179) / 255, blue: CGFloat(163) / 255, alpha: CGFloat(1))
    static let darkColor = UIColor(red: CGFloat(125) / 255, green: CGFloat(62) / 255, blue: CGFloat(0) / 255, alpha: CGFloat(1))
    
    var applicationHome = ""
    var isConnectedViaWifi = false
    var isICloudEnabled = false
    var podcast: DHBPodcast!
    var newPodcast = Podcast()
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        let fileManager = FileManager()
        
        if let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        {
            applicationHome = dir.path
        }
        
        DispatchQueue.main.async
        {
            self.podcast = DHBPodcast()
//            self.podcast.loadEpisodes()
            self.newPodcast.loadEpisodes()
                
            self.startNetworkAvailabilityTest()
        }
        
        return true
    }
    
    func startNetworkAvailabilityTest()
    {
        // Allocate a NetworkAvailability object
        let reach = NetworkAvailability(hostName: ApiClient.Constants.APIEndpointURLString)
        
        // Here we set up a NSNotification observer. The NetworkAvailability that caused the notification
        // is passed in the object parameter
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppDelegate.networkAvailabilityChanged(_:)),
            name: NSNotification.Name.reachabilityChanged,
            object: nil)
        
        reach?.startNotifier();
    }
    
    func networkAvailabilityChanged(_ notice: Notification)
    {
        let reach = notice.object as? NetworkAvailability
        if let _ = reach?.currentReachabilityStatus()
        {
//            if remoteHostStatus == NetworkStatus.notReachable
//            {
//                //showNetworkUnavailableView()
//            }
//            else
//            {
//                //hideNetworkUnavailableView()
//            }
        }
    }
    
    func iCloudKeyValueStoreDidChange(_ notification: Notification)
    {
        let defaultKeyValueStore = NSUbiquitousKeyValueStore.default()
        
        if let userInfo = (notification as NSNotification).userInfo
        {
            if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            {
                for key in changedKeys
                {
                    /*
                    switch key
                    {
                    case Constants.DefaultMailAppKey:
                        if let mailApp = defaultKeyValueStore.stringForKey(Constants.DefaultMailAppKey)
                        {
                            defaultMailApp = mailApp
                        }
                        break;
                    case Constants.IsIcloudEnabledKey:
                        isIcloudEnabled = defaultKeyValueStore.boolForKey(Constants.IsIcloudEnabledKey)
                        break;
                    case Constants.IsSundayFirstDayOfWeekKey:
                        isSundayFirstDayOfWeek = defaultKeyValueStore.boolForKey(Constants.IsSundayFirstDayOfWeekKey)
                        break;
                    default:
                        break;
                    }
                    */
                }
            }
        }
    }
    
    func initializeiCloudKeyValueStore()
    {
        let defaultKeyValueStore = NSUbiquitousKeyValueStore.default()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.iCloudKeyValueStoreDidChange(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: defaultKeyValueStore)
        
        defaultKeyValueStore.synchronize()
    }

    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    var metadataQuery = NSMetadataQuery()
    
    // MARK: - Notification Observers
    func registerForiCloudNotifications()
    {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(AppDelegate.storesWillChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: self.persistentStoreCoordinator)
        
        notificationCenter.addObserver(self, selector: #selector(AppDelegate.storesDidChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: self.persistentStoreCoordinator)
        
        //notificationCenter.addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChanges:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.persistentStoreCoordinator)
        
        metadataQuery.predicate = NSPredicate(format: "(%K = 1)", NSMetadataItemIsUbiquitousKey)
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryUbiquitousDataScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
        
        notificationCenter.addObserver(self, selector: #selector(AppDelegate.metadataQueryDidUpdate(_:)), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: metadataQuery)
        notificationCenter.addObserver(self, selector: #selector(AppDelegate.metadataQueryDidFinishGathering(_:)), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metadataQuery)
        
        if metadataQuery.start()
        {
            //print("Query started!")
        }
        else
        {
            //print("Failed to start query!")
        }
    }
    
    func metadataQueryDidFinishGathering(_ notification: Notification)
    {
        showMetadataQueryResults()
    }
    
    func metadataQueryDidUpdate(_ notification: Notification)
    {
        showMetadataQueryResults()
    }
    
    func showMetadataQueryResults()
    {
        if let results = metadataQuery.results as? [NSMetadataItem]
        {
            for item in results
            {
                /*
                var filename = ""
                
                if let fn = item.valueForAttribute(NSMetadataItemDisplayNameKey) as? String
                {
                filename = fn
                }
                */
                
                /*
                var filesize: NSNumber? = NSNumber()
                
                if let fs = item.valueForAttribute(NSMetadataItemFSSizeKey) as? NSNumber
                {
                filesize = fs
                }
                
                var updated = NSDate()
                
                if let up = item.valueForAttribute(NSMetadataItemFSContentChangeDateKey) as? NSDate
                {
                updated = up
                }
                
                if filesize != nil
                {
                }
                else
                {
                }
                */
                
                if let filepath = item.value(forAttribute: NSMetadataItemURLKey) as? URL
                    
                {
                    let pathExtension = filepath.pathExtension
                    
                    if pathExtension == "jpg" && !FileManager.default.fileExists(atPath: filepath.path)
                    {
                        DispatchQueue.global(qos: .default).async
                        {
                            do
                            {
                                try FileManager.default.startDownloadingUbiquitousItem(at: filepath)
                            }
                            catch
                            {
                                
                            }
                        }
                    }
                }
            }
            
            if results.count == 0
            {
                print("well, there just ain't no results ya see")
            }
        }
        else
        {
            print("results weren't what we thought they were :( : \(metadataQuery.results)")
        }
    }
    
    func storesWillChange(_ notification: Notification)
    {
        print("in storesWillChange")
        var error: NSError?
        
        if let context = managedObjectContext
        {
            if context.hasChanges
            {
                var success: Bool
                
                do
                {
                    try context.save()
                    success = true
                }
                catch let error1 as NSError
                {
                    error = error1
                    success = false
                }
                
                if !success && error != nil
                {
                    print("We had an error in storesWillChange: \(error?.localizedDescription)")
                }
                
                // this causes a crash when returning from the background in certain circumstances. Commenting out on 8/13/2015 hoping no other problems pop up
                //context.reset()
                
                //self.fetchClasses()
                //self.fetchStudents()
            }
        }
    }
    
    func storesDidChange(_ notification: Notification)
    {
        //fetchClasses()
        //fetchStudents()
    }
    
    func persistentStoreDidImportUbiquitousContentChanges(_ changeNotification: Notification)
    {
        print("in persistentStoreDidImportUbiquitousContentChanges")
        self.managedObjectContext?.mergeChanges(fromContextDidSave: changeNotification)
        
        //self.fetchClasses()
        //self.fetchStudents()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL =
    {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "co.ShepherdDog.Instructor" in the application's documents Application Support directory.
        
        #if os(iOS)
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        #endif
        
        #if os(tvOS)
            let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        #endif
        
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: Constants.ModelPath, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = try! self.applicationDocumentsDirectory.appendingPathComponent("Mission_Dharma.sqlite")
        
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        
        var persistentStoreOptions: [NSObject: AnyObject] = [NSMigratePersistentStoresAutomaticallyOption as NSObject: true as AnyObject, NSInferMappingModelAutomaticallyOption as NSObject: true as AnyObject]
        
        if self.isICloudEnabled
        {
            //persistentStoreOptions.updateValue(Constants.CoreDataUbiquitousContentNameKey, forKey: NSPersistentStoreUbiquitousContentNameKey)
        }
        
        do
        {
            try coordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: persistentStoreOptions)
        }
        catch var error1 as NSError
        {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error?.userInfo)")
            abort()
        }
        catch
        {
            fatalError()
        }
        
        return coordinator
    }()
    
    @objc lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext ()
    {
        if let moc = self.managedObjectContext
        {
            var error: NSError? = nil
            if moc.hasChanges
            {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error?.userInfo)")
                    abort()
                }
            }
        }
    }
}

extension UIViewController
{
    var contentViewController: UIViewController
    {
        if let navcon = self as? UINavigationController
        {
            return navcon.visibleViewController!
        }
        else
        {
            return self
        }
    }
}

