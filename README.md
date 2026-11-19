# Compy maze + draw — source

This is the single source tree for two Compy programs:

- **maze** — guide a robot through a maze (the original game);
- **draw** — free drawing plus picture-copying tasks on the
  same command core.

A Compy project is a flat, self-contained folder launched by
`run("name")`, with no runtime sharing between projects. So
this tree is **not run directly**: the `.compy/build` step
copies the shared core plus each program's own files into two
separate project folders.

    .compy/build <out-dir>   # -> <out-dir>/maze and /draw

The host build invokes `.compy/build` as
`cd <repo> && .compy/build <out-dir>`. Which programs ship is
governed by an external manifest (two entries, `maze` and
`draw`, sharing this repo) — it lives in the build system, not
here.

See **BUILD.md** for the file layout and the full procedure.
The child-facing readme for each program is `README_maze.md`
/ `README_draw.md`; the build emits each as that folder's
`README.md`.
