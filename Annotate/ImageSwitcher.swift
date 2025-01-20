//
//  ImageSwitcher.swift
//  Annotate
//
//  Created by Andreas Loizides on 20.01.2025.
//

import SwiftUI
import Foundation
import CoreTransferable

extension Annotation: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}

struct ImageManager {
    var images: [String] = []
    var currentIndex = 0
    
    init() {
        images = all_imgs
    }
    
    mutating func nextImage() -> String? {
        guard !images.isEmpty else { return nil }
        currentIndex = (currentIndex + 1) % images.count
        return images[currentIndex]
    }
    
    mutating func previousImage() -> String? {
        guard !images.isEmpty else { return nil }
        currentIndex = (currentIndex - 1 + images.count) % images.count
        return images[currentIndex]
    }
}

let encoder = JSONEncoder()
let decoder = JSONDecoder()
struct ImageSwitcher: View {
    @State private var imageManager = ImageManager()
    @State private var displayedImage: String?
    @State private var focusedAnnotation = -1
    @State private var isShowingAll = false
    @State private var annotations: [Annotation] = []
    @State var msg = ""
    @State var geo: GeometryProxy? = nil
    @State var uiImage: UIImage? = nil
    @State var keepForNext: Bool = true
    @State var hasSaved = false
    @State var processedCount = 0
    //    @State private var annotations: [Annotation] = [Annotation(points: RectPoints(), label: "Table")]
    private func updateCount(){
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryUrl = urls.first!
        
        guard let items = try? fileManager.contentsOfDirectory(atPath: documentsDirectoryUrl.path()) else {
            return
        }
        print("Found \(items.count) items: \(items.joined(separator: "\n"))")
        withAnimation{
            self.processedCount = items.count
        }
    }
    private func loadAnnotations(){
        updateCount()
        hasSaved = false
        if !keepForNext {
            withAnimation {
                annotations = []
            }
        }
        guard let displayedImage else { return }
        guard let geo else { print("no geometry!");return }
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryUrl = urls.first!
        let jsonUrl = documentsDirectoryUrl.appendingPathComponent(displayedImage.dropLast(4)+".json")
        guard fileManager.fileExists(atPath: jsonUrl.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: jsonUrl)
            let an = try decoder.decode([Annotation].self, from: data)
            if an.count == 0{
                if annotations.count == 0{
                    withAnimation{
                        focusedAnnotation = -1
                    }
                }else{
                    focusedAnnotation = annotations.count-1
                }
                return
            }
            
            let scaledAns = an.map{a in
                var a = a
                var p2 = a.points
                p2.topLeft = toScaledPoint(p: p2.topLeft, geometry: geo)
                p2.topRight = toScaledPoint(p: p2.topRight, geometry: geo)
                p2.bottomLeft = toScaledPoint(p: p2.bottomLeft, geometry: geo)
                p2.bottomRight = toScaledPoint(p: p2.bottomRight, geometry: geo)
                a.points = p2
                return a
            }
            withAnimation{
                annotations = scaledAns
                hasSaved = true
            }
            
        }catch{
            DispatchQueue.main.async {
                withAnimation {
                    self.msg = "while loading an: \(error)"
                }
            }
        }
        if annotations.count == 0{
            withAnimation{
                focusedAnnotation = -1
            }
        }else{
            focusedAnnotation = annotations.count-1
        }
    }
    @State var task: Task<Void, Never>? = nil
    private func ansURL() -> URL? {
        guard let displayedImage else { return nil }
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectoryUrl = urls.first!
        let jsonUrl = documentsDirectoryUrl.appendingPathComponent(displayedImage.dropLast(4)+".json")
        return jsonUrl
    }
    func toScaledPoint(p: CGPoint, geometry: GeometryProxy)->CGPoint{
        let originalWidth = uiImage!.size.width
        let originalHeight = uiImage!.size.height
        
        let scale = min(geometry.size.width / originalWidth,
                        geometry.size.height / originalHeight)
        
        // The displayed (scaled) size of the image in SwiftUI points:
        let displayedWidth = originalWidth * scale
        let displayedHeight = originalHeight * scale
        
        // Center the image in its container:
        let xOffset = (geometry.size.width - displayedWidth) / 2
        let yOffset = (geometry.size.height - displayedHeight) / 2
        
        let pixelX = (scale*p.x + xOffset)
        let pixelY = (scale*p.y + yOffset)
        
        return .init(x: pixelX, y: pixelY)
        
        
        
        /*
         x = (i-o)/s
         (i-o) = sx
         i = sx + o
         */
        
    }
    func originalPoint(p: CGPoint, geometry: GeometryProxy)->CGPoint{
        let originalWidth = uiImage!.size.width
        let originalHeight = uiImage!.size.height
        
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
    private func saveAnnotations(){
        guard let geo else { print("no geometry!");return }
        if let task{
            task.cancel()
        }
        guard let jsonUrl = ansURL() else { return }
        
        do {
            let ans2 = annotations.map{a in
                var a = a
                var p2 = a.points
                p2.topLeft = originalPoint(p: p2.topLeft, geometry: geo)
                p2.topRight = originalPoint(p: p2.topRight, geometry: geo)
                p2.bottomLeft = originalPoint(p: p2.bottomLeft, geometry: geo)
                p2.bottomRight = originalPoint(p: p2.bottomRight, geometry: geo)
                a.points = p2
                return a
            }
            let data = try encoder.encode(ans2)
            try data.write(to: jsonUrl)
            withAnimation {
                self.msg = "saved"
                hasSaved = true
            }
            
            task = Task {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation{
                        self.msg = ""
                    }
                }
            }
        }catch{
            DispatchQueue.main.async {
                withAnimation {
                    self.msg = "while loading an: \(error)"
                }
            }
        }
    }
    private func addNew(category: String){
        withAnimation {
            if let previous = annotations.last{
                self.annotations.append(Annotation(points: RectPoints(prev: previous.points), label: category))
            }else{
                self.annotations.append(Annotation(points: RectPoints(), label: category))
            }
            focusedAnnotation = annotations.count - 1
            ansChanged()
        }
    }
    private func showAll(){
        withAnimation{
            isShowingAll.toggle()
        }
    }
    private func ansChanged(){
        saveAnnotations()
    }
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                HStack{
                    VStack{
                        Spacer()
                        if msg != ""{
                            Text(msg)
                        }
                        if focusedAnnotation != -1{
                            Button("delete"){
                                withAnimation{
                                    _ = annotations.remove(at: focusedAnnotation)
                                    ansChanged()
                                    if annotations.isEmpty{
                                        focusedAnnotation = -1
                                    }else{
                                        focusedAnnotation = annotations.count-1
                                    }
                                }
                            }
                        }
                        if annotations.count > 1{
                            Button("show all", action: showAll)
                                .padding(.top)
                        }
                        Spacer()
                        if annotations.count > 0{
                            ShareLink("share", item: ansURL()!)
                            //                        Button("Share", action: shareAnnotations)
                        }
                        Spacer()
                    }.padding(.leading)
                    Spacer()
                    VStack{
                        Spacer()
                        Button(action: {
                            withAnimation {
                                keepForNext.toggle()
                               }
                        }, label: {
                            Text(keepForNext ? "✅ keep" : "❌ discard")
                                .font(.caption)
                        })
                        Spacer()
                        if !hasSaved{
                            Button("⚠️save", action: saveAnnotations)
                        }
                        
                        
                        Spacer()
                        ForEach(categories, id: \.self){c in
                            Button(action: {
                                addNew(category: c)
                            }) {
                                Text(String(c.prefix(2)))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white) // Adjust text color if needed
                                    .frame(width: 20, height: 20)
                                    .background(colorByCategory[c]!)
                                    .clipShape(Circle())
                            }
                            .padding(.bottom)
                        }
                        Spacer()
                    }
                    .padding(.trailing)
                }
                VStack{
                    HStack{
                        VStack{
                            ProgressView(value: Double(processedCount)/Double(imageManager.images.count))
                            Text("annotated")
                                .font(.caption2)
                            Text("\(processedCount)/\(imageManager.images.count)")
                                .font(.footnote)
                        }
                        .frame(width: 60)
                        Spacer()
                        Button("+", action: {addNew(category: categories.randomElement()!)})
                    }
                    .padding()
                    HStack {
                        Button(action: {
                            withAnimation{
                                displayedImage = imageManager.previousImage()
                                uiImage = UIImage(named: displayedImage!)
                                loadAnnotations()
                            }
                        }) {
                            Image(systemName: "arrow.left")
                        }
                        Spacer()
                        Button(action: {
                            withAnimation{
                                displayedImage = imageManager.nextImage()
                                uiImage = UIImage(named: displayedImage!)
                                loadAnnotations()
                            }
                        }) {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .padding()
                    Spacer()
                }
                if let uiImage {
                        let originalWidth = uiImage.size.width
                        let originalHeight = uiImage.size.height
                        
                        let scale = min(geometry.size.width / originalWidth,
                                        geometry.size.height / originalHeight)
                        
                        // The displayed (scaled) size of the image in SwiftUI points:
                        let displayedWidth = originalWidth * scale
                        let displayedHeight = originalHeight * scale
                        
                        // Center the image in its container:
//                        let xOffset = (geometry.size.width - displayedWidth) / 2
//                        let yOffset = (geometry.size.height - displayedHeight) / 2
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: displayedWidth, height: displayedHeight)
                            .position(x: geometry.size.width / 2,
                                      y: geometry.size.height / 2)
                    
                    
                } else {
                    Text("No Image Available")
                }
                ForEach(0..<annotations.count, id: \.self){i in
                    AdjustableRectangle(a: $annotations[i], hasChanged: {
                        withAnimation{
                            focusedAnnotation = i
                            ansChanged()
                        }
                    })
                    .opacity(isShowingAll ? 1 : focusedAnnotation == i ? 1 : 0.3)
                    .onTapGesture {
                        DispatchQueue.main.async{
                            withAnimation{
                                focusedAnnotation = i
                            }
                        }
                    }
                }
            }
            .onAppear {
                self.geo = geometry
                displayedImage = imageManager.images.first!
                hasSaved = false
                uiImage = UIImage(named: displayedImage!)
                loadAnnotations()
            }
        }
    }
}

#Preview {
    ImageSwitcher()
}


let all_imgs = ["dec24_PNG-Bild-4D81-BEE8-CC-0.png",
                "nov24_PNG-Bild-4C53-962F-A8-0.png",
                "jan24_PNG-Bild-4639-B9CB-79-0.png",
                "mar24_PNG-Bild-4376-BC93-B9-0.png",
                "jul24_PNG-Bild-4B93-BEA1-2B-0.png",
                "sep23_PNG-Bild-4B67-A71A-15-0.png",
                "sep24_PNG-Bild-4447-B90A-D6-0.png",
                "feb24_PNG-Bild-4105-B184-0C-0.png",
                "mar24_PNG-Bild-42D3-A849-0B-0.png",
                "oct23_PNG-Bild-419B-832F-58-0.png",
                "nov23_PNG-Bild-4420-848A-2E-0.png",
                "sep24_PNG-Bild-49E7-8CF8-D6-0.png",
                "oct23_PNG-Bild-401D-AA0D-30-0.png",
                "jan25_PNG-Bild-4A7C-ADC4-B3-0.png",
                "jul24_PNG-Bild-4418-A4DB-A9-0.png",
                "nov24_PNG-Bild-44C2-A034-F7-0.png",
                "jun24_PNG-Bild-48B6-BD17-B9-0.png",
                "jan24_PNG-Bild-4AEA-B014-08-0.png",
                "oct24_PNG-Bild-4F6E-B35B-20-0.png",
                "feb24_PNG-Bild-4F6B-A2FB-AB-0.png",
                "mar24_PNG-Bild-4DC4-8036-F3-0.png",
                "may24_PNG-Bild-4914-A638-77-0.png",
                "oct23_PNG-Bild-4381-8306-D7-0.png",
                "oct24_PNG-Bild-43D9-8B7B-52-0.png",
                "nov24_PNG-Bild-45F7-B256-82-0.png",
                "oct23_PNG-Bild-4818-A667-38-0.png",
                "oct24_PNG-Bild-44A5-959A-3A-0.png",
                "jun24_PNG-Bild-453C-91B2-CE-0.png",
                "dec23_PNG-Bild-4988-83F3-36-0.png",
                "oct24_PNG-Bild-4FBD-9CF9-BE-0.png",
                "feb24_PNG-Bild-4BA8-AE38-EA-0.png",
                "dec24_PNG-Bild-45DD-8772-92-0.png",
                "sep24_PNG-Bild-4A01-B39D-89-0.png",
                "mar24_PNG-Bild-4DCD-BAD1-F0-0.png",
                "sep24_PNG-Bild-4751-8F66-0C-0.png",
                "mar24_PNG-Bild-4CFB-9E4F-49-0.png",
                "oct23_PNG-Bild-48A4-882E-2E-0.png",
                "nov24_PNG-Bild-4148-9B76-2F-0.png",
                "dec24_PNG-Bild-4C10-9244-9E-0.png",
                "may24_PNG-Bild-47F5-86C9-07-0.png",
                "nov23_PNG-Bild-4207-BF2E-CD-0.png",
                "nov24_PNG-Bild-4CCF-90F9-75-0.png",
                "oct24_PNG-Bild-4BF1-BEDC-51-0.png",
                "dec24_PNG-Bild-418C-BBF8-51-0.png",
                "nov23_PNG-Bild-477C-BDEF-95-0.png",
                "oct24_PNG-Bild-4DA2-B67A-F9-0.png",
                "jan24_PNG-Bild-4EDA-8EAF-D4-0.png",
                "feb24_PNG-Bild-47F5-8AB1-37-0.png",
                "dec24_PNG-Bild-4CF1-AEE6-F3-0.png",
                "aug24_PNG-Bild-427D-87A1-F6-0.png",
                "feb24_PNG-Bild-476E-9B99-D5-0.png",
                "jan25_PNG-Bild-46F8-B372-3D-0.png",
                "oct24_PNG-Bild-4B07-A647-53-0.png",
                "jan24_PNG-Bild-4FD1-8FDC-8B-0.png",
                "sep24_PNG-Bild-4CBF-80C2-93-0.png",
                "oct24_PNG-Bild-46DB-B56B-ED-0.png",
                "nov23_PNG-Bild-4DCB-BD68-5A-0.png",
                "jan24_PNG-Bild-4672-8E18-B1-0.png",
                "aug24_PNG-Bild-4E92-93AE-BE-0.png",
                "jul24_PNG-Bild-4D76-9653-B7-0.png",
                "may24_PNG-Bild-4E65-B406-5F-0.png",
                "nov23_PNG-Bild-4DD5-BAA6-18-0.png",
                "jan24_PNG-Bild-4FB1-AA48-A2-0.png",
                "oct24_PNG-Bild-4F64-9B10-DD-0.png",
                "sep24_PNG-Bild-4A16-8F7B-EA-0.png",
                "nov23_PNG-Bild-445E-B41E-C8-0.png",
                "dec23_PNG-Bild-49B0-B759-F6-0.png",
                "nov24_PNG-Bild-4372-843D-D4-0.png",
                "dec23_PNG-Bild-4E15-A6D4-09-0.png",
                "jan25_PNG-Bild-4769-ACB1-68-0.png",
                "feb24_PNG-Bild-4562-B650-8C-0.png",
                "oct24_PNG-Bild-4ED4-A79F-58-0.png",
                "feb24_PNG-Bild-4E52-8765-64-0.png",
                "sep24_PNG-Bild-4AB9-ABE8-23-0.png",
                "oct24_PNG-Bild-47BE-919B-7D-0.png",
                "jul24_PNG-Bild-4030-9C05-0A-0.png",
                "apr24_PNG-Bild-42CC-9BBB-E6-0.png",
                "jul24_PNG-Bild-448C-8C70-C0-0.png",
                "apr24_PNG-Bild-41AF-84A7-10-0.png",
                "oct23_PNG-Bild-4434-A2AD-0D-0.png",
                "oct24_PNG-Bild-408C-9CF1-18-0.png",
                "jul24_PNG-Bild-4A46-BE45-2D-0.png",
                "nov23_PNG-Bild-469F-BDA5-88-0.png",
                "may24_PNG-Bild-44DB-9E1B-6D-0.png",
                "dec24_PNG-Bild-4ADF-8097-60-0.png",
                "nov24_PNG-Bild-44A3-B8CD-D7-0.png",
                "aug24_PNG-Bild-464F-92CA-6C-0.png",
                "apr24_PNG-Bild-4B67-A6F2-EF-0.png",
                "dec23_PNG-Bild-4854-95AD-94-0.png",
                "nov24_PNG-Bild-47C6-AAC3-88-0.png",
                "sep24_PNG-Bild-45F0-9C04-1A-0.png",
                "mar24_PNG-Bild-42EE-A68C-DB-0.png",
                "jun24_PNG-Bild-44CD-9C0A-6B-0.png",
                "jun24_PNG-Bild-4B6F-A436-6E-0.png",
                "may24_PNG-Bild-4B2B-AB83-1B-0.png",
                "jan24_PNG-Bild-43EF-8E86-5F-0.png",
                "jan24_PNG-Bild-4873-A6B7-0A-0.png",
                "jul24_PNG-Bild-41EA-A5B2-87-0.png",
                "jul24_PNG-Bild-471D-8ED8-EC-0.png",
                "jan25_PNG-Bild-42CE-849A-33-0.png",
                "dec24_PNG-Bild-4890-BB24-59-0.png",
                "may24_PNG-Bild-4DB1-8E62-9B-0.png",
                "mar24_PNG-Bild-466D-B3BA-7F-0.png",
                "oct23_PNG-Bild-4CBD-94ED-70-0.png",
                "oct23_PNG-Bild-40DE-BD64-91-0.png",
                "jul24_PNG-Bild-4E68-B305-D0-0.png",
                "aug24_PNG-Bild-4A85-8179-C6-0.png",
                "mar24_PNG-Bild-4569-8F2E-0F-0.png",
                "sep24_PNG-Bild-4262-9485-E7-0.png",
                "sep24_PNG-Bild-4EFE-8B04-5A-0.png",
                "jan25_PNG-Bild-4174-B868-D6-0.png",
                "jul24_PNG-Bild-412B-9339-3C-0.png",
                "oct23_PNG-Bild-4EE3-AA59-83-0.png",
                "may24_PNG-Bild-4582-8132-4A-0.png",
                "jul24_PNG-Bild-4285-9B63-2F-0.png",
                "jan24_PNG-Bild-41DE-94B6-9D-0.png",
                "jan25_PNG-Bild-40C9-B019-4F-0.png",
                "nov23_PNG-Bild-426F-9C7B-87-0.png",
                "dec23_PNG-Bild-44A2-9743-11-0.png",
                "jul24_PNG-Bild-418C-8D4D-1F-0.png",
                "apr24_PNG-Bild-4070-B64E-A4-0.png",
                "nov23_PNG-Bild-4F8F-9637-D7-0.png",
                "jul24_PNG-Bild-4E0B-B70A-63-0.png",
                "nov24_PNG-Bild-46A4-BEE8-05-0.png",
                "jun24_PNG-Bild-4E56-8044-5F-0.png",
                "mar24_PNG-Bild-4FE7-804A-FC-0.png",
                "oct23_PNG-Bild-4225-A643-60-0.png",
                "nov24_PNG-Bild-494E-B695-B9-0.png",
                "jun24_PNG-Bild-4883-AD07-B6-0.png",
                "apr24_PNG-Bild-42F5-85CF-09-0.png",
                "jul24_PNG-Bild-4084-8D0E-D2-0.png",
                "oct23_PNG-Bild-4647-A323-41-0.png",
                "aug24_PNG-Bild-4753-BF2A-9D-0.png",
                "sep23_PNG-Bild-464C-9D7B-79-0.png",
                "nov24_PNG-Bild-470F-9CF6-D0-0.png",
                "may24_PNG-Bild-46A5-A97E-67-0.png",
                "may24_PNG-Bild-4698-B516-AC-0.png",
                "apr24_PNG-Bild-4665-988E-54-0.png",
                "dec24_PNG-Bild-4D77-8C52-3C-0.png",
                "aug24_PNG-Bild-431F-BFB6-B2-0.png",
                "jan25_PNG-Bild-4CAE-BF67-79-0.png",
                "nov23_PNG-Bild-479E-955D-AA-0.png",
                "may24_PNG-Bild-40E6-9A88-6E-0.png",
                "nov24_PNG-Bild-4FBE-9179-AB-0.png",
                "nov24_PNG-Bild-4E76-A628-B7-0.png",
                "feb24_PNG-Bild-4ECB-ADB5-4C-0.png",
                "dec23_PNG-Bild-42B9-BE21-07-0.png",
                "dec24_PNG-Bild-43D8-88A4-85-0.png",
                "feb24_PNG-Bild-42FB-BD77-3E-0.png",
                "may24_PNG-Bild-4EB6-ADD8-A6-0.png",
                "jul24_PNG-Bild-4609-9C81-CD-0.png",
                "nov23_PNG-Bild-4E5E-97C4-52-0.png",
                "may24_PNG-Bild-4102-9A98-CA-0.png",
                "apr24_PNG-Bild-4E53-8941-3B-0.png",
                "oct24_PNG-Bild-43F8-BC81-EE-0.png",
                "sep24_PNG-Bild-4C8D-805B-34-0.png",
                "mar24_PNG-Bild-40B9-AB4D-11-0.png",
                "oct24_PNG-Bild-4677-82EB-62-0.png",
                "nov23_PNG-Bild-44B2-B11E-69-0.png",
                "oct23_PNG-Bild-41F0-98F0-EE-0.png",
                "sep24_PNG-Bild-4C45-9693-64-0.png",
                "dec24_PNG-Bild-4D70-824D-51-0.png",
                "jan24_PNG-Bild-4685-B5EB-31-0.png",
                "oct24_PNG-Bild-452F-9EA5-C5-0.png",
                "may24_PNG-Bild-4471-8EC6-40-0.png",
                "mar24_PNG-Bild-41B0-BE2A-D3-0.png",
                "sep24_PNG-Bild-44B3-8450-56-0.png",
                "dec23_PNG-Bild-4F16-9997-A9-0.png",
                "jan25_PNG-Bild-410F-9DE0-80-0.png",
                "feb24_PNG-Bild-4E12-B53F-E1-0.png",
                "nov24_PNG-Bild-478C-9A4C-D6-0.png",
                "jul24_PNG-Bild-4122-829B-1B-0.png",
                "feb24_PNG-Bild-4BD3-8979-84-0.png",
                "jul24_PNG-Bild-4CE7-B1FA-04-0.png",
                "feb24_PNG-Bild-4AA6-BA9A-2C-0.png",
                "oct24_PNG-Bild-43A5-8468-1E-0.png",
                "mar24_PNG-Bild-486C-B386-DB-0.png",
                "may24_PNG-Bild-4986-9B87-1F-0.png",
                "nov24_PNG-Bild-48C3-93CC-F8-0.png",
                "nov23_PNG-Bild-471D-852D-3C-0.png",
                "may24_PNG-Bild-45E2-B531-94-0.png",
                "oct23_PNG-Bild-4A8C-B5C5-BB-0.png"]
