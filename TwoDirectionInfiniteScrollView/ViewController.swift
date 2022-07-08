//
//  ViewController.swift
//  TwoDirectionInfiniteScrollView
//
//  Created by Hoen on 2022/07/07.
//

import Combine
import UIKit
import SwiftUI

final class ViewController: UIViewController {
    var viewModel = ViewModel()
    var subscriptions = Set<AnyCancellable>()
    let width = UIScreen.main.bounds.width
    let insertEventSubject = PassthroughSubject<Double, Never>()
    let addEventSubject = PassthroughSubject<Double, Never>()
    
    lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout())
        collection.register(CollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collection.delegate = self
        collection.dataSource = self
        collection.isPagingEnabled = true
        collection.decelerationRate = .fast
        collection.showsHorizontalScrollIndicator = false
        
        return collection
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.collectionView.setContentOffset(
            CGPoint(x: self.width * CGFloat(self.viewModel.loadSize), y: 0),
            animated: false
        )
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.loadedMonths.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        cell.contentConfiguration = UIHostingConfiguration {
            HStack{
                
                Text("\(self.viewModel.loadedMonths[indexPath.row])")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundColor(.pink)
                    .shadow(radius: 5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.black)
            )
        }
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView.contentOffset.x < self.width * CGFloat(self.viewModel.loadSize)  {
            
            if !self.viewModel.isLeftLoading {
                
                self.viewModel.isLeftLoading = true
                    
                scrollView.setContentOffset(
                    CGPoint(
                        x: scrollView.contentOffset.x + (self.width * CGFloat(self.viewModel.loadSize)),
                        y: 0),
                    animated: false
                )

                let date = Date()
                let timeInterval = date.timeIntervalSince1970
                                                
                self.insertEventSubject.send(timeInterval)
            }
        }
   
        if scrollView.contentOffset.x >
            (CGFloat(self.viewModel.loadedMonths.count) * width) -
            (self.width * CGFloat(self.viewModel.loadSize))  {
        
        
            if !self.viewModel.isRightLoading {
            
                self.viewModel.isRightLoading = true
                
                let date = Date()
                let timeInterval = date.timeIntervalSince1970
                                                
                self.addEventSubject.send(timeInterval)
            }
        }
    }
}

private extension ViewController {
    func configureUI() {
        view.addSubview(self.collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            self.collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            self.collectionView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    func bindViewModel() {
        let output = self.viewModel.transform(
            input: ViewModel.Input(                
                leftLoadEvent: self.insertEventSubject.eraseToAnyPublisher(),
                rightLoadEvent: self.addEventSubject.eraseToAnyPublisher()
            ),
            subscriptions: &subscriptions
        )
        
        output.dataUpdated
            .filter { $0 }
            .sink { _ in                
                self.collectionView.reloadData()
                self.viewModel.isLeftLoading = false
                self.viewModel.isRightLoading = false
                
            }
            .store(in: &subscriptions)
    }
    
    private func collectionViewLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        let cellWidthHeightConstant: CGFloat = UIScreen.main.bounds.width

        layout.sectionInset = UIEdgeInsets(top: 0,
                                           left: 0,
                                           bottom: 0,
                                           right: 0)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: cellWidthHeightConstant, height: 300)
        
        return layout
    }
}
