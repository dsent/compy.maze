# Maze And Draw Device Test Plan

Use the Compy device harness so the deployed project has a
recorded source identity and the previous project is backed up.

## A. Maze Regression

1. Launch Maze and confirm the three-item maze menu appears.
2. Open Drive the robot and complete one direct-control level.
3. Toggle the grid with the Menu key in both directions.
4. Return to the menu with Esc. Open Drive the robot again and
   hold Esc for two seconds: the maze menu shows and stays.
5. Open Plan a path, enter a short plan, run it, and retry it.
6. Return to the menu with Esc and open Plan a path again, so
   the plan can be edited (a won level locks it). Enter keys
   without pressing Enter, press Shift+Esc and confirm the
   plan stays; press Esc and confirm the plan empties and the
   level stays; enter keys and hold Esc for two seconds: the
   plan empties and the level stays; press Esc on the empty
   plan and confirm the maze menu.
7. Open All mazes and press `.` three times to reach Maze 4,
   the first level with the command field (the first three
   are direct-control). Run one editor command, and confirm
   the robot, trail, compass, command echo, sound, and timing.
   Type a command without pressing Enter, press Shift+Esc,
   Alt+Esc and Alt+Shift+Esc, and confirm the text and the
   level stay. Press Esc and confirm the field empties and the
   level stays; press Esc again and confirm the maze menu.
   Back on that level, type `<`, press Enter, and confirm it
   is refused as invalid input.
8. At the maze menu, press Shift+Esc, Alt+Esc and
   Alt+Shift+Esc and confirm the menu stays; press Esc and
   confirm Maze leaves for the console.
9. Launch Maze again, open a track, leave through Ctrl+Q and
   confirm the console is usable.

## B. Draw Acceptance

1. Launch Draw and confirm the menu lists Free draw first and
   Draw the picture second.
2. Open Free draw. Run commands in separate submissions,
   confirm the trail and robot persist, then run C followed by
   a movement in the same program. When the robot stops, press
   Esc and confirm the field empties and the trail and robot
   stay. Type `EE`, press Shift+Esc, Alt+Esc, then
   Alt+Shift+Esc, and confirm the text stays. Hold Esc for two
   seconds and confirm the field empties and Free draw stays.
3. Confirm Free draw has the original 8x8 canvas, right-side
   compass, cumulative trail, bottom-left start, and soft edge.
4. Type `<` in Free draw, press Enter, and confirm it is
   refused as invalid input. Press Esc to empty the field, then
   hold Esc for two seconds: the draw menu shows and stays.
5. Open Draw the picture. Confirm Picture 1/20 is Line and its
   target appears on an 8x8 grid above the compass with a green
   start marker at the same coordinates as the playing field.
6. Toggle the faint field hint off and on with the Menu key.
7. Complete Line with `5E`; confirm the completion stripe shows
   the Tab key glyph.
8. Press Tab. Confirm Picture 2/20 starts with its declared hint
   default and a fresh trail at its own start point.
9. Run `.` and `,` to confirm next/previous navigation, then
   use a counted jump and confirm first/last clamping.
10. Confirm Pictures 1-7 complete without retracing. Complete
   T with `4W2E5S` and confirm retracing is accepted.
11. On a hint-off task, toggle the hint on, draw an extra edge,
    and confirm it does not complete; run C and confirm reset.
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
