//
//  RxTableViewSectionedAnimatedDataSource.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 6/27/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import UIKit
#if !RX_NO_MODULE
import RxSwift
import RxCocoa
#endif

public class RxTableViewSectionedAnimatedDataSource<S: AnimatableSectionModelType>
    : RxTableViewSectionedDataSource<S>
    , RxTableViewDataSourceType {
    
    public typealias Element = [S]
    public var animationConfiguration = AnimationConfiguration()

    public var updated: Observable<Void> { return updateSubject.asObservable() }
    private let updateSubject: PublishSubject<Void> = PublishSubject<Void>()

    var dataSet = false

    public override init() {
        super.init()
    }

    public func tableView(tableView: UITableView, observedEvent: Event<Element>) {
        UIBindingObserver(UIElement: self) { dataSource, newSections in
            #if DEBUG
                self._dataSourceBound = true
            #endif
            if !self.dataSet {
                self.dataSet = true
                dataSource.setSections(newSections)
                tableView.reloadData()
                print("[RxDataSources: case 1")
            }
            else {
                dispatch_async(dispatch_get_main_queue()) {
                    let oldSections = dataSource.sectionModels
                    do {
                        let differences = try differencesForSectionedView(oldSections, finalSections: newSections)

                        for difference in differences {
                            dataSource.setSections(difference.finalSections)

                            tableView.performBatchUpdates(difference, animationConfiguration: self.animationConfiguration)
                        }
                        print("[RxDataSources: case 2")
                        self.updateSubject.onNext()
                    }
                    catch let e {
                        rxDebugFatalError(e)
                        self.setSections(newSections)
                        print("[RxDataSources: case 3")
                        tableView.reloadData()
                    }
                }
            }
        }.on(observedEvent)
    }
}