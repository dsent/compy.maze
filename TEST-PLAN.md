# Maze And Draw Device Test Plan

Use the Compy device harness so the deployed project has a
recorded source identity and the previous project is backed up.

## A. Maze Regression

1. Launch Maze and confirm the three-item maze menu appears.
2. Open Drive the robot and complete one direct-control level.
3. Toggle the grid with the Menu key in both directions. Click
   on the maze and confirm the grid stays as it is.
4. Return to the menu with Esc. Open Drive the robot again and
   hold Esc for two seconds: the maze menu shows and stays.
5. Open Plan a path, enter a short plan, run it, and retry it.
   Run it again and press Esc while the robot moves: the robot
   returns to the start and the plan stays.
6. Return to the menu with Esc and open Plan a path again, so
   the plan can be edited (a won level locks it). Enter keys
   without pressing Enter, press Shift+Esc and confirm the
   plan stays; press Esc and confirm the plan empties and the
   level stays; enter keys and hold Esc for two seconds: the
   plan empties and the level stays; press Esc on the empty
   plan and confirm the maze menu.
7. Open All mazes and press `.` three times to reach Maze 4,
   the first level with the command field (the first three
   are direct-control). Run `n`, and confirm the robot, trail,
   compass, command echo, sound, and timing, and that the field
   is away while the robot moves and while "Goal not reached"
   shows. Press Tab and confirm the field is back with `n`.
   Run `n` again and press Esc at the message: the field is
   back with `n` again. Run `2n2w`; while the robot
   moves, type `e` and press Enter and confirm nothing
   changes; press Esc and confirm the robot stops where it is
   and the field holds `2n2w`; press Esc and confirm the field
   empties; press Esc and confirm the maze menu; return to
   Maze 4.
   Type a command without pressing Enter, press Shift+Esc,
   Alt+Esc and Alt+Shift+Esc, and confirm the text and the
   level stay. Press Esc and confirm the field empties and the
   level stays; press Esc again and confirm the maze menu.
   Back on that level, type `<`, press Enter, and confirm it
   is refused as invalid input. Replace the text with `y=e;.`
   and run it; on Maze 5 run `y` and confirm "Unknown command:
   Y": a jump carries no shortcut.
   Still on Maze 5, win with `x=n;xe2n2en` and confirm the
   celebration banner shows with no column Tab hint. Type
   `y=e;n` and press Enter: the banner goes and a `[Tab] next`
   hint appears above the legend. Wait for the miss banner,
   press Tab once to dismiss it (`n` returns to the field and
   the hint stays), then press Tab again to advance to Maze 6.
   Run `y` (refused), then `x` (moves north): only the last
   winning program's shortcuts carried. Press Esc to empty the
   field and Esc again for the maze menu.
8. At the maze menu, press Shift+Esc, Alt+Esc and
   Alt+Shift+Esc and confirm the menu stays; press Esc and
   confirm Maze leaves for the console.
9. Launch Maze again, open a track, leave through Ctrl+Q and
   confirm the console is usable.

## B. Draw Acceptance

1. Launch Draw and confirm the menu lists Free draw first and
   Draw the picture second.
2. Open Free draw. Run `3e` and confirm three steps east and
   that the field is away while the robot moves and holds `3e`
   again when it stops. Replace the field's text with `2n` and
   run it, and confirm only two steps north from the start cell
   show. Replace the text with `x=3e` and run it, then replace
   it with `x` and run it, and confirm "Unknown command: X";
   replace it with `x=2e;x n x`, run it and confirm it draws.
   Replace it with `3e;c;2n`, run it and confirm only two steps
   north from the start cell show. Replace it with `3e`; when
   the robot stops, press Esc and confirm the field empties and
   the trail and robot stay. Type `EE`, press Shift+Esc,
   Alt+Esc, then Alt+Shift+Esc, and confirm the text stays.
   Hold Esc for two seconds and confirm the field empties and
   Free draw stays. Run `7n7s7n7s`; while the robot moves, type
   `e` and press Enter and confirm nothing changes; press Esc
   and confirm the robot stops where it is, the drawing stays
   and the field holds `7n7s7n7s`; press Esc and confirm the
   field empties; press Esc and confirm the draw menu; open
   Free draw again.
3. Confirm Free draw has the original 8x8 canvas, right-side
   compass, bottom-left start, and soft edge.
4. Type `<` in Free draw, press Enter, and confirm it is
   refused as invalid input. Press Esc to empty the field, then
   hold Esc for two seconds: the draw menu shows and stays.
5. Open Draw the picture. Confirm Picture 1/20 is Line and its
   target appears on an 8x8 grid above the compass with a green
   start marker at the same coordinates as the playing field.
6. Toggle the faint field hint off and on with the Menu key.
   Click on the canvas and confirm the hint stays as it is.
7. Complete Line with `5E`; confirm the completion stripe shows
   the Tab key glyph, the column shows no Tab hint, and the
   field is back and empty. Type `5E` and press Enter in place
   of Tab: the program runs again from a clean start and the
   stripe comes back. Type `X=5E;X` and run it to win again,
   then type `Y=3E;Y` and run it: the stripe goes and `[Tab]
   next` appears above the legend without covering the preview
   or legend. Type `Q` (refused), confirm the hint stays, then
   press Tab and confirm `X` runs on Picture 2/20 while `Y` is
   refused; go back with `,`.
8. Complete Line again with `5E`, then press Tab. Confirm
   Picture 2/20 starts with its declared hint
   default, an empty field and a fresh trail at its own start
   point. Run a wrong program, then a corrected one, and confirm
   the corrected run starts clean.
9. Run `.` and `,` to confirm next/previous navigation, then
   use a counted jump and confirm first/last clamping. Run
   `y=s;.`, then `y` on the next picture, and confirm "Unknown
   command: Y": a jump carries no shortcut.
10. Confirm Pictures 1-7 complete without retracing. Complete
   T with `4W2E5S` and confirm retracing is accepted.
11. On a hint-off task, toggle the hint on, draw an extra edge,
    and confirm it does not complete; run the extra edge, `C`
    and the target's route as one program, and confirm it
    completes.
12. Read every target once at Picture 1-20 and confirm each is
    recognizable as its name at preview scale.
13. Exercise a middle task and Picture 20/20 Dog, checking
    smooth animation, quiet sounds, and editor use. On the
    middle task, run a program that does not complete it. When
    the robot stops, press Esc and confirm the field empties
    and the trail and robot stay.
14. Complete Dog, press Tab, and confirm Draw returns to its
    menu.
15. Return to the menu from a picture with Esc on an empty
    field. Open Draw the picture again and hold Esc for two
    seconds on an empty field: the draw menu shows and stays.
16. At the draw menu, press Shift+Esc, Alt+Esc and
    Alt+Shift+Esc and confirm the menu stays; press Esc and
    confirm Draw leaves for the console.
17. Launch Draw again, open Free draw, leave through Ctrl+Q and
    confirm the console is usable.
