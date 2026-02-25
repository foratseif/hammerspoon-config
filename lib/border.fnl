;(local border-color {:red 0.2 :green 0.7 :blue 0.8 :alpha 1})
(local border-width 5)
(local border-radius 6)
(local border-offset (+ -3 border-width))

(lambda rgb [red green blue]
  {:red (/ red 255) :green (/ green 255) :blue (/ blue 255) :alpha 255})

(var mode :normal)
(var focus-border nil)

(lambda get-border-color []
  (case mode
    :normal (rgb 57 56 87)
    ;:normal {:red 0.2 :green 0.35 :blue 0.4 :alpha 1}
    :window {:red 0.95 :green 0.5 :blue 0.2 :alpha 1}
    _       {:red 1 :green 1 :blue 1 :alpha 1}))

(lambda adjust-frame [frame]
  (hs.geometry.new
    (- frame.x border-offset)
    (- frame.y border-offset)
    (+ frame.w (* 2 border-offset))
    (+ frame.h (* 2 border-offset))))

(lambda create-border [frame]
  (let [border (hs.drawing.rectangle (adjust-frame frame))]
    (border:setFill false)
    (border:setStrokeColor (get-border-color))
    (border:setStrokeWidth border-width)
    (local radius (+ border-radius border-width))
    (border:setRoundedRectRadii radius radius)
    (set focus-border border)))

(lambda delete []
  (if focus-border
      (do (focus-border:delete)
          (set focus-border nil))))

(lambda is-fullscreen? [win]
  (let [scr  (win:screen)
        winf (win:frame)
        scrf (scr:frame)
        scrf-full (scr:fullFrame)]
    (or (win:isFullscreen)
        (and (= scrf.x winf.x)
           (= scrf.y winf.y)
           (= scrf.h winf.h)
           (= scrf.w winf.w))
        (and (= scrf-full.x winf.x)
           (= scrf-full.y winf.y)
           (= scrf-full.h winf.h)
           (= scrf-full.w winf.w)))))

(lambda draw []
  (delete)
  (let [win (hs.window.focusedWindow)]
    (if (and win (not (is-fullscreen? win)))
        (do (if (not focus-border)
                (create-border (win:frame)))
            (focus-border:show)))))

(lambda init []
  (let [window-filter (hs.window.filter.new)]
    (window-filter:subscribe hs.window.filter.windowUnfocused delete)
    (window-filter:subscribe hs.window.filter.windowDestroyed delete)
    (window-filter:subscribe hs.window.filter.windowMinimized delete)
    (window-filter:subscribe hs.window.filter.windowHidden delete)
    (window-filter:subscribe hs.window.filter.windowFocused draw)
    (window-filter:subscribe hs.window.filter.windowUnminimized draw)
    (window-filter:subscribe hs.window.filter.windowUnhidden draw)
    (window-filter:subscribe hs.window.filter.windowMoved draw)))

(lambda draw-after [func]
  (lambda []
    (func)
    (draw)))

(lambda set-mode [val]
  (set mode val)
  (draw))

{: init
 : draw
 : draw-after
 : set-mode}
