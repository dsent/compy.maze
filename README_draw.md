# Draw

A program for learning to code by guiding a robot around a
canvas to draw!

## Choosing a Drawing Game

Draw starts with two numbered choices and a mode switch:

  1 — Free draw
  2 — Draw the picture
  S — Step by step: off / on

Press S on the menu to switch step-by-step mode on or off. It starts
off when Draw launches and keeps its setting across games until you
press S on the menu again.

Free draw is the open canvas. Draw the picture is a series of 20 tasks
that get harder in steps: counting single strokes, then closed shapes,
then a repeating step pattern, then the first pictures that send you
back over a line you already drew, then sloped sides built from steps,
and finally whole objects. It ends with a dog.

## Goal

In Free draw there is no goal to reach and no way to lose. The
canvas is yours: send the robot across the grid and watch the
trail it leaves behind.

In Draw the picture, copy the target shown above the compass.
The green dot shows where the robot starts. Each picture can be
drawn as one continuous trail. Some need you to travel over a
line you already drew.

When the trail matches the target, use the shown Tab key for the next
picture. You can also type another program and press Enter to keep
playing on the picture: the completion banner goes, a short Tab hint
appears above the legend, and Tab moves on (or finishes at the last
picture) whenever the robot is stopped. Extra lines are part of the
drawing: in default mode, change your program and run it again from a
fresh canvas; in step-by-step mode, use C to clear and start over.

Some pictures start with a faint target line on the canvas and
some start without it. Press the Menu key at any time to turn
this hint on or off.

## Editor Mode

Type commands in the text field at the bottom and press Enter to run
them. The prompt reads "Commands:" in default mode and "Next step:" in
step-by-step mode. You hear a ping for each command except C. Clearing
the canvas is silent. The text field goes away while the robot moves.
In default mode it comes back holding your program (or empty after a
win); in step-by-step mode it comes back empty, and pressing Up at the
first line recalls your last step. Press Esc while the robot moves to
stop it where it is: the drawing stays and the field comes back holding
that run's text. Press Esc to empty the field and start a new program.
Esc on an empty field returns to the drawing-game menu, and Esc at that
menu leaves Draw.

You can give directions on a compass:

  N — North
  S — South
  E — East
  W — West

Or tell the robot to move and turn relative to where it faces:

  F — move forward
  B — move backward
  L — turn left
  R — turn right

Both uppercase and lowercase letters work. You can type several
commands at once, such as EEFN. Spaces, semicolons and new lines
separate commands.

Entered command lines are echoed with reduced opacity. The
command currently being executed is highlighted in its source
line.

### Repeating Commands

Put a number before a command to repeat it:

    3E

This moves east three times.

### Defining Shortcuts

Give a name to a sequence by typing a letter, an equal sign and
the commands:

    X=3E;X;N;X

Now X runs three steps east, later in the same program. Put the
shortcut and its uses on one line with semicolons, or on several lines
with Shift+Enter. In default mode a shortcut lasts only for its run,
until pressing Tab after completing a picture carries the last winning
program's shortcuts to the next picture. In step-by-step mode every
shortcut stays across steps (in Free draw until returning to the menu;
in Draw the picture across all later steps and all later pictures,
whether you advance with Tab or jump with `.` or `,`). Shortcuts can
build on each other. N, E, S, W, F, B, L, R and C are already commands,
so they cannot name shortcuts.

### Multiple Lines And Errors

Press Shift+Enter to type several lines. All lines run in order
when you press Enter. If a command is unknown, nothing runs: the
bad letter turns red, a short message appears, and you hear a
soft sound so you can fix it.

## What Happens

The robot turns and moves with a short animation. Moving forward leaves
a bright trail. Moving backward leaves no trail. In default mode every
run starts on a clean canvas with the robot at its start, so the drawing
shows what your whole program does. In step-by-step mode the drawing and
the robot's place stay from one step to the next, so each step continues
from where the last one finished.

None of the 20 picture tasks requires moving backward without
drawing.

If a move would take the robot off the canvas, that step is
skipped and the rest of the commands keep running.

## Absolute Direction Reversal

When you send the robot directly opposite to where it faces, it
makes a 180-degree turn and moves one step forward. The turn goes
the same way as the last turn; without one, it turns clockwise.

## Clearing the Canvas

Type C to wipe the trail and send the robot back to its start.
In Free draw that is the bottom-left corner, facing north. In a
picture task it is the green starting point, facing along the
first part of the target.

C runs silently. Commands after it continue on the fresh canvas. In
default mode every run already starts fresh and C clears mid-program;
in step-by-step mode C clears the drawing and resets the robot while
keeping your shortcuts.

## Moving Between Pictures

In Draw the picture, use the same level commands as Maze:

  .  — go to the next picture
  ,  — go back one picture

Put a number in front to jump several: 3. moves three pictures forward
and 2, moves two back, stopping at the first or last picture. A jump to
another picture opens a fresh copy of it with an empty text field. The
moves after the jump do not run. In default mode a jump carries no
shortcuts and Tab carries the last winning program's shortcuts; in
step-by-step mode both Tab and jumps carry all shortcuts you have
defined. A jump that stays on the same picture, such as , on the first
one, starts it over.

## The Screen

The canvas sits on the left. On the right, the compass lists the
direction and movement commands. In Draw the picture, the target
appears on a miniature 8x8 grid above the compass, at the same
scale and coordinates as the playing field.

## Leaving

  Esc       — stop the robot; then empty the text field;
              from an empty field, return to the
              drawing-game menu; at the menu, leave Draw
              for the console
  Ctrl+Q    — leave Draw for the console at once

While the robot moves, the first Esc stops it. When the field
holds text, the next Esc empties it and the one after returns.
Each Esc goes back one step, so holding it down stops the robot
and goes no further. Ctrl+Q leaves Draw from anywhere.
