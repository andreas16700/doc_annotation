//
//  testview.swift
//  Annotate
//
//  Created by Andreas Loizides on 20.01.2025.
//

import SwiftUI
struct Some{
    var n: Nums = Nums()
}
struct Nums{
    var n1: Int = 1
    var n2: Int = 2
    var n3: Int = 3
    
    var description: String{
        "\(n1),\(n2),\(n3)"
    }
}
struct parentView: View {
    @State var some: Some = Some()
    var body: some View {
        VStack{
            Text(some.n.description)
            testview(s: $some)
        }
    }
}
struct testview: View {
    @Binding var s: Some
//    @State private var selection: Int = 1
    let title = "Select Room Type"
    
    var body: some View {
        Picker(title, selection: self.$s.n.n1) {
            HStack {
                Image(systemName: "person.fill")
                Text("Single Room")
            }.tag(1)
            
            HStack {
                Image(systemName: "person.2.fill")
                Text("Double Room")
            }.tag(2)
            
            HStack {
                Image(systemName: "person.3.fill")
                Text("Triple Room")
            }.tag(3)
        }.frame(width: 500)
    }}

#Preview {
    parentView()
}
