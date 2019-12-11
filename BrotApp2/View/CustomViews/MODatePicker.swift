//
//  MODatePicker.swift
//  BrotApp2
//
//  Created by Moritz Schaub on 11.12.19.
//  Copyright © 2019 Moritz Schaub. All rights reserved.
//

import SwiftUI

struct MODatePicker: UIViewRepresentable {
    
    @Binding var date:Date
    
    func makeCoordinator() -> MODatePicker.Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: UIViewRepresentableContext<MODatePicker>) -> UIDatePicker {
        let datepicker = UIDatePicker()
        datepicker.datePickerMode = .dateAndTime
        datepicker.date = self.date
        datepicker.addTarget(context.coordinator, action: #selector(Coordinator.updateDate(sender:)), for: .valueChanged)
        return datepicker
    }
    
    func updateUIView(_ uiView: UIDatePicker, context: UIViewRepresentableContext<MODatePicker>) {
        uiView.date = self.date
    }
    
    
    class Coordinator: NSObject {
        var datepicker: MODatePicker

        init(_ datepicker: MODatePicker) {
            self.datepicker = datepicker
        }

        @objc func updateDate(sender: UIDatePicker) {
            datepicker.date = sender.date
        }
    }
    
}
