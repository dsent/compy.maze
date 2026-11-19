-- core_editor.lua

-- The command-line editor flow shared by every program:
-- prompt, submit, validate, run, and re-arm. The app
-- supplies before_run() (what to do once a program
-- validates) and finish_run() (what a finished run means).

-- Macros (editor X=... sequences and recorded keyboard
-- macros) carry across levels through a per-level base.
-- Each editor run rebuilds the table from that base, so a
-- definition deleted from the program is dropped; only
-- carried base bindings survive a restart.

function clone_macros(src)
  local t = { }
  for k, v in pairs(src) do
    t[k] = v
  end
  return t
end

-- before_run() is supplied by the app and called by
-- start_program once a program validates: the maze resets
-- the level, and draw clears the drawing and sends the
-- robot to its start. The core names it but never defines
-- it.

-- Editor input processing

-- The editor runs the whole program from the start each
-- time. A miss or crash shows a modal that waits for Tab
-- (see draw_failed); a syntax error keeps the editor open
-- and shows its message on this prompt so the child fixes
-- it in place.

function input_prompt()
  if GS.invalid then
    return GS.invalid.msg
  end
  return "Commands:"
end

-- Submitting is an event: the runtime calls
-- on_text_entered with the entered text.

function submit_program(text)
  start_program(text)
end

-- Up at the first-line boundary recalls the last program,
-- but only when one exists. Down at the last-line boundary
-- does nothing, so recall stays lossless. Ordinary cursor
-- motion inside the program is left to the widget.

function program_limit_reached(direction)
  if direction ~= "up" or not GS.program then
    return
  end
  compy.input.set_text(string.lines(GS.program))
end

-- The prompt is written only where it genuinely changes:
-- arming a level, rejecting a program, and ending a run.
-- Watching for a change instead would mean remembering the
-- previous value to compare against.
--
-- show() only shows: over an already-shown widget it is
-- ignored and cannot change the prompt. Reconfigure is what
-- changes a live widget, and the text is set separately.
--
-- "Widget" is compy.input's own name for it; this repo's own
-- prose calls the same thing the command field. Comments
-- written here on the input branch use the platform's word.

function open_editor(text)
  compy.input.show{
    prompt = input_prompt(),
    text = string.lines(text),
    on_text_entered = submit_program,
    on_limit_reached = program_limit_reached,
  }
end

function set_prompt(text)
  if compy.input.is_shown() then
    compy.input.configure{ prompt = input_prompt() }
    compy.input.set_text(string.lines(text))
  else
    open_editor(text)
  end
end

-- The reject path: a failed validation keeps the typed
-- text on screen, marks it invalid, and re-prompts.

function reject_program(text, bad, lines)
  sfx.wrong()
  GS.invalid = bad
  GS.program = text
  echo_lines = lines
  set_prompt(text)
end

-- Esc empties the field (each program's on_escape). A
-- refused program's error goes with its text: the prompt says
-- "Commands:" again and the echo is empty, as at a level's
-- fresh start, so the screen says nothing about a program
-- that is gone.

function clear_field()
  compy.input.clear()
  if not GS.invalid then
    return
  end
  GS.invalid = nil
  echo_lines = { }
  compy.input.configure{ prompt = input_prompt() }
end

-- Any submit clears the previous run's crash marker; it
-- otherwise persists through Tab so it stays visible while
-- the child edits.
--
-- A program is validated against the level's base, and a
-- rejected one leaves the shortcuts of the run before it,
-- which a win or a jump still carries on.
--
-- A run from the field is judged when it ends, whatever the
-- run before it left: a win, a miss or a crash drops
-- ctrl_update to hold the screen, and Enter in place of Tab
-- arms it again.

function start_program(text)
  GS.failed = nil
  GS.crash = nil
  local lines = string.lines(text)
  local earlier = macros
  macros = clone_macros(GS.base_macros)
  local bad = validate_program(lines)
  if bad then
    macros = earlier
    reject_program(text, bad, lines)
    return
  end
  GS.invalid = nil
  GS.program = text
  ctrl_update = rearm_input
  before_run()
  echo_lines = lines
  process_input(lines, 0)
  GS.running = true
end

function editor_idle()
  return not player.anim and 0 == #(player.queue)
end

-- Still a poll, and the game's own question rather than the
-- editor's: has the queue drained? Nothing raises an event
-- for an animation ending.
--
-- The widget comes back here because this is the moment the
-- run ends -- once, not once per frame. Which runs get it
-- back is finish_run's decision, read from what it leaves
-- behind: a win starts an animation, a miss drops
-- ctrl_update, and a crash does neither -- that is the case
-- the child edits and retries from.

function rearm_input()
  if not editor_idle() then
    return
  end
  if not GS.running then
    return
  end
  finish_run()
  if ctrl_update and editor_idle() then
    set_prompt(GS.program or "")
  end
end

-- Arm the command editor with initial text. editor()
-- starts empty; rearm_editor() keeps the last program.
--
-- It goes through set_prompt rather than opening directly:
-- a level can arm while a widget from the previous one is
-- still shown, and showing over a shown widget is ignored --
-- which would silently drop both the text and the label
-- this was called to set.

function arm_editor(text)
  ctrl_pressed = nil
  ctrl_update = rearm_input
  set_prompt(text)
end

function editor()
  arm_editor("")
end

function rearm_editor()
  arm_editor(GS.program or "")
end
