//
//  CoreDataManager.swift
//  AppleWatchDemo
//
//  Created by Rohit Pathak on 10/06/19.
//  Copyright © 2019 Rohit Pathak. All rights reserved.
//

import Foundation
import CoreData

// MARK: - PersistentStoreType

/// An enumeration of the three string constants that are used for specifying the persistent store type (NSSQLiteStoreType, NSBinaryStoreType, NSInMemoryStoreType).
public enum PersistentStoreType {
    
    /// Represents the value for NSSQLiteStoreType.
    case sqLite
    
    /// Represents the value for NSBinaryStoreType.
    case binary
    
    /// Represents the value for NSInMemoryStoreType.
    case inMemory
    
    /// Value of the Core Data string constants corresponding to each case.
    var stringValue: String {
        switch self {
        case .sqLite:
            return NSSQLiteStoreType
        case .binary:
            return NSBinaryStoreType
        case .inMemory:
            return NSInMemoryStoreType
        }
    }
}
// MARK: - CoreDataManager

/**
 Responsible for setting up the Core Data stack. Also provides some convenience methods for fetching, deleting, and saving.
 */
class CoreDataManager:NSObject {
    
    static fileprivate let mustCallSetupMethodErrorMessage = "CoreDataManager must be set up using setUp(withDataModelName:bundle:persistentStoreType:) before it can be used."

    static let shared = CoreDataManager()
    
    override init(){
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(contextDidSavePrivateQueueContext), name: .NSManagedObjectContextDidSave, object: privateContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(contextDidSaveMainQueueContext), name: .NSManagedObjectContextDidSave, object: privateContext)
    }
    
    // MARK: Properties
    
    static let dataModelName = "SkillSquad"
    
    /// The logger to use for logging errors caught internally. A default logger is used if a custom one isn't provided. Assigning nil to this property prevents CoreDataManager from emitting any logs to the console.
    //public static var errorLogger: CoreDataManagerErrorLogger? = DefaultLogger()
    
    /// The value to use for `fetchBatchSize` when fetching objects.
    public var defaultFetchBatchSize = 50
    
    
    // MARK: Core Data Stack
    @objc func contextDidSavePrivateQueueContext(notification:Notification){
    
        DispatchQueue.main.async {
            let mainContext  = self.mainContext
            mainContext.performAndWait {
                mainContext.mergeChanges(fromContextDidSave: notification)
                do{
                    try mainContext.save()
                }catch let error {
                    // log error
                    self.log(error: error)
                }
            }
        }
    }
    
    @objc func contextDidSaveMainQueueContext(notification:Notification){
        let writerContext = self.writerContext
        
        writerContext.perform {
            writerContext.mergeChanges(fromContextDidSave: notification)
            
            do{
                try writerContext.save()
            }catch let error {
                // log error
                self.log(error: error)
            }
        }
    }
    
    var applicationDocumentsDirectory: URL = {
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }()
    
    var managedObjectModel: NSManagedObjectModel = {
        
        guard let modelURL = Bundle.main.url(forResource: dataModelName, withExtension: "momd") else {
            fatalError("Failed to locate data model schema file.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to created managed object model")
        }
        
        return managedObjectModel
    }()
    
    var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel:CoreDataManager.shared.managedObjectModel)

        let url = CoreDataManager.shared.applicationDocumentsDirectory.appendingPathComponent("\(dataModelName).sqlite")

        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]

        do {
            try coordinator.addPersistentStore(ofType:NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        }
        catch let error as NSError {
            fatalError("Failed to initialize the application's persistent data: \(error.localizedDescription)")
        }
        catch {
            fatalError("Failed to initialize the application's persistent data")
        }
        
        return coordinator
    }()
    
    fileprivate var writerContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = CoreDataManager.shared.persistentStoreCoordinator
        return context
    }()
    
    public var privateContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = CoreDataManager.shared.mainContext
        return context
    }()
    
    /// A MainQueueConcurrencyType context whose parent is a PrivateQueueConcurrencyType Writer Context. The PrivateQueueConcurrencyType Writer context is the root context.
    public var mainContext: NSManagedObjectContext = {
        
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = CoreDataManager.shared.writerContext
        return context
    }()
    
    
    // MARK: Fetching
    
    /**
     This is a convenience method for performing a fetch request. Note: Errors thrown by executeFetchRequest are suppressed and logged in order to make usage less verbose. If detecting thrown errors is needed in your use case, you will need to use Core Data directly.
     
     - parameter entity:          The NSManagedObject subclass to be fetched.
     - parameter predicate:       A predicate to use for the fetch if needed (defaults to nil).
     - parameter sortDescriptors: Sort descriptors to use for the fetch if needed (defaults to nil).
     - parameter context:         The NSManagedObjectContext to perform the fetch with.
     
     - returns: A typed array containing the results. If executeFetchRequest throws an error, an empty array is returned.
     */
    public  func fetchObjects<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> [T] {
        
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchBatchSize = defaultFetchBatchSize
        
        do {
            return try context.fetch(request)
        }
        catch let error as NSError {
            log(error: error)
            return [T]()
        }
    }
    
    /**
     This is a convenience method for performing a fetch request that fetches a single object. Note: Errors thrown by executeFetchRequest are suppressed and logged in order to make usage less verbose. If detecting thrown errors is needed in your use case, you will need to use Core Data directly.
     
     - parameter entity:          The NSManagedObject subclass to be fetched.
     - parameter predicate:       A predicate to use for the fetch if needed (defaults to nil).
     - parameter sortDescriptors: Sort descriptors to use for the fetch if needed (defaults to nil).
     - parameter context:         The NSManagedObjectContext to perform the fetch with.
     
     - returns: A typed result if found. If executeFetchRequest throws an error, nil is returned.
     */
    public  func fetchObject<T: NSManagedObject>(entity: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, context: NSManagedObjectContext) -> T? {
        
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        }
        catch let error as NSError {
            log(error: error)
            return nil
        }
    }
    
    // MARK: Deleting
    
    /**
     Iterates over the objects and deletes them using the supplied context.
     
     - parameter objects: The objects to delete.
     - parameter context: The context to perform the deletion with.
     */
    public  func delete(_ objects: [NSManagedObject]) {
        
        self.privateContext.perform {
            for object in objects {
                self.privateContext.delete(object)
            }
        }
    }
    
    /**
     For each entity in the model, fetches all objects into memory, iterates over each object and deletes them using the main context. Note: Errors thrown by executeFetchRequest are suppressed and logged in order to make usage less verbose. If detecting thrown errors is needed in your use case, you will need to use Core Data directly.
     */
    public  func deleteAllObjects() {
        
        self.privateContext.perform {
            
            for entityName in self.managedObjectModel.entitiesByName.keys {
                
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                request.includesPropertyValues = false
                
                do {
                    for object in try self.privateContext.fetch(request) {
                        self.privateContext.delete(object)
                    }
                }
                catch let error as NSError {
                    self.log(error: error)
                }
            }
        }
    }
    
    // MARK: Saving
    
    /**
     Saves changes to the persistent store.
     
     - parameter synchronously: Whether the main thread should block while writing to the persistent store or not.
     - parameter completion:    Called after the save on the private context completes. If there is an error, it is called immediately and the error parameter is populated.
     */
    public  func saveChanges(completion: ((Error?) -> Void)? = nil) {
        
        if self.privateContext.hasChanges {
            
            self.privateContext.perform {
                do {
                    try self.privateContext.save()
                    completion?(nil)
                }
                catch let error {
                    completion?(error)
                }
            }
        }else{
            //CoreDataManager.log no changes found in context
        }
    }
    
    // MARK: Logging
    
    private func log(error: Error, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        
        //errorLogger?.log(error: error, file: file, function: function, line: line)
    }
}
