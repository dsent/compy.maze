-- controls.lua

-- Control mode initializers.
-- Each sets two optional callbacks:
-- ctrl_pressed(k) from love.keypressed
-- ctrl_update() from love.update

-- Keyboard controls

function keys()
  ctrl_pressed = handle_key
  ctrl_update = nil
end

-- Plan-a-path controls: keys collect as tiles at the
-- bottom of the screen, Enter runs the plan.

function plan()
  ctrl_pressed = plan_key
  ctrl_update = plan_update
  plan_reset()
end

-- Command line controls

-- Progression modes

function portal()
  next_level()
end

-- A celebration waits for Tab. On an editor level the field,
-- away since the run began, comes back empty, as after any
-- win.

function celebrate()
  ctrl_update = nil
  GS.celebrating = true
  if cur_controls == editor then
    open_editor("")
  end
end

function continue()
  GS.won = true
end
