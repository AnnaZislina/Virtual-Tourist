//
//  UpdateOnMainThread.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 06/11/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import Foundation

func updateOnMainThread(_ updates: @escaping () -> Void) {
    
    DispatchQueue.main.async {
        updates()
    }
}
