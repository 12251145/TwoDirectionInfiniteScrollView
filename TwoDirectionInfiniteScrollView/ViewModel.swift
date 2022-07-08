//
//  ViewModel.swift
//  TwoDirectionInfiniteScrollView
//
//  Created by Hoen on 2022/07/07.
//

import UIKit
import Combine

final class ViewModel {
    var loadedMonths: [Int] = [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]
    var isLeftLoading = false
    var isRightLoading = false
    var loadSize = 5
    
    struct Input {        
        var leftLoadEvent: AnyPublisher<Double, Never>
        var rightLoadEvent: AnyPublisher<Double, Never>
    }
    
    struct Output {
        var dataUpdated = PassthroughSubject<Bool, Never>()
    }
    
    func transform(input: Input, subscriptions: inout Set<AnyCancellable>) -> Output {
        let output = Output()
        
        input.leftLoadEvent
            .scan(0.0, { old, new in
                if abs((old ?? 0) - new) > 0.05 {
                    return new
                } else {
                    self.isLeftLoading = false
                    return nil
                }
            })
            .compactMap{ $0 }
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { _ in
                let left = self.loadedMonths.first!
                for i in 1...self.loadSize {
                    self.loadedMonths.insert(left - i, at: 0)
                }                
                
                output.dataUpdated.send(true)
            })
            .store(in: &subscriptions)
        
        input.rightLoadEvent
            .scan(0.0) { old, new in
                if abs((old ?? 0) - new) > 0.05 {
                    return new
                } else {
                    self.isRightLoading = false
                    return nil
                }
            }
            .compactMap { $0 }
            .sink { _ in
                let right = self.loadedMonths.last!
                for i in 1...self.loadSize {
                    self.loadedMonths.append(right + i)
                }
                
                output.dataUpdated.send(true)
            }
            .store(in: &subscriptions)
        
        return output
    }
}
