(local dbg (require :dbg))
(require :boring)

(local THRESHOLD 0.9)

(var borders [])

(lambda sort [tbl comperator]
  (let [sorted (icollect [_ v (ipairs tbl)] v)]
    (table.sort sorted comperator)
    sorted))

(lambda frame-comperator [frame-a frame-b]
  (if (not (= frame-a.x frame-b.x))
      (< frame-a.x frame-b.x)
      (< frame-a.y frame-b.y)))

(lambda comperator-by-frames [a b]
  (frame-comperator (a:frame) (b:frame)))

(lambda get-screens [] 
  (hs.screen.allScreens))

(lambda get-screens-sorted []
  (sort (get-screens) comperator-by-frames))

(lambda is-valid-window [win]
  (and (win:isStandard)
       (not (win:isMinimized))))

(lambda get-windows []
  (icollect [_ win (ipairs (hs.window.allWindows))]
    (if (is-valid-window win)
        win)))

(lambda get-windows-sorted []
  (sort (get-windows) comperator-by-frames))

(lambda show-border [border]
  (border:show)
  (table.insert borders border))

(lambda clear-borders []
  (each [_ border (ipairs borders)]
    (border:delete))
  (set borders []))
(lambda f-mostly-in-x [innie outie]
  (let [intersection (innie:intersect outie)]
    (>= intersection.w (* innie.w THRESHOLD))))

(lambda f-mostly-in-y [innie outie]
  (let [intersection (innie:intersect outie)]
    (>= intersection.h (* innie.h THRESHOLD))))

(lambda f-mostly-in [innie outie]
  (and (f-mostly-in-x innie outie)
       (f-mostly-in-y innie outie)))

(lambda test []
  (let [screens (get-screens-sorted)
        windows (get-windows-sorted)]
    (dbg.inspect (collect [_ scr (ipairs screens)] 
      (values 
        (scr:name)
        (icollect [_ win (ipairs windows)]
          (if (f-mostly-in (win:frame) (scr:frame))
              (win:title))))))))

(hs.hotkey.bind [:shift :ctrl] :D test)
(hs.hotkey.bind [:shift :ctrl] :S clear-borders)
