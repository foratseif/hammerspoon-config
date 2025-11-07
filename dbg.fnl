(lambda to-str [thing ?key ?indent] 
  (let [indent (or ?indent "")] 
    (..
      indent
      (if ?key (.. ?key " = ") "")
      (case [(type thing)]
        [:string] (.. "'" thing "'")
        [:userdata] "#userdata"
        [:table] 
          (.. (.. "{" "\n")
              (table.concat 
                (icollect [k v (pairs thing)] 
                  (to-str v k (.. "  " indent))))
              (.. indent "}"))
        _ (tostring thing))
      (if ?indent "\n" ""))))

(lambda create-border [rect ?color]
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

(lambda inspect [thing] 
  (print (to-str thing)))

{: inspect : create-border}
