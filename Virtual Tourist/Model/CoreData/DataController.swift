//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/8/22.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { store, err in
            guard err == nil else {
                fatalError(err!.localizedDescription)
            }
            completion?()
        }
    }
}
