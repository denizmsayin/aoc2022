# Advent of Code 2022 with Lua 5.4 and LuaJIT

I wanted to do this year's AoC using Lua to get some experience with it, since it is embedded in and used to configure a whole bunch of programs, of which [neovim](https://neovim.io/) is the most important for me. 

It was a fun and very simple language to learn, but perhaps not very well suited to AoC. I'll compile my thoughts about it after AoC ends.

I usually tried to make my solutions _fast_ (< 50ms). If some are slower right now, they're definitely on my mind! Speed usually happens coincidentally since most problems are straightforward, but some days did require me to modify my initial straightforward approaches. I compiled some notes about those below. 

I initially started with the [Lua 5.4](https://www.lua.org/manual/5.4/manual.html) interpreter to keep things simple and did not use the legendary [LuaJIT](https://luajit.org/luajit.html). After day 15 however, I integrated LuaJIT as well since any Lua I use in real life will probably be LuaJIT or some derivative. This was pretty fun, since I got to compare performances between the two, make my own small compatibility library under `lib/compat.lua` as an exercise, and keep compatibility in mind in general. I'll talk more about it in my eventual Lua comments.

__NOTE:__ I cheesed my way through day 17 part 2 with some manual searching and calculations (using `calc.py`) because the solution I used does not generalize to the sample input. I'll have to think about it some more.

## howtospeed

__NOTE:__ Times I mention here are in Lua 5.4 unless specified otherwise.

### Day 11

The straightforward implementation of this one in which every monkey had a list of items took around 120ms for the 10,000 steps in part 2.

To make this a bit faster, I flipped the representation: All the items are held together in a global list. For each item, I run a big loop that applies each operation and moves the item through the monkey graph, tracking which monkey it belongs to with a single integer. The round count is increased every time the item has to move backwards in monkey indices. This sped up execution by a factor of 2-3 because we don't keep moving items around different arrays; each item completes all 10,000 without moving _at all_. 

Don't know how I could really speed it up further, except for trying to _compile_/_fuse_ some of the paths in the monkey graph, which seems quite difficult.

### Day 12

For part 2, instead of running a BFS starting from each `a` and taking their minimum, it is more efficient to run a single exhaustive BFS in reverse starting from `E` recording the minimum distance to each cell. Blazing!

### Day 14

After going through some less inspired approaches, I ended up using a simple "drop 1 grain at a time" approach, which ran in a few hundred ms. Speeding this up is not too hard, because making the next sand grain start from scratch every time is wasteful. Instead, we can put the next sand grain at the position the last sand grain was at just before coming to a rest and move from there. Keeping a stack of previous positions and popping from it to get the initial position of the next sand grain does the trick!

### Day 15

For part 1, I used a "clever" approach in which I found the 1-D `[s, e]` range each sensor _closed-off_ at the given `y=a` line based on the distance of their nearest beacon. Then, merging these ranges and using their spans to count the number of impossible positions after accounting for existing beacons was very quick, since there are few sensors and beacons. 

Unfortunately, I could not extend this approach's "cleverness" to part 2, brute-force involving applying it on each of the 400,000 rows takes several seconds. ~~I have a completely separate idea to make it fast, but it is not very simple.~~ I implemented it and it is fast! Needs some visualizations to explain though...

## Automated Tests

These are generated by `test_solutions` and appended to `readme_template.md` to complete the README, and times are reported by `time -p`. They are meant to give a rough idea of the execution time on my machine and are not very precise. 

A pre-commit [hook](https://githooks.com/) `test_hook` runs automatically after every commit and refreshes the below table. In case a test fails, the commit is aborted and I get to fix the code. Otherwise, the updated README gets staged and the commit completed.

To set up this hook after cloning the repository, you just have to link it:
```
ln test_hook .git/hooks/pre-commit
```

### ... and their results

Using: `LuaJIT 2.1.0-beta3 -- Copyright (C) 2005-2022 Mike Pall. https://luajit.org/`
```diff
+ day1	part1: OK (0.00s)
+ day1	part2: OK (0.00s)
+ day2	part1: OK (0.00s)
+ day2	part2: OK (0.00s)
+ day3	part1: OK (0.00s)
+ day3	part2: OK (0.00s)
+ day4	part1: OK (0.00s)
+ day4	part2: OK (0.00s)
+ day5	part1: OK (0.00s)
+ day5	part2: OK (0.00s)
+ day6	part1: OK (0.00s)
+ day6	part2: OK (0.00s)
+ day7	part1: OK (0.00s)
+ day7	part2: OK (0.00s)
+ day8	part1: OK (0.00s)
+ day8	part2: OK (0.00s)
+ day9	part1: OK (0.00s)
+ day9	part2: OK (0.01s)
+ day10	part1: OK (0.00s)
+ day10	part2: OK (0.00s)
+ day11	part1: OK (0.00s)
+ day11	part2: OK (0.01s)
+ day12	part1: OK (0.00s)
+ day12	part2: OK (0.00s)
+ day13	part1: OK (0.00s)
+ day13	part2: OK (0.00s)
+ day14	part1: OK (0.00s)
+ day14	part2: OK (0.00s)
+ day15	part1: OK (0.00s)
+ day15	part2: OK (0.00s)
+ day16	part1: OK (0.07s)
+ day16	part2: OK (3.19s)
+ day17	part1: OK (0.03s)
+ day18	part1: OK (0.00s)
+ day18	part2: OK (0.00s)
+ day19	part1: OK (0.62s)
```
Using: `Lua 5.4.4  Copyright (C) 1994-2022 Lua.org, PUC-Rio`
```diff
+ day1	part1: OK (0.00s)
+ day1	part2: OK (0.00s)
+ day2	part1: OK (0.00s)
+ day2	part2: OK (0.00s)
+ day3	part1: OK (0.00s)
+ day3	part2: OK (0.00s)
+ day4	part1: OK (0.00s)
+ day4	part2: OK (0.00s)
+ day5	part1: OK (0.00s)
+ day5	part2: OK (0.00s)
+ day6	part1: OK (0.00s)
+ day6	part2: OK (0.00s)
+ day7	part1: OK (0.00s)
+ day7	part2: OK (0.00s)
+ day8	part1: OK (0.00s)
+ day8	part2: OK (0.01s)
+ day9	part1: OK (0.01s)
+ day9	part2: OK (0.02s)
+ day10	part1: OK (0.00s)
+ day10	part2: OK (0.00s)
+ day11	part1: OK (0.00s)
+ day11	part2: OK (0.04s)
+ day12	part1: OK (0.00s)
+ day12	part2: OK (0.00s)
+ day13	part1: OK (0.00s)
+ day13	part2: OK (0.00s)
+ day14	part1: OK (0.00s)
+ day14	part2: OK (0.01s)
+ day15	part1: OK (0.00s)
+ day15	part2: OK (0.00s)
+ day16	part1: OK (0.19s)
+ day16	part2: OK (6.83s)
+ day17	part1: OK (0.08s)
+ day18	part1: OK (0.00s)
+ day18	part2: OK (0.01s)
+ day19	part1: OK (2.23s)
```

