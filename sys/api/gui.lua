-- GUI API
-- by recoskyler
-- 2020

-- x = 1
-- y = 1
-- w = 3
-- h = 3
-- ox = 0
-- oy = 0
-- dragging = false

-- ball = window.create(term.current(), x, y, w, h, true)

-- term.setBackgroundColor(colors.black)
-- term.clear()
-- ball.setBackgroundColor(colors.red)
-- ball.clear()

-- while true do
--     e, p1, p2, p3, p4, p5, p6 = os.pullEvent()
    
--     if e == "mouse_drag" and dragging then
--         term.clear()
--         ball.reposition(p2 - ox, p3 - oy)
--         ball.redraw()
--         x = p2 - ox
--         y = p3 - oy
--     elseif e == "mouse_click" then
--         dragging = false

--         if p2 >= x and p2 < x + w and p3 >= y and p3 < y + h then
--             dragging = true
--             ox = p2 - x
--             oy = p3 - y
--         end
--     elseif e == "mouse_up" then
--         dragging = false
--     end
-- end