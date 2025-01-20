//
//  AdjustableRectangle.swift
//  Annotate
//
//  Created by Andreas Loizides on 19.01.2025.
//

import SwiftUI

let threshold = 30.0
func formattedFloat(f: Double)->String{
    return String(format: "%.0f", f)
}
extension CGPoint {
    var desc: String {
        return "(\(formattedFloat(f: x)),\(formattedFloat(f: y))"
    }
}
struct RectPoints: Codable, Equatable{
    static let defHeight = 20.0
    static let defWidth = 210.0
    static let defX: CGFloat = 95
    static let defY: CGFloat = 100
    
    var topLeft = CGPoint(x: defX, y: defY)
    var topRight = CGPoint(x: defX+defWidth, y: defY)
    var bottomLeft = CGPoint(x: defX, y: defY+defHeight)
    var bottomRight = CGPoint(x: defX+defWidth, y: defY+defHeight)
    
    init(){
    }
    
//    init(yOffset: CGFloat){
//        self.init()
//        
//    }
    init(prev: RectPoints){
        topLeft.y = prev.bottomLeft.y + 5
        topRight.y = prev.bottomRight.y + 5
        bottomLeft.y = topLeft.y + RectPoints.defHeight
        bottomRight.y = topRight.y + RectPoints.defHeight
    }
    var description: String {
        return "\(topLeft.desc),\(topRight.desc),\(bottomLeft.desc),\(bottomRight.desc)"
    }
    
}

struct Annotation: Codable, Equatable{
    var points: RectPoints
    var label: String
}

let categories = ["Actor", "Address", "Table", "Info", "Date", "Ind.Field"]
let colorByCategory = [
    "Actor": Color.black,
    "Address": Color.green,
    "Table": Color.red,
    "Info": Color.orange,
    "Date": Color.purple,
    "Ind.Field": Color.yellow
]
struct AdjustableRectangle: View {
    @Binding var a: Annotation
    @State private var showPicker = false
    @State private var showingCircles = true
    var hasChanged: () -> Void = {}

    var body: some View {
        ZStack {
            if showPicker {
                Picker("p", selection: $a.label) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                            .tag(category)
                    }
                }
                .onChange(of: a.label) { oldV, newValue in
                    print("\(oldV) -> \(newValue)")
                    hasChanged()
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 110, height: 40, alignment: .center)
                .background(colorByCategory[a.label])
                .clipShape(Rectangle())
                .position(x: (a.points.topLeft.x + a.points.topRight.x) / 2, y: (a.points.topLeft.y + a.points.bottomLeft.y) / 2)
                .onTapGesture(count: 2){
                    withAnimation{
                        showPicker.toggle()
                    }
                }
                
            }else{
                Text(a.label)
                    .font(.caption)
//                Text(a.points.description)
                    .foregroundStyle(Color.blue)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 50, height: 20, alignment: .center)
                    .background(colorByCategory[a.label])
                    .clipShape(Rectangle())
//                    .position(x: (a.points.topLeft.x + a.points.topRight.x) / 2, y: (a.points.topLeft.y + a.points.bottomLeft.y) / 2)
                    .position(x: (a.points.topRight.x-25), y: (a.points.topLeft.y - 10))
                    .onTapGesture(count: 2){
                        withAnimation{
                            showPicker.toggle()
                        }
                    }
            }
            
            Path{ path in
                path.addLines([
                    a.points.topLeft, a.points.topRight, a.points.bottomRight, a.points.bottomLeft, a.points.topLeft
                ])
            }
            .stroke(colorByCategory[a.label]!, lineWidth: 2)
            let height = abs(a.points.bottomLeft.y - a.points.topLeft.y)
            let width = abs(a.points.bottomLeft.x - a.points.bottomRight.x)
            
            cornerHandle2(onlyVertical: true, atBot: $a.points.bottomLeft, atTop: $a.points.bottomRight, xOffset: width/8)
            cornerHandle2(onlyVertical: true, atBot: $a.points.topLeft, atTop: $a.points.topRight, xOffset: -width/8)
            
            cornerHandle2(onlyVertical: false, atBot: $a.points.bottomLeft, atTop: $a.points.topLeft)
            cornerHandle2(onlyVertical: false, atBot: $a.points.bottomRight, atTop: $a.points.topRight)
            
            
//            Text("\(abs(a.points.bottomLeft.x - a.points.bottomRight.x))")
        }
    }

    private func cornerHandle(at binding: Binding<CGPoint>) -> some View {
        Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(.blue)
            .position(x: binding.wrappedValue.x, y: binding.wrappedValue.y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        print("changed to \(value.location)")
                        withAnimation{
                            binding.wrappedValue = value.location
                        }
                    }
            )
    }
    private func cornerHandle2(onlyVertical: Bool, atBot bindingBot: Binding<CGPoint>, atTop bindingTop: Binding<CGPoint>, xOffset: CGFloat = 0) -> some View {
        var x = onlyVertical ? abs(bindingBot.wrappedValue.x + bindingTop.wrappedValue.x)/2 : bindingBot.wrappedValue.x
        x += xOffset
        let y = onlyVertical ? bindingBot.wrappedValue.y : abs(bindingBot.wrappedValue.y + bindingTop.wrappedValue.y)/2
        
        return Circle()
            .frame(width: 20, height: 20)
            .foregroundColor(colorByCategory[a.label]!)
            .overlay(
                    Circle().stroke(colorByCategory[a.label]!.opacity(0.5), lineWidth: 9)
                )
            .position(x: x, y: y)
            .gesture(
                DragGesture()
                    .onEnded{_ in
                        withAnimation{
                            showingCircles = true
                        }
                    }
                    .onChanged { value in
                        hasChanged()
                        withAnimation{
                            showingCircles = false
                        }
                        print("changed to \(onlyVertical ? value.location.y : value.location.x)")
                        if onlyVertical{
                            bindingBot.wrappedValue.y = value.location.y
                            bindingTop.wrappedValue.y = value.location.y
                        }else{
                            bindingBot.wrappedValue.x = value.location.x
                            bindingTop.wrappedValue.x = value.location.x
                        }
//                        binding.wrappedValue = value.location
                    }
            )
            .opacity(showingCircles ? 1 : 0.1)
            
    }
}

struct ParentView: View {
//    @State var a: Annotation = Annotation(points: RectPoints(), label: categories.randomElement()!)
    @State var a: Annotation = Annotation(points: RectPoints(), label: "Ind.Field")
    var body: some View {
        AdjustableRectangle(a: $a)
    }
}

struct AdjustableRectangle_Previews: PreviewProvider {
    static var previews: some View {
        ParentView()
    }
}
