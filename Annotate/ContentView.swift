import SwiftUI

struct ContentView: View {
    @State private var points: [CGPoint] = []
    @State private var lineY: CGFloat = 0             // Initial vertical position of the line
    @GestureState private var isDragging: Bool = false  // Tracks whether the user is actively dragging
    
    let uiImage = UIImage(named: "sample")!
    
    func originalPoint(i: CGFloat, isX: Bool, geometry: GeometryProxy)->CGFloat{
        let originalWidth = uiImage.size.width
        let originalHeight = uiImage.size.height
        
        let scale = min(geometry.size.width / originalWidth,
                        geometry.size.height / originalHeight)
        
        // The displayed (scaled) size of the image in SwiftUI points:
        let displayedWidth = originalWidth * scale
        let displayedHeight = originalHeight * scale
        
        // Center the image in its container:
        let xOffset = (geometry.size.width - displayedWidth) / 2
        let yOffset = (geometry.size.height - displayedHeight) / 2
        
        return isX ? (i - xOffset) / scale : (i - yOffset) / scale
        
    }
    func toScaledPoint(i: CGFloat, isX: Bool, geometry: GeometryProxy)->CGFloat{
        let originalWidth = uiImage.size.width
        let originalHeight = uiImage.size.height
        
        let scale = min(geometry.size.width / originalWidth,
                        geometry.size.height / originalHeight)
        
        // The displayed (scaled) size of the image in SwiftUI points:
        let displayedWidth = originalWidth * scale
        let displayedHeight = originalHeight * scale
        
        // Center the image in its container:
        let xOffset = (geometry.size.width - displayedWidth) / 2
        let yOffset = (geometry.size.height - displayedHeight) / 2
        
//        return isX ? (i - xOffset) / scale : (i - yOffset) / scale
        
        return isX ? (scale*i + xOffset) : (scale*i + yOffset)
        
        
        
        /*
         x = (i-o)/s
         (i-o) = sx
         i = sx + o
         */
        
    }
    
    func originalPoint(p: CGPoint, geometry: GeometryProxy)->CGPoint{
        let originalWidth = uiImage.size.width
        let originalHeight = uiImage.size.height
        
        let scale = min(geometry.size.width / originalWidth,
                        geometry.size.height / originalHeight)
        
        // The displayed (scaled) size of the image in SwiftUI points:
        let displayedWidth = originalWidth * scale
        let displayedHeight = originalHeight * scale
        
        // Center the image in its container:
        let xOffset = (geometry.size.width - displayedWidth) / 2
        let yOffset = (geometry.size.height - displayedHeight) / 2
        
        let pixelX = (p.x - xOffset) / scale
        let pixelY = (p.y - yOffset) / scale
        
        return .init(x: pixelX, y: pixelY)
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let originalWidth = uiImage.size.width
                let originalHeight = uiImage.size.height
                
                let scale = min(geometry.size.width / originalWidth,
                                geometry.size.height / originalHeight)
                
                // The displayed (scaled) size of the image in SwiftUI points:
                let displayedWidth = originalWidth * scale
                let displayedHeight = originalHeight * scale
                
                // Center the image in its container:
                let xOffset = (geometry.size.width - displayedWidth) / 2
                let yOffset = (geometry.size.height - displayedHeight) / 2
                
                ZStack {
                    // The SwiftUI image, scaled to fit
//                    jul24/PNG-Bild-4A46-BE45-2D-0
                    Image("sample")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: displayedWidth, height: displayedHeight)
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)
                    
                    // Detect taps on the image
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let tapLocation = value.location
                                    print("tap location: (\(tapLocation.x), \(tapLocation.y))")
                                    
                                    
                                    // Check if the tap is within the displayed image bounds
                                    guard tapLocation.x >= xOffset,
                                          tapLocation.x <= xOffset + displayedWidth,
                                          tapLocation.y >= yOffset,
                                          tapLocation.y <= yOffset + displayedHeight
                                    else {
                                        // Tap was outside the image area; ignore
                                        return
                                    }
                                    
                                    // Convert from SwiftUI coordinates back to actual image pixel coordinates
                                    let pixelX = (tapLocation.x - xOffset) / scale
                                    let pixelY = (tapLocation.y - yOffset) / scale
                                    
                                    print("Tapped pixel coords: (\(pixelX), \(pixelY))")
                                    print("recovered x: \(toScaledPoint(i: pixelX, isX: true, geometry: geometry))")
                                    
                                    // Store this location in SwiftUI’s coordinate space
                                    points.append(tapLocation)
                                }
                        )
                    
                    // Draw a small red circle for each tapped point
                    ForEach(points, id: \.self) { point in
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .position(point)
                    }
                    
                    // A draggable horizontal "line" at y = lineY
                    Rectangle()
                        .fill(Color.red)
                        // Height is bigger by 50% while dragging
                        .frame(width: geometry.size.width,
                               height: isDragging ? 5 * 1.5 : 5)
                        // Position it horizontally centered, vertically at lineY
                        .position(x: geometry.size.width / 2, y: lineY)
                        // Add drag gesture
                        .gesture(
                            DragGesture()
                                // Let SwiftUI track "isDragging" automatically
                                .updating($isDragging) { _, isDragging, _ in
                                    withAnimation{
                                        isDragging = true
                                    }
                                }
                                // On each drag change, update the line’s Y-position
                                .onChanged { value in
                                    lineY = value.location.y
                                    print(lineY)
                                    print(uiImage.size.height)
                                    print("dragged to \(originalPoint(p: value.location, geometry: geometry))")
                                    print("dragged to \(toScaledPoint(i: lineY, isX: false, geometry: geometry))")
                                }
                        )
                }
                .onAppear{
//                    let i = uiImage.size.height - 930
                    let i = 930
                    self.lineY = toScaledPoint(i: CGFloat(i), isX: false, geometry: geometry)
                    print("set lineY to \(lineY)")
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
