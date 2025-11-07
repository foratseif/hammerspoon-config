(hs.console.clearConsole)
(hs.console.consolePrintColor {:red 1 :green 1 :blue 1  :alpha 1})
(hs.console.darkMode true)
(hs.console.outputBackgroundColor { :white 0 })
(hs.console.consoleCommandColor { :white 1 })
(hs.console.alpha 1)
(let [font (hs.console.consoleFont)]
  (set font.size (+ 3 font.size))
  (hs.console.consoleFont font))

(pcall require :hs.ipc)
