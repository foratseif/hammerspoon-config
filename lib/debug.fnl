(var borders [])

(lambda show-border [border]
  "Draws a border and keeps track of it in borders global var"
  (border:show)
  (table.insert borders border))

(lambda clear-borders []
  "Deletes all borders and clears borders global var"
  (each [_ border (ipairs borders)]
    (border:delete))
  (set borders []))

(lambda to-str [thing ?key ?level] 
  "Converts variable to string"
  (let [level  (or ?level 0)
        indent (string.rep "  " level)] 
    (.. indent
        (if ?key (.. ?key " = ") "")
        (if (> level 5)
          "MAX-LEVEL"
          (case [(type thing)]
            [:string] (.. "'" thing "'")
            [:userdata] "#userdata"
            [:table] 
              (.. (.. "{" "\n")
                  (table.concat 
                    (icollect [k v (pairs thing)] 
                      (to-str v k (+ level 1))))
                  (.. indent "}"))
            _ (tostring thing)))
        (if (> level 0) "\n" ""))))

(lambda create-border [rect ?color]
  "Creates a border based on rect.
    Accepts color but has default if color is nil."
  (let [border (hs.drawing.rectangle rect)]
    (border:setStrokeWidth 4)
    (border:setFill false)
    (border:setLevel :floating)
    (border:setBehaviorByLabels 
      [:canJoinAllSpaces :stationary :ignoresMouseEvents])
    (border:setStrokeColor 
      (case [?color]
        [:red] {:red 1 :green 0 :blue 0 :alpha 1}
        [:blue] {:red 0 :green 0 :blue 1 :alpha 1}
        [:green] {:red 0 :green 1 :blue 0 :alpha 1}
        _ {:red 1 :green 0 :blue 1 :alpha 1}))
    border))

(lambda create-and-show-border [?color rect]
  (show-border (create-border rect ?color)))

(lambda inspect [thing ?key]
  "Converts variable to string and prints it"
  (print (to-str thing ?key)))

(lambda time-func [func]
  (print "starting to time function")
  (local start (os.clock))
  (func)
  (print (string.format "function took %s ms" (math.floor (* (- (os.clock) start) 1000)))))

{: inspect 
 : to-str
 : create-border
 : show-border
 : clear-borders
 : create-and-show-border
 : time-func}
