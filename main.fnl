(require :lib.boring)
(local dbg (require :lib.debug))
(local border (require :lib.border))

(local THRES_INSIDE 0.55)
(local THRES_INTER 75)
(local STACK_STEP 15)
(local PADDING 15)
(local MOVE_STEP 150)
(local SCALE_STEP 150)

(lambda first [tbl ?cond]
  "Returns the first element in the table that returns
    true for the condition. If the condition is not
    set then it returns the first truthy element."
  (let [cond (or ?cond #$1)]
    (accumulate [ret nil i v (ipairs tbl)] 
      (or ret 
          (if (cond v i) v nil)))))

(lambda index-of [tbl ?cond]
  (let [cond (or ?cond #$1)]
    (accumulate [ret nil i v (ipairs tbl)] 
      (or ret 
          (if (cond v i) i nil)))))

(lambda round-to-decimal [num ?decimals]
  (let [factor (^ 10 (or ?decimals 2))]
    (/ (math.floor (* num factor)) factor)))

(lambda eq-decimal? [num1 num2 ?decimals] 
  (= (round-to-decimal num1 ?decimals)
     (round-to-decimal num2 ?decimals)))

(lambda index-of-window [windows win]
  (index-of windows #(= ($1:id) (win:id))))

(lambda map [tbl mapper]
  "Maps sequential table"
  (icollect [i v (ipairs tbl)] (mapper v i)))

(lambda filter [tbl cond]
  "Filter sequential table"
  (icollect [i v (ipairs tbl)] (if (cond v i) v)))

(lambda sort [tbl comperator]
  "Sort tbl based on comperator function."
  (let [sorted (icollect [_ v (ipairs tbl)] v)]
    (table.sort sorted comperator)
    sorted))

(lambda frame-of [thing] 
  (let [metatable  (getmetatable thing)
        frame-func (?. metatable :frame)]
    (if frame-func (thing:frame) thing)))

(lambda pad-frame [rect ?padding]
  (let [padding (or ?padding PADDING)]
    (hs.geometry.rect {:x (+ rect.x padding)
                       :y (+ rect.y padding)
                       :x2 (- rect.x2 padding)
                       :y2 (- rect.y2 padding)})))

;(lambda same-frame? [a b]
;  (and (= a.x b.x)
;       (= a.y b.y)
;       (= a.w b.w)
;       (= a.h b.h)))
(lambda same-frame? [a b]
  (a:equals b))

;(lambda f-merge [frame-a frame-b] 
;  (hs.geometry.new {:x (math.min frame-a.x frame-b.x)
;                    :y (math.min frame-a.y frame-b.y)
;                    :x2 (math.max frame-a.x2 frame-b.x2)
;                    :y2 (math.max frame-a.y2 frame-b.y2)}))
(lambda f-merge [frame-a frame-b] 
  (frame-a:union frame-b))

(lambda merge-frames [things cond]
  (let [output []]
    (each [_ thing (ipairs things)]
      (let [frame (frame-of thing)
            ?matched (first output #(cond frame $1))]
        (if ?matched 
            (let [merged (f-merge frame ?matched)]
                (set ?matched.x merged.x)
                (set ?matched.y merged.y)
                (set ?matched.w merged.w)
                (set ?matched.h merged.h))
            (table.insert output frame))))
    output))

(lambda frame-comperator [frame-a frame-b]
  "Comperator function used to sort frames based on x than y."
  (if (not (= frame-a.x frame-b.x))
      (< frame-a.x frame-b.x)
      (< frame-a.y frame-b.y)))

(lambda comperator-by-frames [a b]
  "Comperator function that gives gets :frame()
    then calls frame-comperator"
  (frame-comperator (frame-of a) (frame-of b)))

(lambda f-intersection-x [a b]
  (let [frame-a      (frame-of a)
        frame-b      (frame-of b)
        intersection (frame-a:intersect frame-b)]
    intersection.w))

(lambda f-intersection-y [a b]
  (let [frame-a      (frame-of a)
        frame-b      (frame-of b)
        intersection (frame-a:intersect frame-b)]
    intersection.h))

(lambda f-intersect-x? [a b]
  (>= (f-intersection-x a b) THRES_INTER))

(lambda f-intersect-y? [a b]
  (>= (f-intersection-y a b) THRES_INTER))

(lambda f-intersect? [a b]
  (and (f-intersect-x? a b)
       (f-intersect-y? a b)))

(lambda f-mostly-in-x? [innie outie]
  (let [innie (frame-of innie)]
    (>= (f-intersection-x innie outie)
        (* innie.w THRES_INSIDE))))

(lambda f-mostly-in-y? [innie outie]
  (let [innie (frame-of innie)]
    (>= (f-intersection-y innie outie)
        (* innie.h THRES_INSIDE))))

(lambda f-mostly-in? [innie outie]
  (and (f-mostly-in-x? innie outie)
       (f-mostly-in-y? innie outie)))

(lambda focus-window [win] 
  (if win (win:focus)))

(lambda top-window-in [frame] 
  (first (hs.window.orderedWindows) #(f-mostly-in? $1 frame)))

(lambda set-win-frame [win {: x : y : w : h}]
  "Sets the window frame and tries to recover if 
    the window has a set aspect ratio"
  (let [bef-frame (win:frame)
        new-frame (hs.geometry.new x y w h)]
    (win:setFrame new-frame 0)
    (let [aft-frame (win:frame)
          fix-frame (hs.geometry.new bef-frame)]
        (if (eq-decimal? bef-frame.aspect 
                         aft-frame.aspect)
            (do 
              (if (< new-frame.h new-frame.w)
                (fix-frame:scale (/ new-frame.h fix-frame.h))
                (fix-frame:scale (/ new-frame.w fix-frame.w)))
              (set fix-frame.x x)
              (set fix-frame.y y)
              (win:setFrame fix-frame 0))))))

(lambda get-screens [] 
  "Gets screens"
  (hs.screen.allScreens))

(lambda get-screens-sorted []
  "Gets screens sorted on comperator-by-frames"
  (sort (get-screens) comperator-by-frames))

(lambda get-screen-of [win] 
  "Gets screen of window based on `f-mostly-in?` function"
  (first (get-screens) 
         #(f-mostly-in? (frame-of win) ($1:frame))))

(lambda is-valid-window [win]
  "Returns true if window is relevant"
  (and (win:isStandard)
       (not (win:isMinimized))
       (get-screen-of win)))

(lambda get-active-window [] 
  "Returns active window"
  (hs.window.focusedWindow))

(lambda get-active-screen [] 
  "Returns active screen"
  (get-screen-of (hs.window.focusedWindow)))

(lambda get-windows []
  "Returns list of windows filtered with is-valid-window"
  (icollect [_ win (ipairs (hs.window.allWindows))]
    (if (is-valid-window win)
        win)))

(lambda get-windows-sorted []
  "Returns list of windows sorted on comperator-by-frames"
  (sort (get-windows) comperator-by-frames))

(lambda get-windows-inside [frame]
  (sort (filter (get-windows) 
                #(f-mostly-in? (frame-of $1) (frame-of frame)))
        comperator-by-frames))

(lambda get-groups []
  (merge-frames (get-windows) #(f-intersect? $1 $2)))

(lambda get-groups-sorted []
  (sort (get-groups) frame-comperator))

(lambda get-group-of [win] 
  (first (get-groups) 
         #(f-mostly-in? (frame-of win) $1)))

(lambda get-active-group [] 
  "Returns active screen"
  (get-group-of (hs.window.focusedWindow)))

(lambda get-columns-sorted []
  (merge-frames (get-groups-sorted)
                #(let [screen-1 (get-screen-of $1)
                       screen-2 (get-screen-of $2)] 
                   (and (f-intersect-x? $1 $2) 
                        (= (screen-1:id) (screen-2:id))))))

(lambda get-column-of [win]
  (first (get-columns-sorted)
         #(f-mostly-in? (frame-of win) $1)))

(lambda get-active-column []
  "Returns active screen"
  (get-column-of (hs.window.focusedWindow)))

;; actual functions
(lambda cmd-focus-window [direction]
    (let [windows  (get-windows-inside (get-active-screen))
          curr-win (get-active-window)
          curr-idx (index-of-window windows curr-win)]
      (if curr-idx
          (let [step (case [direction] [:next] 1 [:prev] -1)
                next-idx (+ (% (+ curr-idx -1 step) (length windows)) 1)
                next-win (. windows next-idx)]
            (focus-window next-win)))))

(lambda cmd-focus-group [direction]
    (let [groups   (get-groups-sorted)
          curr-grp (get-active-group)
          curr-idx (index-of groups #(same-frame? $1 curr-grp))]
      (if curr-idx
          (let [step (case [direction] [:next] 1 [:prev] -1)
                next-idx (+ (% (+ curr-idx -1 step) (length groups)) 1)
                next-grp (. groups next-idx)]
            (focus-window (top-window-in next-grp))))))

(lambda cmd-focus-column [direction]
    (let [columns  (get-columns-sorted)
          curr-col (get-active-column)
          curr-idx (index-of columns #(same-frame? $1 curr-col))]
      (if curr-idx
          (let [step (case [direction] [:next] 1 [:prev] -1)
                next-idx (+ (% (+ curr-idx -1 step) (length columns)) 1)
                next-col (. columns next-idx)]
            (focus-window (top-window-in next-col))))))

(lambda cmd-stack-group [] 
  (let [group   (get-active-group)
        windows (get-windows-inside group)
        amount  (length windows)]
    (each [i win (ipairs windows)] 
      (let [x (+ group.x (* STACK_STEP (- i 1)))
            y (+ group.y (* STACK_STEP (- i 1)))
            w (- group.w (* STACK_STEP (- amount 1)))
            h (- group.h (* STACK_STEP (- amount 1)))]
        (set-win-frame win {: x : y : h : w})))))

(lambda cmd-expand-group [] 
  (let [group-frame   (get-active-group)
        screen-frame  (frame-of (get-active-screen))
        innie-windows (filter (get-windows-inside screen-frame)
                              #(f-mostly-in? $1 group-frame))
        outie-windows (filter (get-windows-inside screen-frame)
                              #(not (f-mostly-in? $1 group-frame)))]
    (var expanded 
      (accumulate [expanded screen-frame _ win (ipairs outie-windows)]
        (let [win-frame (win:frame)]
          (hs.geometry.new {:x (if (< win-frame.x2 group-frame.x) 
                                   (math.max win-frame.x2 expanded.x)
                                   expanded.x)
                            :y (if (< win-frame.y2 group-frame.y) 
                                   (math.max win-frame.y2 expanded.y)
                                   expanded.y)
                            :x2 (if (> win-frame.x group-frame.x2) 
                                    (math.min win-frame.x expanded.x2)
                                    expanded.x2)
                            :y2 (if (> win-frame.y group-frame.y2) 
                                    (math.min win-frame.y expanded.y2)
                                    expanded.y2)}))))
    (set expanded (pad-frame expanded))
    (each [_ win (ipairs innie-windows)] 
      (let [win-frame (win:frame)]
        (set-win-frame win 
          (hs.geometry.new {:x (+ expanded.x (- win-frame.x group-frame.x))
                            :y (+ expanded.y (- win-frame.y group-frame.y))
                            :x2 (- expanded.x2 (- group-frame.x2 win-frame.x2))
                            :y2 (- expanded.y2 (- group-frame.y2 win-frame.y2))}))))))


(lambda cmd-move-window [direction] 
  (let [win     (get-active-window)
        screen  (get-active-screen)
        frame   (win:frame)
        limits  (pad-frame (screen:frame))]
    (case [direction]
      [:up]    (set frame.y (- frame.y MOVE_STEP))
      [:down]  (set frame.y (+ frame.y MOVE_STEP))
      [:left]  (set frame.x (- frame.x MOVE_STEP))
      [:right] (set frame.x (+ frame.x MOVE_STEP)))
    (set frame.x (math.max frame.x limits.x))
    (set frame.y (math.max frame.y limits.y))
    (set frame.x (math.min frame.x (- limits.x2 frame.w)))
    (set frame.y (math.min frame.y (- limits.y2 frame.h)))
    (set-win-frame win frame)))

(lambda cmd-resize-window [command]
  (let [win     (get-active-window)
        screen  (get-active-screen)
        frame   (win:frame)
        limits  (pad-frame (screen:frame))
        center  frame.center]
    (case [command]
      [:both-up]   (do (set frame.w (+ frame.w SCALE_STEP))
                       (set frame.h (+ frame.h SCALE_STEP)))
      [:both-down] (do (set frame.w (- frame.w SCALE_STEP))
                       (set frame.h (- frame.h SCALE_STEP)))
      [:horz-up]   (set frame.w (+ frame.w SCALE_STEP))
      [:horz-down] (set frame.w (- frame.w SCALE_STEP))
      [:vert-up]   (set frame.h (+ frame.h SCALE_STEP))
      [:vert-down] (set frame.h (- frame.h SCALE_STEP)))
    (set frame.x (- center.x (/ frame.w 2)))
    (set frame.y (- center.y (/ frame.h 2)))
    (set-win-frame win (frame:intersect limits))))

(lambda cmd-carve-window [] nil)
(lambda cmd-migrate-window [] nil)

;; testing stuff here
(lambda test []
  (let [screens (get-screens-sorted)
        windows (get-windows-sorted)
        groups  (get-groups)
        columns  (get-columns-sorted)]
    (dbg.inspect (collect [_ scr (ipairs screens)] 
      (values 
        (scr:name)
        (icollect [_ win (ipairs windows)]
          (if (f-mostly-in? (win:frame) (scr:frame))
              (win:title))))))
    (each [i fr (ipairs columns)]
          (dbg.show-border
            (dbg.create-border (pad-frame fr -2) (if (same-frame? fr (get-column-of (get-active-window)))
                                      :red
                                      :blue))))
    (each [i fr (ipairs groups)]
          (dbg.show-border
            (dbg.create-border (pad-frame fr 2))))
    (each [i screen (ipairs screens)]
      (print (.. (screen:name) " " (let [size (screen:frame)] 
                                     (.. "(" size.w "x" size.h ")")))))
    (each [i win (ipairs (get-windows-inside (get-active-screen)))]
      (print (win:title)))))

(hs.hotkey.bind [:shift :ctrl] :D test)
(hs.hotkey.bind [:shift :ctrl] :R dbg.clear-borders)

(hs.hotkey.bind [:cmd] :H #nil)

(hs.hotkey.bind [:shift :ctrl] :J #(cmd-focus-window :next))
(hs.hotkey.bind [:shift :ctrl] :K #(cmd-focus-window :prev))
(hs.hotkey.bind [:shift :ctrl] :L #(cmd-focus-column :next))
(hs.hotkey.bind [:shift :ctrl] :H #(cmd-focus-column :prev))

(hs.hotkey.bind [:shift :ctrl] :S (border.draw-after cmd-stack-group))
(hs.hotkey.bind [:shift :ctrl] :E (border.draw-after cmd-expand-group))
(hs.hotkey.bind [:shift :ctrl :cmd] :S (border.draw-after cmd-stack-group))
(hs.hotkey.bind [:shift :ctrl :cmd] :E (border.draw-after cmd-expand-group))

(hs.hotkey.bind [:shift :ctrl :cmd] :H (border.draw-after #(cmd-move-window :left)))
(hs.hotkey.bind [:shift :ctrl :cmd] :J (border.draw-after #(cmd-move-window :down)))
(hs.hotkey.bind [:shift :ctrl :cmd] :K (border.draw-after #(cmd-move-window :up)))
(hs.hotkey.bind [:shift :ctrl :cmd] :L (border.draw-after #(cmd-move-window :right)))

(hs.hotkey.bind [:shift :ctrl :cmd] :+ (border.draw-after #(cmd-resize-window :both-up)))
(hs.hotkey.bind [:shift :ctrl :cmd] :- (border.draw-after #(cmd-resize-window :both-down)))
(hs.hotkey.bind [:shift :ctrl :cmd] :Y (border.draw-after #(cmd-resize-window :horz-down)))
(hs.hotkey.bind [:shift :ctrl :cmd] :U (border.draw-after #(cmd-resize-window :vert-down)))
(hs.hotkey.bind [:shift :ctrl :cmd] :I (border.draw-after #(cmd-resize-window :vert-up)))
(hs.hotkey.bind [:shift :ctrl :cmd] :O (border.draw-after #(cmd-resize-window :horz-up)))

(border.init)
