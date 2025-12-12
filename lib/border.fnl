;(local border-color {:red 0.7 :green 0.7 :blue 0.7 :alpha 0.8})
;(local border-width 2)
;(local border-offset 1)

;(local border-color {:red 0.2 :green 0.7 :blue 0.8 :alpha 1})
(local border-color {:red 0.7 :green 0.7 :blue 0.8 :alpha 0.5})
;(local border-color {:red 0.624 :green 0.494 :blue 0.125 :alpha 1})
(local border-width 5)
(local border-offset 3)

(var focus-border nil)

(lambda adjust-frame [frame]
  (hs.geometry.new
    (- frame.x border-offset)
    (- frame.y border-offset)
    (+ frame.w (* 2 border-offset))
    (+ frame.h (* 2 border-offset))))

(lambda create-border [frame]
  (let [border (hs.drawing.rectangle (adjust-frame frame))]
    (border:setFill false)
    (border:setStrokeColor border-color)
    (border:setStrokeWidth border-width)
    (local radius 12)
    (border:setRoundedRectRadii radius radius)
    (set focus-border border)))

(lambda delete []
  (if focus-border
      (do (focus-border:delete)
          (set focus-border nil))))

(lambda draw []
  (delete)
  (let [win (hs.window.focusedWindow)]
    (if win
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

{: init
 : draw
 : draw-after}
