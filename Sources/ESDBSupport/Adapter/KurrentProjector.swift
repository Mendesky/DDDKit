//
//  KurrentProjector2.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2026/2/6.
//
import KurrentDB
import EventSourcing

struct KurrentProjector<PresenterType: EventSourcingPresenter> {
    typealias PresenterType = PresenterType
    typealias StorageCoordinator = EventStorageCoordinator
    
    let coordinator: ESDBStorageCoordinator
    
    init(client: KurrentDBClient, category: String, eventMapper: any EventTypeMapper, coordinator: ESDBStorageCoordinator, id: String){
        self.coordinator = coordinator
        self.coordinator.fetchEvents(byId: id)
    }
}
