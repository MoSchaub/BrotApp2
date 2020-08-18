//
//  ImageTableViewCell.swift
//  Back App iOS
//
//  Created by Moritz Schaub on 29.06.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI

class ImageTableViewCell: UITableViewCell {
    
    struct ImageView: View {
        
        var data: Data?
        
        var body: some View {
                Group {
                    if data != nil {
                        Image(uiImage: UIImage(data: data!)!)
                            .resizable()
                            .scaledToFill()
                            .cornerRadius(cornerRadius)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .imageScale(.large)
                            .scaledToFit()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
            .background(Color.cellBackgroundColor())
        }
        
        let cornerRadius: CGFloat = 10
        let maxHeight: CGFloat = 250
    }
    
    func setup(imageData: Data?) {
        let hostingController = UIHostingController(rootView: ImageView(data: imageData))
        addSubview(hostingController.view)
        
        hostingController.view.fillSuperview()
        selectionStyle = .none
    }
    
}

struct ImageTableViewCell_Previews: PreviewProvider {
    static var previews: some View {
        ImageTableViewCell.ImageView()
    }
}