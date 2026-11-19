# Draw

A program for learning to code by guiding a robot around a
canvas to draw!

## Choosing a Drawing Game

Draw starts with two choices:

  1 — Free draw
  2 — Draw the picture

Free draw is the open canvas. Draw the picture is a series of
20 tasks that get harder in steps: counting single strokes,
then closed shapes, then a repeating step pattern, then the
first pictures that send you back over a line you already
drew, then sloped sides built from steps, and finally whole
objects. It ends with a dog.

## Goal

In Free draw there is no goal to reach and no way to lose. The
canvas is yours: send the robot across the grid and watch the
trail it leaves behind.

In Draw the picture, copy the target shown above the compass.
The green dot shows where the robot starts. Each picture can be
drawn as one continuous trail. Some need you to travel over a
line you already drew.

When the trail matches the target, use the shown Tab key for
the next picture. Extra lines are part of the drawing, so change
your program and run it again: every run starts on a fresh
canvas.

Some pictures start with a faint target line on the canvas and
some start without it. Press the Menu key at any time to turn
this hint on or off.

## Editor Mode

Type commands in the text field at the bottom and press Enter
to run them. You hear a ping for each command except C. Clearing
the canvas is silent. The text field goes away while the robot
moves and comes back with your program when it stops, so you
can change it and press Enter to run it again. When a picture
is complete, it comes back empty. Press Esc while
the robot moves to stop it where it is: the drawing stays and
your program comes back in the field. Press Esc to empty the
field and start a new program. Esc on an empty field returns to
the drawing-game menu, and Esc at that menu leaves Draw.

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
shortcut and its uses on one line with semicolons, or on several
lines with Shift+Enter. A shortcut lasts for the program it is
in. When a program completes a picture, its shortcuts come along
to the next picture. Shortcuts can build on each other. N, E,
S, W, F, B, L, R and C are already commands, so they cannot
name shortcuts.

### Multiple Lines And Errors

Press Shift+Enter to type several lines. All lines run in order
when you press Enter. If a command is unknown, nothing runs: the
bad letter turns red, a short message appears, and you hear a
soft sound so you can fix it.

## What Happens

The robot turns and moves with a short animation. Moving forward
leaves a bright trail. Moving backward leaves no trail. Every
run starts on a clean canvas with the robot at its start, so
the drawing shows what your whole program does.

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

C runs silently. Commands after it continue on the fresh canvas.
Every run already starts on a fresh canvas; C clears one in the
middle of a program.

## Moving Between Pictures

In Draw the picture, use the same level commands as Maze:

  .  — go to the next picture
  ,  — go back one picture

Put a number in front to jump several: 3. moves three pictures
forward and 2, moves two back, stopping at the first or last
picture. A jump to another picture opens a fresh copy of it
with an empty text field. The moves after the jump do not run,
and no shortcut your program defines comes along: only a
completed picture saves shortcuts. A jump that stays on the
same picture, such as , on the first one, starts it over.

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
