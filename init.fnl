(local dbg (require :dbg))
(require :boring)

(local THRESHOLD 0.9)

(var borders [])

(lambda sort [tbl comperator]
  "Sort tbl based on comperator function."
  (let [sorted (icollect [_ v (ipairs tbl)] v)]
    (table.sort sorted comperator)
    sorted))

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
  "Checks if THRESHOLD percent of the innie 
    is in the outie in the X-axis"
  (let [intersection (innie:intersect outie)]
    (>= intersection.w (* innie.w THRESHOLD))))

(lambda f-mostly-in-y [innie outie]
  "Checks if THRESHOLD percent of the innie 
    is in the outie in the Y-axis"
  (let [intersection (innie:intersect outie)]
    (>= intersection.h (* innie.h THRESHOLD))))

(lambda f-mostly-in [innie outie]
  "Checks if THRESHOLD percent of the innie 
    is in the outie in both axis"
  (and (f-mostly-in-x innie outie)
       (f-mostly-in-y innie outie)))

(lambda get-screens [] 
  "Gets screens"
  (hs.screen.allScreens))

(lambda get-screens-sorted []
  "Gets screens sorted on comperator-by-frames"
  (sort (get-screens) comperator-by-frames))

(lambda get-screen-of [win] 
  "Gets screen of window based on f-mostly-in function"
  (or (icollect [_ scr (ipairs (get-screens))]
        (f-mostly-in (win:frame) (scr:frame)))))

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

(lambda show-border [border]
  "Draws a border and keeps track of it in borders global var"
  (border:show)
  (table.insert borders border))

(lambda clear-borders []
  "Deletes all borders and clears borders global var"
  (each [_ border (ipairs borders)]
    (border:delete))
  (set borders []))

(lambda test []
  (let [screens (get-screens-sorted)
        windows (get-windows-sorted)]
    (dbg.inspect (collect [_ scr (ipairs screens)] 
      (values 
        (scr:name)
        (icollect [_ win (ipairs windows)]
          (if (f-mostly-in (win:frame) (scr:frame))
              (win:title))))))
    (each [i win (ipairs windows)]
          (show-border 
            (dbg.create-border (win:frame))))))

(hs.hotkey.bind [:shift :ctrl] :D test)
(hs.hotkey.bind [:shift :ctrl] :S clear-borders)
