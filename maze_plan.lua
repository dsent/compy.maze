-- maze_plan.lua

-- Plan-a-path control mode: typed direction commands
-- collect as key tiles at the bottom of the screen and
-- Enter runs the pending tail. A middle step between
-- direct control (keys) and the editor.

-- Plan state lives in GS.plan: buf holds command chars,
-- done counts tiles already executed (shown green), exec
-- is the tile animating now. A run either wins or sends
-- the robot home: crash_at keeps the crash display and
-- ran keeps the all-green missed-run display, both until
-- the next edit or submit; hold delays the miss reset so
-- the end position can be seen.

function plan_reset()
  GS.plan = {
    buf = { },
    done = 0
  }
end

-- Any level reset sends the robot home, so the whole
-- buffer is pending again.

function plan_rewind()
  local p = GS.plan
  if p then
    p.done = 0
    p.exec = nil
  end
end

-- Input is locked while a run is in flight and during
-- the win pause.

function plan_locked()
  return GS.running or GS.celebrating or GS.won
end

-- An edit clears the previous run's crash or missed-run
-- display.

function plan_clear_marks()
  GS.plan.crash_at = nil
  GS.plan.ran = nil
  GS.crash = nil
end

function plan_append(c)
  local p = GS.plan
  if MAX_PLAN_LEN <= #p.buf then
    return
  end
  table.insert(p.buf, c)
  plan_clear_marks()
  sfx.toggle()
end

function plan_backspace()
  local p = GS.plan
  if #p.buf <= p.done then
    return
  end
  table.remove(p.buf)
  plan_clear_marks()
  sfx.toggle()
end

function plan_enqueue(i)
  table.insert(player.queue, GS.plan.buf[i])
  table.insert(player.queue_refs, {
    line = i,
    col_from = i,
    col_to = i
  })
  sfx.ping()
end

-- Enter runs the plan from the start: any earlier run
-- ended in a reset, so the robot is home and done is 0.

function plan_submit()
  local p = GS.plan
  if #p.buf <= p.done then
    return
  end
  plan_clear_marks()
  GS.failed = nil
  for i = p.done + 1, #p.buf do
    plan_enqueue(i)
  end
  GS.running = true
end

-- Level navigation, a teacher aid as in keys mode.

function plan_jump(k)
  local delta = 1
  if k == "," then
    delta = -1
  end
  jump_level(delta)
end

PLAN_ACTS = {
  backspace = plan_backspace,
  ["return"] = plan_submit,
  ["."] = plan_jump,
  [","] = plan_jump
}

-- Whether Esc has a plan to empty: a plan level with keys in
-- its buffer, while input is not locked (plan_locked). During
-- a run or a win Esc leaves for the menu, as on a level with
-- no plan.

function plan_holds_keys()
  local planning = ctrl_pressed == plan_key and not plan_locked()
  if not planning then
    return false
  end
  return 0 < #GS.plan.buf
end

-- A tile key is a movement primitive; the silent
-- navigation commands never become tiles.

function plan_movement(c)
  local prim = PRIMITIVES[c]
  local nav = SILENT_CMDS[c]
  return prim and not nav
end

function plan_dispatch(k)
  local act = PLAN_ACTS[k]
  if act then
    act(k)
    return
  end
  local c = k:upper()
  if plan_movement(c) then
    plan_append(c)
  end
end

-- A held key repeats keypresses; act on the edge only. The
-- runtime marks a repeat as one, so the press itself says
-- whether it is fresh -- where tracking which keys are down
-- refuses a direction for the rest of the session if its
-- release goes missing, as it does when a window loses
-- focus with the key held.

function plan_key(k, _, isrepeat)
  if isrepeat then
    return
  end
  if plan_locked() then
    return
  end
  plan_dispatch(k)
end

-- Advance the green highlight as the queue drains.

function plan_track_exec()
  local a = player.anim
  local on = a and a.line
  if not on then
    return
  end
  local p = GS.plan
  p.exec = a.line
  if p.done < a.line - 1 then
    p.done = a.line - 1
  end
end

function plan_run_over()
  local busy = player.anim or 0 < #(player.queue)
  return GS.running and not busy
end

function plan_won()
  return GS.won or GS.celebrating
end

-- A run that misses the goal holds the end position for
-- a beat, then sends the robot home. The whole plan is
-- pending again, shown all green until the next edit.

function plan_miss_reset()
  local p = GS.plan
  p.hold = nil
  p.exec = nil
  p.ran = true
  GS.running = false
  reset_level()
end

function plan_holding(dt)
  local p = GS.plan
  if not p.hold then
    return false
  end
  p.hold = p.hold - dt
  if p.hold <= 0 then
    plan_miss_reset()
  end
  return true
end

-- Ends of runs: a win locks input for the celebration, a
-- crash was already handled by plan_after_crash, and a
-- miss starts the hold.

function plan_update(dt)
  plan_track_exec()
  if plan_holding(dt) then
    return
  end
  if not plan_run_over() then
    return
  end
  local p = GS.plan
  if GS.crash or plan_won() then
    GS.running = false
    if not GS.crash then
      p.done = p.exec or p.done
    end
    p.exec = nil
    return
  end
  p.hold = PLAN_MISS_HOLD
end

-- Crash: snapshot the failed tile for the display, then
-- reset the maze. The buffer is preserved so the child
-- can read which step failed, edit, and retry.

-- Esc during a plan run stops it: the robot goes home and the
-- whole plan is pending again, with no step shown as run and
-- no crash marked -- green is for steps a completed run took.

function plan_stop()
  plan_miss_reset()
  plan_clear_marks()
end

function plan_after_crash()
  local mark = GS.crash
  GS.plan.crash_at = mark and mark.line
  reset_level()
end

-- Dock strip: two tile rows, ten tiles each, at the
-- keyboard game's natural key size, anchored to the
-- bottom edge below the field. All metrics derive from
-- the keycap scale so they are independent of whatever
-- font is active.

function plan_tile_w()
  return STD_W * SCALE
end

function plan_tile_h()
  return STD_H * SCALE
end

function plan_gap()
  return SCALE
end

function plan_zone_h()
  return 2 * plan_tile_h() + 3 * plan_gap()
end
