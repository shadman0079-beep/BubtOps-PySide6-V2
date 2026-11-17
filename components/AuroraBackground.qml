import QtQuick

Item {
    id: aurora
    clip: true

    // Master brightness of the nebula layers (higher = brighter).
    property real glow: 0.80

    // Shared clock. Integer multipliers keep every loop seamless.
    property real phase: 0
    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: 36000
        loops: Animation.Infinite
        running: true
    }

    // Per-layer settings:  0 violet/magenta, 1 blue/cyan, 2 warm,
    //                      3 teal/emerald,   4 pale core
    property var layerGain:  [1.00, 0.95, 0.70, 0.80, 0.80]
    property var layerBeat:  [1, 2, 1, 3, 2]
    property var layerSpin:  [260000, 340000, 420000, 300000, 220000]  // ms per turn
    property var layerDir:   [1, -1, 1, -1, 1]
    property var layerDrift: [34000, 41000, 29000, 37000, 31000]

    // =====================================================
    // 01. PAINTING HELPERS
    // =====================================================

    function makeRng(seed) {
        var s = seed
        return function () {
            s = (s * 16807) % 2147483647
            return (s - 1) / 2147483646
        }
    }

    function rgba(c, a) {
        return "rgba(" + Math.round(c[0]) + "," + Math.round(c[1]) + ","
               + Math.round(c[2]) + "," + a + ")"
    }

    function mix(a, b, t) {
        return [a[0] + (b[0] - a[0]) * t,
                a[1] + (b[1] - a[1]) * t,
                a[2] + (b[2] - a[2]) * t]
    }

    // Blend through a list of colors with t in 0..1.
    function ramp(cols, t) {
        var n = cols.length - 1
        var f = Math.min(t, 0.9999) * n
        var i = Math.floor(f)
        return mix(cols[i], cols[i + 1], f - i)
    }

    function paintBlob(ctx, x, y, rx, ry, rot, c, a) {
        ctx.save()
        ctx.translate(x, y)
        ctx.rotate(rot)
        ctx.scale(rx, ry)

        var g = ctx.createRadialGradient(0, 0, 0, 0, 0, 1)
        g.addColorStop(0.0, rgba(c, a))
        g.addColorStop(0.45, rgba(c, a * 0.38))
        g.addColorStop(1.0, rgba(c, 0))

        ctx.fillStyle = g
        ctx.fillRect(-1.1, -1.1, 2.2, 2.2)
        ctx.restore()
    }

    function paintCluster(ctx, rng, cx, cy, spreadX, spreadY,
                          count, rMin, rMax, c, a) {
        for (var i = 0; i < count; ++i) {
            var ang = rng() * Math.PI * 2
            var dist = Math.sqrt(rng())
            var x = cx + Math.cos(ang) * dist * spreadX
            var y = cy + Math.sin(ang) * dist * spreadY
            var r = rMin + rng() * (rMax - rMin)
            paintBlob(ctx, x, y, r * (0.8 + rng() * 0.8),
                      r * (0.5 + rng() * 0.6),
                      (rng() - 0.5) * 1.6, c, a * (0.5 + rng() * 0.5))
        }
    }

    // A curved, spiral-like arm of colored clouds around the canvas center.
    function paintArm(ctx, rng, w, a0, sweep, r0, r1, n, cols, alpha, sMin, sMax) {
        var c = w * 0.5
        for (var i = 0; i < n; ++i) {
            var t = i / (n - 1)
            var ang = a0 + t * sweep
            var rad = w * (r0 + (r1 - r0) * t)
            var px = c + Math.cos(ang) * rad
            var py = c + Math.sin(ang) * rad * 0.82
            var fade = 0.55 + 0.45 * Math.sin(t * Math.PI)

            paintCluster(ctx, rng, px, py, w * 0.07, w * 0.07, 3,
                         w * sMin, w * sMax, ramp(cols, t), alpha * fade)
        }
    }

    // One call paints any of the five nebula layers.
    function paintLayer(ctx, k, w, h) {
        ctx.clearRect(0, 0, w, h)
        ctx.globalCompositeOperation = "lighter"

        var rng = makeRng(1000 + k * 7919)
        var c = w * 0.5

        if (k === 0) {
            // Violet -> magenta -> pink
            paintArm(ctx, rng, w, 0.3, 2.7, 0.08, 0.38, 36,
                     [[104, 58, 204], [196, 62, 172], [255, 116, 168]],
                     0.30, 0.06, 0.14)
            paintBlob(ctx, c - w * 0.12, c - w * 0.05, w * 0.26, w * 0.18,
                      0.5, [120, 60, 200], 0.16)
        } else if (k === 1) {
            // Sapphire -> blue -> cyan
            paintArm(ctx, rng, w, 3.6, 2.8, 0.06, 0.36, 36,
                     [[28, 78, 200], [30, 148, 224], [60, 214, 222]],
                     0.30, 0.06, 0.14)
            paintBlob(ctx, c + w * 0.12, c + w * 0.06, w * 0.26, w * 0.18,
                      -0.4, [30, 100, 210], 0.16)
        } else if (k === 2) {
            // Warm accents: orange, gold, rose, coral
            var warm = [[255, 150, 72], [255, 205, 110],
                        [240, 92, 126], [255, 122, 90]]
            for (var j = 0; j < 4; ++j) {
                var ang = j * 1.6 + 0.5
                var rad = w * (0.15 + 0.05 * ((j * 3) % 4) / 3)
                paintCluster(ctx, rng,
                             c + Math.cos(ang) * rad, c + Math.sin(ang) * rad * 0.85,
                             w * 0.07, w * 0.06, 6,
                             w * 0.04, w * 0.10, warm[j], 0.20)
            }
        } else if (k === 3) {
            // Teal -> emerald -> mint
            paintArm(ctx, rng, w, 1.7, 2.3, 0.12, 0.34, 30,
                     [[16, 130, 170], [22, 168, 140], [110, 236, 184]],
                     0.22, 0.05, 0.12)
        } else {
            // Pale lavender-white core with cool and rosy shoulders
            paintBlob(ctx, c, c, w * 0.22, w * 0.15, -0.3,
                      [236, 222, 255], 0.20)
            paintCluster(ctx, rng, c - w * 0.05, c, w * 0.14, w * 0.09, 12,
                         w * 0.04, w * 0.10, [190, 232, 255], 0.14)
            paintCluster(ctx, rng, c + w * 0.08, c + w * 0.04, w * 0.12, w * 0.08, 10,
                         w * 0.04, w * 0.09, [214, 190, 255], 0.13)
            paintCluster(ctx, rng, c, c - w * 0.07, w * 0.12, w * 0.06, 8,
                         w * 0.03, w * 0.08, [255, 214, 236], 0.11)
        }
    }

    function paintFilaments(ctx, w, h) {
        ctx.save()
        ctx.lineCap = "round"
        ctx.globalCompositeOperation = "lighter"

        // Blue -> cyan -> lavender sweeps.
        for (var i = 0; i < 32; ++i) {
            var t = i / 31.0
            var o = t - 0.5

            var sx = -w * 0.08, sy = h * (0.72 - o * 0.30)
            var ex = w * 1.08,  ey = h * (0.24 + t * 0.40)

            var g = ctx.createLinearGradient(sx, sy, ex, ey)
            g.addColorStop(0.00, "rgba(40,100,200,0)")
            g.addColorStop(0.30, "rgba(70,150,230,0.09)")
            g.addColorStop(0.58, "rgba(110,220,235,0.14)")
            g.addColorStop(0.80, "rgba(190,170,255,0.11)")
            g.addColorStop(1.00, "rgba(150,120,230,0)")

            ctx.beginPath()
            ctx.moveTo(sx, sy)
            ctx.bezierCurveTo(w * 0.20, h * (0.16 + o * 0.45),
                              w * 0.57, h * (0.94 - o * 0.34), ex, ey)
            ctx.strokeStyle = g
            ctx.lineWidth = 0.8 + (i % 4) * 0.32
            ctx.stroke()
        }

        // Violet -> pink sweeps.
        for (var j = 0; j < 18; ++j) {
            var t2 = j / 17.0
            var sh = t2 - 0.5

            var sx2 = w * (0.12 + t2 * 0.12), sy2 = h * (0.92 - t2 * 0.42)
            var ex2 = w * (0.84 + t2 * 0.20), ey2 = h * (0.44 + t2 * 0.24)

            var g2 = ctx.createLinearGradient(sx2, sy2, ex2, ey2)
            g2.addColorStop(0.00, "rgba(110,60,190,0)")
            g2.addColorStop(0.42, "rgba(170,80,200,0.09)")
            g2.addColorStop(0.70, "rgba(250,130,190,0.13)")
            g2.addColorStop(1.00, "rgba(255,170,150,0)")

            ctx.beginPath()
            ctx.moveTo(sx2, sy2)
            ctx.bezierCurveTo(w * (0.33 + sh * 0.12), h * (0.20 + sh * 0.20),
                              w * (0.66 - sh * 0.12), h * (0.87 + sh * 0.16),
                              ex2, ey2)
            ctx.strokeStyle = g2
            ctx.lineWidth = 0.65 + (j % 3) * 0.35
            ctx.stroke()
        }

        // Pale gold-white delicate strands.
        for (var k = 0; k < 7; ++k) {
            var p = k / 6.0
            var sx3 = w * (0.18 + p * 0.06), sy3 = h * (0.65 - p * 0.08)
            var ex3 = w * (0.77 + p * 0.05), ey3 = h * (0.30 + p * 0.09)

            var g3 = ctx.createLinearGradient(sx3, sy3, ex3, ey3)
            g3.addColorStop(0.0, "rgba(255,220,180,0)")
            g3.addColorStop(0.5, "rgba(255,238,220,0.18)")
            g3.addColorStop(1.0, "rgba(255,220,180,0)")

            ctx.beginPath()
            ctx.moveTo(sx3, sy3)
            ctx.bezierCurveTo(w * 0.35, h * (0.17 + p * 0.10),
                              w * 0.68, h * (0.76 - p * 0.09), ex3, ey3)
            ctx.strokeStyle = g3
            ctx.lineWidth = 0.7
            ctx.stroke()
        }

        ctx.restore()
    }

    // =====================================================
    // 02. DEEP SPACE FOUNDATION (indigo, not black)
    // =====================================================

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "#050818" }
            GradientStop { position: 0.40; color: "#0a0f2c" }
            GradientStop { position: 0.75; color: "#0d0e30" }
            GradientStop { position: 1.0;  color: "#04061a" }
        }
    }

    // Colored corner glows that slowly breathe.
    Canvas {
        anchors.fill: parent
        opacity: aurora.glow * (0.80 + 0.20 * Math.sin(aurora.phase))

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.globalCompositeOperation = "lighter"

            aurora.paintBlob(ctx, width * 0.08, height * 0.92,
                             width * 0.60, height * 0.60, 0,
                             [150, 50, 160], 0.30)
            aurora.paintBlob(ctx, width * 0.92, height * 0.08,
                             width * 0.60, height * 0.60, 0,
                             [40, 90, 200], 0.30)
            aurora.paintBlob(ctx, width * 0.88, height * 0.95,
                             width * 0.38, height * 0.34, 0,
                             [220, 110, 70], 0.14)
            aurora.paintBlob(ctx, width * 0.50, height * 0.50,
                             width * 0.50, height * 0.40, 0,
                             [60, 40, 140], 0.18)
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // =====================================================
    // 03. COLORED NEBULA LAYERS (rotate, drift, breathe)
    // =====================================================

      Repeater {
        model: 5

        delegate: Item {
            id: layer
            required property int index

            readonly property real side: Math.sqrt(aurora.width * aurora.width
                                                   + aurora.height * aurora.height) * 1.08
            property real dx: 0
            property real dy: 0

            width: side
            height: side
            x: (aurora.width - side) / 2 + dx
            y: (aurora.height - side) / 2 + dy
            transformOrigin: Item.Center

            opacity: aurora.glow * aurora.layerGain[index]
                     * (0.72 + 0.28 * Math.sin(aurora.phase * aurora.layerBeat[index]
                                               + index * 1.9))

            NumberAnimation on rotation {
                from: 0
                to: 360 * aurora.layerDir[layer.index]
                duration: aurora.layerSpin[layer.index]
                loops: Animation.Infinite
                running: true
            }

            SequentialAnimation on scale {
                running: true; loops: Animation.Infinite
                NumberAnimation { to: 1.07; duration: 22000 + layer.index * 3000; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.97; duration: 22000 + layer.index * 3000; easing.type: Easing.InOutSine }
            }

            SequentialAnimation on dx {
                running: true; loops: Animation.Infinite
                NumberAnimation { to: layer.side * 0.03;  duration: aurora.layerDrift[layer.index]; easing.type: Easing.InOutSine }
                NumberAnimation { to: -layer.side * 0.03; duration: aurora.layerDrift[layer.index]; easing.type: Easing.InOutSine }
            }

            SequentialAnimation on dy {
                running: true; loops: Animation.Infinite
                NumberAnimation { to: -layer.side * 0.025; duration: aurora.layerDrift[layer.index] * 1.2; easing.type: Easing.InOutSine }
                NumberAnimation { to: layer.side * 0.025;  duration: aurora.layerDrift[layer.index] * 1.2; easing.type: Easing.InOutSine }
            }

            // Painted at half resolution, then scaled up (soft clouds, cheap).
            Canvas {
                width: layer.side / 2
                height: layer.side / 2
                scale: 2
                transformOrigin: Item.TopLeft
                renderTarget: Canvas.FramebufferObject

                onPaint: {
                    var ctx = getContext("2d")
                    aurora.paintLayer(ctx, layer.index, width, height)
                }

                Component.onCompleted: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }
        }
    }

    // =====================================================
    // 04. FILAMENTS (multicolor)
    // =====================================================

    Item {
        id: filamentLayer
        width: aurora.width * 1.18
        height: aurora.height * 1.15
        x: -aurora.width * 0.09
        y: -aurora.height * 0.06
        opacity: aurora.glow * 0.85

        Canvas {
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                aurora.paintFilaments(ctx, width, height)
            }

            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        SequentialAnimation on x {
            running: true; loops: Animation.Infinite
            NumberAnimation { to: -aurora.width * 0.13; duration: 33000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -aurora.width * 0.05; duration: 33000; easing.type: Easing.InOutSine }
        }
        SequentialAnimation on y {
            running: true; loops: Animation.Infinite
            NumberAnimation { to: -aurora.height * 0.03; duration: 28000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -aurora.height * 0.09; duration: 28000; easing.type: Easing.InOutSine }
        }
    }

    // =====================================================
    // 05. MILKY WAY BAND + COLORED STAR CLUSTERS
    // =====================================================

    Item {
        id: milkyWay
        width: aurora.width * 1.10
        height: aurora.height * 1.10
        x: -aurora.width * 0.05
        y: -aurora.height * 0.05
        opacity: 0.55 + 0.20 * Math.sin(aurora.phase * 2 + 1.0)

        Canvas {
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.globalCompositeOperation = "lighter"

                var w = width, h = height
                var rng = aurora.makeRng(8080)
                var tilt = Math.atan2(-0.76 * h, w)

                // Soft hazy band.
                for (var i = 0; i < 20; ++i) {
                    var t = i / 19
                    var bx = w * t
                    var by = h * (0.88 - 0.76 * t)
                    aurora.paintBlob(ctx, bx, by, w * 0.20, h * 0.11, tilt,
                                     [150, 160, 235], 0.050)
                    aurora.paintBlob(ctx, bx, by, w * 0.12, h * 0.06, tilt,
                                     [255, 222, 205], 0.030)
                }

                // Dense tiny stars hugging the band.
                var palette = [[199, 232, 240], [255, 255, 255],
                               [170, 200, 255], [255, 226, 200],
                               [255, 190, 220]]
                for (var s = 0; s < 420; ++s) {
                    var u = rng()
                    var g = (rng() + rng() + rng() - 1.5) / 1.5
                    var sx = u * w
                    var sy = h * (0.88 - 0.76 * u) + g * h * 0.12
                    var c = palette[Math.floor(rng() * palette.length)]
                    ctx.fillStyle = aurora.rgba(c, 0.12 + rng() * 0.30)
                    ctx.beginPath()
                    ctx.arc(sx, sy, 0.3 + Math.pow(rng(), 2) * 0.6, 0, Math.PI * 2)
                    ctx.fill()
                }

                // A few colored star clusters with soft halos.
                var halos = [[0.18, 0.30, [255, 140, 190], 26],
                             [0.74, 0.22, [140, 190, 255], 22],
                             [0.52, 0.72, [255, 190, 120], 28],
                             [0.88, 0.62, [170, 140, 255], 20],
                             [0.30, 0.80, [120, 230, 210], 18],
                             [0.62, 0.40, [255, 160, 140], 16]]
                for (var k = 0; k < halos.length; ++k) {
                    var hx = w * halos[k][0], hy = h * halos[k][1]
                    var hc = halos[k][2], hr = halos[k][3]
                    aurora.paintBlob(ctx, hx, hy, hr, hr, 0, hc, 0.16)
                    ctx.fillStyle = aurora.rgba([255, 255, 255], 0.85)
                    ctx.beginPath()
                    ctx.arc(hx, hy, 1.1, 0, Math.PI * 2)
                    ctx.fill()
                }
            }

            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        SequentialAnimation on x {
            running: true; loops: Animation.Infinite
            NumberAnimation { to: -aurora.width * 0.075; duration: 60000; easing.type: Easing.InOutSine }
            NumberAnimation { to: -aurora.width * 0.025; duration: 60000; easing.type: Easing.InOutSine }
        }
    }

    // =====================================================
    // 06. STATIC DISTANT STARS
    // =====================================================

    Canvas {
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var rng = aurora.makeRng(1234567)
            var palette = [[199, 232, 240], [255, 255, 255],
                           [160, 210, 255], [255, 236, 214],
                           [114, 213, 195]]

            for (var i = 0; i < 170; ++i) {
                var x = rng() * width
                var y = rng() * height
                var size = 0.35 + Math.pow(rng(), 3) * 1.0
                var c = palette[Math.floor(rng() * palette.length)]
                var a = 0.14 + rng() * 0.30

                ctx.fillStyle = aurora.rgba(c, a)
                ctx.beginPath()
                ctx.arc(x, y, size, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // =====================================================
    // 07. TWINKLING STARS (single canvas, soft glow)
    // =====================================================

    Canvas {
        id: twinkle
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        property var stars: []

        function build() {
            var rng = aurora.makeRng(55501)
            var palette = [[210, 240, 248], [255, 255, 255],
                           [170, 215, 255], [255, 238, 220],
                           [140, 225, 205]]
            var list = []
            for (var i = 0; i < 70; ++i) {
                var bright = i < 14
                list.push({
                    x: rng() * width,
                    y: rng() * height,
                    r: bright ? 0.9 + rng() * 0.5 : 0.5 + rng() * 0.5,
                    c: palette[Math.floor(rng() * palette.length)],
                    base: bright ? 0.75 : 0.40 + rng() * 0.25,
                    s1: 2 + Math.floor(rng() * 4),
                    s2: 3 + Math.floor(rng() * 5),
                    o1: rng() * Math.PI * 2,
                    o2: rng() * Math.PI * 2,
                    bright: bright,
                    spike: 7 + rng() * 5
                })
            }
            stars = list
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (stars.length === 0)
                build()

            var ph = aurora.phase

            for (var i = 0; i < stars.length; ++i) {
                var s = stars[i]

                var v = 0.5 + 0.5 * (0.65 * Math.sin(ph * s.s1 + s.o1)
                                   + 0.35 * Math.sin(ph * s.s2 + s.o2))
                v = v * v * (3 - 2 * v)

                var a = s.base * (0.30 + 0.70 * v)
                var rr = s.r * (0.88 + 0.22 * v)

                var gr = rr * (s.bright ? 6.0 : 4.0)
                var g = ctx.createRadialGradient(s.x, s.y, 0, s.x, s.y, gr)
                g.addColorStop(0.0, aurora.rgba(s.c, a * 0.55))
                g.addColorStop(0.35, aurora.rgba(s.c, a * 0.14))
                g.addColorStop(1.0, aurora.rgba(s.c, 0))
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(s.x, s.y, gr, 0, Math.PI * 2)
                ctx.fill()

                if (s.bright) {
                    var L = s.spike * (0.75 + 0.25 * v)
                    var gh = ctx.createLinearGradient(s.x - L, s.y, s.x + L, s.y)
                    gh.addColorStop(0.0, aurora.rgba(s.c, 0))
                    gh.addColorStop(0.5, aurora.rgba(s.c, a * 0.55))
                    gh.addColorStop(1.0, aurora.rgba(s.c, 0))
                    ctx.fillStyle = gh
                    ctx.fillRect(s.x - L, s.y - 0.4, L * 2, 0.8)

                    var gv = ctx.createLinearGradient(s.x, s.y - L, s.x, s.y + L)
                    gv.addColorStop(0.0, aurora.rgba(s.c, 0))
                    gv.addColorStop(0.5, aurora.rgba(s.c, a * 0.45))
                    gv.addColorStop(1.0, aurora.rgba(s.c, 0))
                    ctx.fillStyle = gv
                    ctx.fillRect(s.x - 0.4, s.y - L, 0.8, L * 2)
                }

                ctx.fillStyle = aurora.rgba([255, 255, 255], Math.min(1, a * 1.1))
                ctx.beginPath()
                ctx.arc(s.x, s.y, rr * 0.7, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        onWidthChanged: { stars = []; requestPaint() }
        onHeightChanged: { stars = []; requestPaint() }
        Component.onCompleted: requestPaint()

        Connections {
            target: aurora
            function onPhaseChanged() { twinkle.requestPaint() }
        }
    }

    // =====================================================
    // 08. SHOOTING STAR (tapered tail, random path)
    // =====================================================

    Item {
        id: meteor

        property real t: 0
        property real sx: 0
        property real sy: 0
        property real ex: 0
        property real ey: 0
        property real angle: 0.4

        x: sx + (ex - sx) * t
        y: sy + (ey - sy) * t
        width: 0
        height: 0
        rotation: angle * 180 / Math.PI

        opacity: {
            var e = t < 0.18 ? t / 0.18
                  : t > 0.55 ? (1 - t) / 0.45
                  : 1
            e = Math.max(0, Math.min(1, e))
            return e * e * (3 - 2 * e) * 0.85
        }
        visible: opacity > 0.001

        Canvas {
            id: meteorBody
            width: 190
            height: 9
            x: -width
            y: -height / 2
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cy = height / 2

                var g = ctx.createLinearGradient(0, 0, width, 0)
                g.addColorStop(0.00, "rgba(170,225,255,0)")
                g.addColorStop(0.55, "rgba(170,225,255,0.20)")
                g.addColorStop(0.92, "rgba(235,250,255,0.75)")
                g.addColorStop(1.00, "rgba(255,255,255,0.95)")

                ctx.fillStyle = g
                ctx.beginPath()
                ctx.moveTo(0, cy)
                ctx.quadraticCurveTo(width * 0.55, cy - 0.5, width - 3, cy - 1.5)
                ctx.lineTo(width - 3, cy + 1.5)
                ctx.quadraticCurveTo(width * 0.55, cy + 0.5, 0, cy)
                ctx.closePath()
                ctx.fill()

                var hg = ctx.createRadialGradient(width - 3, cy, 0, width - 3, cy, 4.5)
                hg.addColorStop(0.0, "rgba(255,255,255,0.95)")
                hg.addColorStop(0.4, "rgba(200,240,255,0.35)")
                hg.addColorStop(1.0, "rgba(200,240,255,0)")
                ctx.fillStyle = hg
                ctx.beginPath()
                ctx.arc(width - 3, cy, 4.5, 0, Math.PI * 2)
                ctx.fill()
            }
            Component.onCompleted: requestPaint()
        }

        NumberAnimation {
            id: meteorFlight
            target: meteor
            property: "t"
            from: 0
            to: 1
            duration: 1500
            easing.type: Easing.OutSine
            onFinished: {
                meteorTimer.interval = 9000 + Math.random() * 11000
                meteorTimer.start()
            }
        }

        Timer {
            id: meteorTimer
            interval: 6000
            running: true
            repeat: false
            onTriggered: {
                var ang = (14 + Math.random() * 22) * Math.PI / 180
                var len = aurora.width * (0.30 + Math.random() * 0.22)

                meteor.sx = aurora.width * (0.08 + Math.random() * 0.55)
                meteor.sy = aurora.height * (0.04 + Math.random() * 0.34)
                meteor.angle = ang
                meteor.ex = meteor.sx + Math.cos(ang) * len
                meteor.ey = meteor.sy + Math.sin(ang) * len

                meteorFlight.duration = 1200 + Math.random() * 700
                meteorFlight.restart()
            }
        }
    }

    // =====================================================
    // 09. SOFT INDIGO VIGNETTE
    // =====================================================

    Canvas {
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var w = width, h = height
            var radius = Math.max(w, h) * 0.78

            var v = ctx.createRadialGradient(w * 0.50, h * 0.45, Math.min(w, h) * 0.12,
                                             w * 0.50, h * 0.45, radius)
            v.addColorStop(0.0,  "rgba(4,5,22,0.00)")
            v.addColorStop(0.62, "rgba(4,5,22,0.12)")
            v.addColorStop(1.0,  "rgba(3,4,18,0.62)")

            ctx.fillStyle = v
            ctx.fillRect(0, 0, w, h)
        }

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }
}