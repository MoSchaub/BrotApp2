//
//  RecipeTableViewCell.swift
//  Back App iOS
//
//  Created by Moritz Schaub on 28.06.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI
import LBTATools

extension Color {
    
    static func cellBackgroundColor() -> Color {
        Color("blue")
    }
}

class RecipeTableViewCell: UITableViewCell {
    
    class RecipeCellData: ObservableObject {
        var name: String
        var minuteLabel: String
        var imageData: Data?
        
        init(name: String, minuteLabel: String, imageData: Data? = nil) {
            self.name = name
            self.minuteLabel = minuteLabel
            self.imageData = imageData
        }
    }
    
    struct RecipeRowView: View {
        @ObservedObject var data: RecipeCellData
        
        var image: some View {
            Group {
                if data.imageData != nil {
                    Image(uiImage: UIImage(data: data.imageData!)!)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(cornerRadius)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .imageScale(.large)
                        .scaledToFit()
                }
            }
        }
        
        var body: some View {
            HStack {
                image
                    .frame(maxHeight: height)
                VStack(alignment: .leading) {
                    Text(data.name)
                        .font(.headline)
                    Text(data.minuteLabel).secondary()
                }
                Spacer()
            }
            .padding()
            
            .background(Color.cellBackgroundColor())
        }
        //constants
        let height: CGFloat = 50
        let cornerRadius: CGFloat = 10
        
    }
    
    func setUp(cellData: RecipeCellData) {
        let hostingController = UIHostingController(rootView: RecipeRowView(data: cellData))
        addSubview(hostingController.view)
        hostingController.view.fillSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let indicatorButton = self.allSubviews.compactMap({ $0 as? UIButton }).last {
            let image = indicatorButton.backgroundImage(for: .normal)?.withRenderingMode(.alwaysTemplate)
            indicatorButton.setBackgroundImage(image, for: .normal)
            indicatorButton.tintColor = .label
        }
    }

}


struct RecipeTableViewCell_Previews: PreviewProvider {
    static var previews: some View {
        RecipeTableViewCell.RecipeRowView(data: .init(name: "Name", minuteLabel: "10 Minuten"))
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .environment(\.colorScheme, .dark)
            
    }
}
