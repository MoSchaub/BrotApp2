//
//  ScheduleForm.swift
//  BrotApp2
//
//  Created by Moritz Schaub on 16.04.20.
//  Copyright © 2020 Moritz Schaub. All rights reserved.
//

import SwiftUI

struct ScheduleForm: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var recipe: Recipe
    
    let roomTemp: Int
    
    @State private var times: Decimal? = 1
    @State private var showingSchedule = false
    @State private var showingAlert = false
    
    var numberFormatter: NumberFormatter{
        let nF = NumberFormatter()
        nF.numberStyle = .decimal
        return nF
    }
    
    var timesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("amount").secondary()
                .padding(.leading, 35)
            DecimalField("amountCellPlaceholder2", value: self.$times, formatter: self.numberFormatter)
                .padding([.leading, .vertical])
                .background(BackgroundGradient())
                .padding([.horizontal,.bottom])
        }
    }
    
    var alert: Alert{
        Alert(title: Text("Error"), message: Text("scheduleFormErrorMessage"), dismissButton: .default(Text("Ok")))
    }
    
    var okButton: some View {
        Button(action: {
            if self.times != nil{
                self.showingSchedule = true
            } else{
                self.showingAlert = true
            }
        }){
            Text("OK")
        }
        .alert(isPresented: self.$showingAlert) {
            self.alert
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(Color("Color1"),Color("Color2")).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(){
                    timesSection
                    VStack {
                        MODatePicker(date: self.$recipe.date)
                            .frame(width: UIScreen.main.bounds.width - 60)
                            .clipped()
                        Picker("s", selection: self.$recipe.inverted){
                            Text("start").tag(false)
                            Text("end").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: UIScreen.main.bounds.width - 30)
                        .padding(.bottom)
                        .clipped()
                    }.background(BackgroundGradient())
                    Text(recipe.formattedDate).font(.title).padding()
                    NavigationLink(destination: ScheduleView(recipe: recipe, roomTemp: self.roomTemp, times: self.times), isActive: self.$showingSchedule) {
                       EmptyView()
                    }
                }
            }
        }
            .onAppear{
                self.times = self.recipe.times
            }
        .navigationBarTitle(
            Text(recipe.formattedName),
            displayMode: NavigationBarItem.TitleDisplayMode.inline
        )
        .navigationBarItems(trailing: okButton)
    }
}

struct ScheduleForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleForm(recipe: .constant(Recipe.example), roomTemp: 20)
        }
    }
}
