import SwiftUI

struct RiverSceneView: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    @State private var oarAngle: Double = 0
    @State private var isRowing = false

    private let riverBlue = Color(red: 0.2, green: 0.5, blue: 0.85)
    private let bankGreen = Color(red: 0.25, green: 0.65, blue: 0.3)
    private let skyTop = Color(red: 0.55, green: 0.78, blue: 0.95)
    private let skyBottom = Color(red: 0.85, green: 0.92, blue: 1.0)
    private let boatBrown = Color(red: 0.55, green: 0.35, blue: 0.15)

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                drawScene(context: context, size: size, time: time)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animatedProgress = newValue
            }
            // Trigger rowing animation
            isRowing = true
            withAnimation(.easeInOut(duration: 0.4).repeatCount(6, autoreverses: true)) {
                oarAngle = 25
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    oarAngle = 0
                    isRowing = false
                }
            }
        }
        .onAppear {
            animatedProgress = progress
        }
    }

    // MARK: - Drawing

    private func drawScene(context: GraphicsContext, size: CGSize, time: Double) {
        let riverY = size.height * 0.4
        let riverHeight = size.height * 0.35
        let bankHeight = size.height * 0.15

        // Sky gradient
        let skyRect = CGRect(x: 0, y: 0, width: size.width, height: riverY)
        context.fill(
            Path(skyRect),
            with: .linearGradient(
                Gradient(colors: [skyTop, skyBottom]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: riverY)
            )
        )

        // Sun
        let sunCenter = CGPoint(x: size.width * 0.85, y: size.height * 0.12)
        let sunPath = Path(ellipseIn: CGRect(
            x: sunCenter.x - 20, y: sunCenter.y - 20, width: 40, height: 40
        ))
        context.fill(sunPath, with: .color(Color(red: 1.0, green: 0.85, blue: 0.3)))
        // Sun glow
        let glowPath = Path(ellipseIn: CGRect(
            x: sunCenter.x - 30, y: sunCenter.y - 30, width: 60, height: 60
        ))
        context.fill(glowPath, with: .color(Color(red: 1.0, green: 0.9, blue: 0.4).opacity(0.3)))

        // Far bank (top of river)
        drawBank(context: context, y: riverY - bankHeight * 0.5, width: size.width, height: bankHeight, time: time, treeSeed: 42)

        // River with animated waves
        drawRiver(context: context, y: riverY, width: size.width, height: riverHeight, time: time)

        // Near bank (bottom of river)
        drawBank(context: context, y: riverY + riverHeight - bankHeight * 0.3, width: size.width, height: bankHeight + size.height * 0.15, time: time, treeSeed: 17)

        // Finish flag
        let flagX = size.width * 0.9
        let flagY = riverY + riverHeight * 0.25
        drawFlag(context: context, x: flagX, y: flagY)

        // Start marker
        let startX = size.width * 0.08
        drawStartMarker(context: context, x: startX, y: riverY + riverHeight * 0.5)

        // Rower + boat
        let rowerMinX = size.width * 0.1
        let rowerMaxX = size.width * 0.88
        let rowerX = rowerMinX + (rowerMaxX - rowerMinX) * animatedProgress
        let rowerY = riverY + riverHeight * 0.4 + sin(time * 1.5) * 2 // gentle bob
        drawBoatAndRower(context: context, x: rowerX, y: rowerY, time: time)

        // Wake behind boat
        if animatedProgress > 0.01 {
            drawWake(context: context, x: rowerX, y: rowerY + 8, width: min(animatedProgress * 60, 40), time: time)
        }

        // Clouds
        drawCloud(context: context, x: size.width * 0.2 + sin(time * 0.1) * 10, y: size.height * 0.08, scale: 0.8)
        drawCloud(context: context, x: size.width * 0.55 + sin(time * 0.08 + 1) * 8, y: size.height * 0.15, scale: 0.6)
    }

    private func drawRiver(context: GraphicsContext, y: CGFloat, width: CGFloat, height: CGFloat, time: Double) {
        // Base river
        var riverPath = Path()
        riverPath.move(to: CGPoint(x: 0, y: y))

        // Wavy top edge
        for x in stride(from: 0, through: width, by: 2) {
            let waveY = y + sin(x * 0.02 + time * 2) * 3 + sin(x * 0.05 + time * 1.5) * 2
            riverPath.addLine(to: CGPoint(x: x, y: waveY))
        }

        riverPath.addLine(to: CGPoint(x: width, y: y + height))
        riverPath.addLine(to: CGPoint(x: 0, y: y + height))
        riverPath.closeSubpath()

        context.fill(
            riverPath,
            with: .linearGradient(
                Gradient(colors: [
                    riverBlue,
                    riverBlue.opacity(0.7),
                    Color(red: 0.15, green: 0.4, blue: 0.75)
                ]),
                startPoint: CGPoint(x: 0, y: y),
                endPoint: CGPoint(x: 0, y: y + height)
            )
        )

        // Water sparkle ripples
        for i in 0..<6 {
            let rippleX = width * Double(i + 1) / 7.0 + sin(time * 0.8 + Double(i)) * 15
            let rippleY = y + height * 0.3 + cos(time + Double(i) * 0.7) * 8
            let rippleWidth = 12.0 + sin(time * 1.2 + Double(i)) * 4
            let ripplePath = Path(ellipseIn: CGRect(
                x: rippleX - rippleWidth / 2, y: rippleY - 1,
                width: rippleWidth, height: 2.5
            ))
            context.fill(ripplePath, with: .color(.white.opacity(0.25 + sin(time + Double(i)) * 0.1)))
        }
    }

    private func drawBank(context: GraphicsContext, y: CGFloat, width: CGFloat, height: CGFloat, time: Double, treeSeed: Int) {
        // Ground
        var bankPath = Path()
        bankPath.move(to: CGPoint(x: 0, y: y + 8))
        for x in stride(from: 0, through: width, by: 3) {
            let bumpY = y + 8 + sin(x * 0.03 + Double(treeSeed)) * 4
            bankPath.addLine(to: CGPoint(x: x, y: bumpY))
        }
        bankPath.addLine(to: CGPoint(x: width, y: y + height))
        bankPath.addLine(to: CGPoint(x: 0, y: y + height))
        bankPath.closeSubpath()

        context.fill(bankPath, with: .color(bankGreen))

        // Simple trees
        let treePositions = [0.1, 0.25, 0.42, 0.6, 0.78, 0.93]
        for (i, pos) in treePositions.enumerated() {
            let treeX = width * pos + Double((treeSeed + i * 7) % 20) - 10
            let treeY = y + 6 + sin(Double(treeSeed + i) * 1.3) * 3
            let treeHeight = 14.0 + Double((treeSeed + i * 3) % 8)
            let sway = sin(time * 0.5 + Double(i)) * 1.5

            // Trunk
            let trunkPath = Path { p in
                p.move(to: CGPoint(x: treeX + sway * 0.3, y: treeY))
                p.addLine(to: CGPoint(x: treeX + sway, y: treeY - treeHeight))
            }
            context.stroke(trunkPath, with: .color(Color(red: 0.4, green: 0.28, blue: 0.15)), lineWidth: 2)

            // Canopy (triangle)
            let canopyPath = Path { p in
                let cx = treeX + sway
                let cy = treeY - treeHeight
                let canopyRadius = 6.0 + Double((treeSeed + i) % 4)
                p.move(to: CGPoint(x: cx, y: cy - canopyRadius))
                p.addLine(to: CGPoint(x: cx - canopyRadius, y: cy + canopyRadius * 0.5))
                p.addLine(to: CGPoint(x: cx + canopyRadius, y: cy + canopyRadius * 0.5))
                p.closeSubpath()
            }
            let greenVariant = Color(
                red: 0.2 + Double((treeSeed + i) % 3) * 0.05,
                green: 0.55 + Double((treeSeed + i) % 4) * 0.05,
                blue: 0.2
            )
            context.fill(canopyPath, with: .color(greenVariant))
        }
    }

    private func drawBoatAndRower(context: GraphicsContext, x: CGFloat, y: CGFloat, time: Double) {
        // Boat hull
        let hullPath = Path { p in
            p.move(to: CGPoint(x: x - 18, y: y))
            p.addQuadCurve(
                to: CGPoint(x: x + 18, y: y),
                control: CGPoint(x: x, y: y + 10)
            )
            p.addLine(to: CGPoint(x: x + 15, y: y - 3))
            p.addLine(to: CGPoint(x: x - 15, y: y - 3))
            p.closeSubpath()
        }
        context.fill(hullPath, with: .color(boatBrown))
        context.stroke(hullPath, with: .color(Color(red: 0.4, green: 0.25, blue: 0.1)), lineWidth: 1)

        // Person body (sitting)
        let bodyX = x
        let bodyY = y - 8

        // Torso
        let torsoPath = Path { p in
            p.move(to: CGPoint(x: bodyX, y: bodyY + 5))
            p.addLine(to: CGPoint(x: bodyX, y: bodyY - 4))
        }
        context.stroke(torsoPath, with: .color(Color(red: 0.3, green: 0.3, blue: 0.3)), lineWidth: 2.5)

        // Head
        let headPath = Path(ellipseIn: CGRect(x: bodyX - 3.5, y: bodyY - 11, width: 7, height: 7))
        context.fill(headPath, with: .color(Color(red: 0.9, green: 0.75, blue: 0.6)))

        // Arms + oars
        let oarRotation = oarAngle * .pi / 180

        // Left oar
        let leftOarEnd = CGPoint(
            x: bodyX - 16 - cos(oarRotation) * 5,
            y: bodyY + 2 + sin(oarRotation) * 8
        )
        let leftArmPath = Path { p in
            p.move(to: CGPoint(x: bodyX - 2, y: bodyY - 1))
            p.addLine(to: leftOarEnd)
        }
        context.stroke(leftArmPath, with: .color(.gray), lineWidth: 1.5)
        // Oar blade
        let leftBladePath = Path(ellipseIn: CGRect(
            x: leftOarEnd.x - 4, y: leftOarEnd.y - 1, width: 5, height: 3
        ))
        context.fill(leftBladePath, with: .color(Color(red: 0.6, green: 0.4, blue: 0.2)))

        // Right oar
        let rightOarEnd = CGPoint(
            x: bodyX + 16 + cos(oarRotation) * 5,
            y: bodyY + 2 + sin(oarRotation) * 8
        )
        let rightArmPath = Path { p in
            p.move(to: CGPoint(x: bodyX + 2, y: bodyY - 1))
            p.addLine(to: rightOarEnd)
        }
        context.stroke(rightArmPath, with: .color(.gray), lineWidth: 1.5)
        // Oar blade
        let rightBladePath = Path(ellipseIn: CGRect(
            x: rightOarEnd.x - 1, y: rightOarEnd.y - 1, width: 5, height: 3
        ))
        context.fill(rightBladePath, with: .color(Color(red: 0.6, green: 0.4, blue: 0.2)))
    }

    private func drawWake(context: GraphicsContext, x: CGFloat, y: CGFloat, width: CGFloat, time: Double) {
        for i in 0..<3 {
            let offset = Double(i) * 8
            let wakeAlpha = 0.2 - Double(i) * 0.06
            let wakePath = Path { p in
                p.move(to: CGPoint(x: x - 5 - offset, y: y))
                p.addQuadCurve(
                    to: CGPoint(x: x - 5 - offset - width, y: y + Double(i + 1) * 3),
                    control: CGPoint(x: x - 5 - offset - width * 0.5, y: y - 2 + sin(time * 2 + Double(i)) * 2)
                )
            }
            context.stroke(wakePath, with: .color(.white.opacity(wakeAlpha)), lineWidth: 1.5)
        }
    }

    private func drawFlag(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Pole
        let polePath = Path { p in
            p.move(to: CGPoint(x: x, y: y + 10))
            p.addLine(to: CGPoint(x: x, y: y - 15))
        }
        context.stroke(polePath, with: .color(.gray), lineWidth: 2)

        // Flag
        let flagPath = Path { p in
            p.move(to: CGPoint(x: x, y: y - 15))
            p.addLine(to: CGPoint(x: x + 12, y: y - 11))
            p.addLine(to: CGPoint(x: x, y: y - 7))
            p.closeSubpath()
        }
        context.fill(flagPath, with: .color(.red))

        // Checkered pattern hint
        let checkPath = Path { p in
            p.move(to: CGPoint(x: x + 3, y: y - 14))
            p.addLine(to: CGPoint(x: x + 8, y: y - 12))
            p.addLine(to: CGPoint(x: x + 3, y: y - 10))
            p.closeSubpath()
        }
        context.fill(checkPath, with: .color(.white))
    }

    private func drawStartMarker(context: GraphicsContext, x: CGFloat, y: CGFloat) {
        // Small dock / start platform
        let dockPath = Path { p in
            p.addRect(CGRect(x: x - 6, y: y - 2, width: 12, height: 4))
        }
        context.fill(dockPath, with: .color(Color(red: 0.5, green: 0.35, blue: 0.2)))

        // Post
        let postPath = Path { p in
            p.move(to: CGPoint(x: x, y: y - 2))
            p.addLine(to: CGPoint(x: x, y: y - 12))
        }
        context.stroke(postPath, with: .color(Color(red: 0.4, green: 0.3, blue: 0.2)), lineWidth: 2)

        // "GO" sign
        let signPath = Path(roundedRect: CGRect(x: x - 8, y: y - 18, width: 16, height: 8), cornerRadius: 2)
        context.fill(signPath, with: .color(.green))
    }

    private func drawCloud(context: GraphicsContext, x: CGFloat, y: CGFloat, scale: CGFloat) {
        let cloudColor = Color.white.opacity(0.8)
        let r = 8.0 * scale
        let positions: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 0, r),
            (-r * 0.8, r * 0.3, r * 0.7),
            (r * 0.8, r * 0.3, r * 0.7),
            (r * 0.3, -r * 0.2, r * 0.6),
        ]
        for (dx, dy, radius) in positions {
            let cloudPart = Path(ellipseIn: CGRect(
                x: x + dx - radius, y: y + dy - radius,
                width: radius * 2, height: radius * 2
            ))
            context.fill(cloudPart, with: .color(cloudColor))
        }
    }
}
