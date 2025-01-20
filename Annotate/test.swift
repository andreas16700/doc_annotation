//
//  test.swift
//  Annotate
//
//  Created by Andreas Loizides on 25.12.2024.
//

import SwiftUI

//@State private var offset = CGSize.zero



struct Card {
    var prompt: String
    var answer: String

    static let example = Card(prompt: "Who played the 13th Doctor in Doctor Who?", answer: "Jodie Whittaker")
}

struct CardView: View {
    @State private var isShowingAnswer = false
    
    let card: Card
    
    @State private var offset = CGSize.zero
    
    var removal: (() -> Void)? = nil


    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)
                .shadow(radius: 10)

            VStack {
                Text(card.prompt)
                    .font(.largeTitle)
                    .foregroundStyle(.black)

                if isShowingAnswer {
                    Text(card.answer)
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .frame(width: 450, height: 250)
        .rotationEffect(.degrees(offset.width / 5.0))
        .offset(x: offset.width * 5)
        .opacity(2 - Double(abs(offset.width / 50)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { _ in
                    if abs(offset.width) > 100 {
                        removal?()
                    } else {
                        offset = .zero
                    }
                }
        )
        .onTapGesture {
            withAnimation{
                isShowingAnswer.toggle()
            }
        }
    }
    
}

#Preview {
    CardView(card: .example)
}

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(y: offset * 10)
    }
}

struct CardContainerView: View {
    @State private var cards = Array<Card>(repeating: .example, count: 10)
    func removeCard(at index: Int) {
        cards.remove(at: index)
    }
    var body: some View {
        ZStack {
                VStack {
                    ZStack {
                        ForEach(0..<cards.count, id: \.self) { index in
                            CardView(card: cards[index]) {
                               withAnimation {
                                   removeCard(at: index)
                               }
                            }
                            .stacked(at: index, in: cards.count)
                        }
                    }
                }
            }
    }
}
