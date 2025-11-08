(local dbg (require :dbg))
(require :boring)

(local THRES_INSIDE 0.9)
(local THRES_INTER 0.5)

(lambda first [tbl ?cond]
  "Returns the first element in the table that returns
    true for the condition. If the condition is not
    set then it returns the first truthy element."
  (let [cond (or ?cond #$2)]
    (accumulate [ret nil _ v (ipairs tbl)] 
      (or ret 
          (if (cond i v) v nil)))))

(lambda sort [tbl comperator]
  "Sort tbl based on comperator function."
  (let [sorted (icollect [_ v (ipairs tbl)] v)]
    (table.sort sorted comperator)
    sorted))

(lambda merge-frames [a b] 
  (let [x (math.min a.x b.x) 
        y (math.min a.y b.y)
        w (- (math.max (+ a.x a.w) 
                       (+ b.x b.w)) x)
        h (- (math.max (+ a.y a.h) 
                       (+ b.y b.h)) y)]
    {: x : y : w : h}))

(lambda frame-comperator [frame-a frame-b]
  "Comperator function used to sort frames based on x than y."
  (if (not (= frame-a.x frame-b.x))
      (< frame-a.x frame-b.x)
      (< frame-a.y frame-b.y)))

(lambda comperator-by-frames [a b]
  "Comperator function that gives gets :frame()
    then calls frame-comperator"
  (frame-comperator (a:frame) (b:frame)))

(lambda f-mostly-in-x [innie outie]
  "Checks if THRES_INSIDE percent of the innie 
    is in the outie in the X-axis"
  (let [intersection (innie:intersect outie)]
    (>= intersection.w (* innie.w THRES_INSIDE))))

(lambda f-mostly-in-y [innie outie]
  "Checks if THRES_INSIDE percent of the innie 
    is in the outie in the Y-axis"
  (let [intersection (innie:intersect outie)]
    (>= intersection.h (* innie.h THRES_INSIDE))))

(lambda f-mostly-in [innie outie]
  "Checks if THRESHOLD percent of the innie 
    is in the outie in both axis"
  (and (f-mostly-in-x innie outie)
       (f-mostly-in-y innie outie)))

(lambda f-interection [f1 f2]
  (let [intersection (f1:intersect f2)
        i-area       (* intersection.h intersection.w)
        f1-area      (* f1.h f1.w)
        f2-area      (* f2.h f2.w)]
    (or (>= i-area (* f1-area THRES_INTER))
        (>= i-area (* f2-area THRES_INTER)))))

(lambda get-screens [] 
  "Gets screens"
  (hs.screen.allScreens))

(lambda get-screens-sorted []
  "Gets screens sorted on comperator-by-frames"
  (sort (get-screens) comperator-by-frames))

(lambda get-screen-of [win] 
  "Gets screen of window based on f-mostly-in function"
  (first (get-screens) 
         #(f-mostly-in (win:frame) ($2:frame))))

(lambda is-valid-window [win]
  "Returns true if window is relevant"
  (and (win:isStandard)
       (not (win:isMinimized))
       (get-screen-of win)))

(lambda get-windows []
  "Returns list of windows filtered with is-valid-window"
  (icollect [_ win (ipairs (hs.window.allWindows))]
    (if (is-valid-window win)
        win)))

(lambda get-windows-sorted []
  "Returns list of windows sorted on comperator-by-frames"
  (sort (get-windows) comperator-by-frames))

(lambda get-groups []
  "Returns list of group frames"
  (let [windows (get-windows)
        groups  []]
    (each [_ win (ipairs windows)]
      (let [?gr (first groups #(f-interection (win:frame) $2))]
        (if ?gr 
            (let [merged (merge-frames (win:frame) ?gr)]
                (set ?gr.x merged.x)
                (set ?gr.y merged.y)
                (set ?gr.w merged.w)
                (set ?gr.h merged.h))
            (table.insert groups (win:frame)))))
    groups))

;; testing stuff here
(lambda test []
  (let [screens (get-screens-sorted)
        windows (get-windows-sorted)
        groups  (get-groups)]
    (dbg.inspect (collect [_ scr (ipairs screens)] 
      (values 
        (scr:name)
        (icollect [_ win (ipairs windows)]
          (if (f-mostly-in (win:frame) (scr:frame))
              (win:title))))))
    (each [i gr (ipairs groups)]
          (dbg.show-border 
            (dbg.create-border gr)))))

(hs.hotkey.bind [:shift :ctrl] :D test)
(hs.hotkey.bind [:shift :ctrl] :S dbg.clear-borders)
