(local dbg (require :dbg))
(require :boring)
(require :border)

(local THRES_INSIDE 0.55)
(local THRES_INTER 75)
(local STACK_STEP 15)

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

(lambda f-merge [frame-a frame-b] 
  (let [x (math.min frame-a.x frame-b.x) 
        y (math.min frame-a.y frame-b.y)
        w (- (math.max (+ frame-a.x frame-a.w) 
                       (+ frame-b.x frame-b.w)) x)
        h (- (math.max (+ frame-a.y frame-a.h) 
                       (+ frame-b.y frame-b.h)) y)]
    (hs.geometry.new x y w h)))

(lambda merge-frames [frames cond]
  (let [output []]
    (each [_ frame (ipairs frames)]
      (let [?matched (first output #(cond frame $1))]
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
  (let [intersection (a:intersect b)]
    intersection.w))

(lambda f-intersection-y [a b]
  (let [intersection (a:intersect b)]
    intersection.h))

(lambda f-intersect-x? [a b]
  (>= (f-intersection-x a b) THRES_INTER))

(lambda f-intersect-y? [a b]
  (>= (f-intersection-y a b) THRES_INTER))

(lambda f-intersect? [a b]
  (and (f-intersect-x? a b)
       (f-intersect-y? a b)))

(lambda f-mostly-in-x? [innie outie]
  (>= (f-intersection-x innie outie)
      (* innie.w THRES_INSIDE)))

(lambda f-mostly-in-y? [innie outie]
  (>= (f-intersection-y innie outie)
      (* innie.h THRES_INSIDE)))

(lambda f-mostly-in? [innie outie]
  (and (f-mostly-in-x? innie outie)
       (f-mostly-in-y? innie outie)))

(lambda set-win-frame [win {: x : y : w : h}]
  (win:setFrame (hs.geometry.new x y w h) 0))

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
  (merge-frames (map (get-windows) #($1:frame)) 
                #(f-intersect? $1 $2)))

(lambda get-groups-sorted []
  (sort (get-groups) frame-comperator))

(lambda get-group-of [win] 
  (first (get-groups) 
         #(f-mostly-in? (frame-of win) $1)))

(lambda get-active-group [] 
  "Returns active screen"
  (get-group-of (hs.window.focusedWindow)))

(lambda get-columns []
  (merge-frames (get-groups) 
                #(let [screen-1 (get-screen-of $1)
                       screen-2 (get-screen-of $2)] 
                   (and (f-intersect-x? $1 $2) 
                        (= (screen-1:id) (screen-2:id))))))

(lambda get-columns-sorted []
  (sort (get-columns) frame-comperator))

;; actual functions
(lambda cmd-focus-window [direction]
    (let [windows  (get-windows-inside (get-active-screen))
          curr-win (get-active-window)
          curr-idx (index-of-window windows curr-win)]
      (if curr-idx
          (let [step (case [direction] [:next] 1 [:prev] -1)
                next-idx (+ (% (+ curr-idx -1 step) (length windows)) 1)
                next-win (. windows next-idx)]
            (next-win:focus)))))

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

(lambda cmd-focus-stack [] nil)
(lambda cmd-move-window [] nil)
(lambda cmd-resize-window [] nil)
(lambda cmd-migrate-window [] nil)
(lambda cmd-expand-group [] nil)

;; testing stuff here
(lambda test []
  (let [screens (get-screens-sorted)
        windows (get-windows-sorted)
        groups  (get-groups)
        columns  (get-columns)]
    (dbg.inspect (collect [_ scr (ipairs screens)] 
      (values 
        (scr:name)
        (icollect [_ win (ipairs windows)]
          (if (f-mostly-in? (win:frame) (scr:frame))
              (win:title))))))
    (each [i gr (ipairs groups)]
          (dbg.show-border 
            (dbg.create-border gr)))
    (each [i screen (ipairs screens)]
      (print (.. (screen:name) " " (let [size (screen:frame)] 
                                     (.. "(" size.w "x" size.h ")")))))
    (each [i win (ipairs (get-windows-inside (get-active-screen)))]
      (print (win:title)))))

(hs.hotkey.bind [:shift :ctrl] :D test)
(hs.hotkey.bind [:shift :ctrl] :R dbg.clear-borders)
(hs.hotkey.bind [:shift :ctrl] :J #(cmd-focus-window :next))
(hs.hotkey.bind [:shift :ctrl] :K #(cmd-focus-window :prev))
(hs.hotkey.bind [:shift :ctrl] :S cmd-stack-group)
