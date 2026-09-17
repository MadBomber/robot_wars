# RobotWars — Core Rules

Numbered for reference. All rules below are decided (proposed defaults
approved by Dewayne 2026-09-16). Two sensing details remain open under
rule 35. See `notes.md` for the discussion history behind each rule.

## Board and Setup

1. The game is played on a 2D board divided into squares. The board is
   bounded by walls.
2. Board size is set at the start of the game.
3. Each robot player is represented by an icon on the board.
4. Only one robot can occupy a square at a time.
5. Every robot starts the game with 100 life points.
6. Starting positions are randomized. No two robots start on the same
   square.

## Turns and Actions

7. The game is turn based. All robots act simultaneously; results are
   resolved between turns.
8. Each turn, a robot chooses exactly one action: **stay**, **move**,
   **attack**, or **defend**.
9. A move is one square in any of the 8 directions (like a chess king).
10. A successful move costs 1 life point.
11. A turn in which the robot does not move adds 1 life point. Only a
    **stay** earns this point; attack and defend turns neither pay the
    move cost nor earn the rest point.
12. There is no upper limit on life points.

## Conflicts (robots on the same square)

13. A conflict occurs when two or more robots are on the same square at
    the end of a turn.
14. One random number between 1 and 10 is generated per conflict. That
    same value is subtracted from the life points of every robot in the
    conflict.
15. The robot with the highest remaining life points wins: it stays on
    the square and marks it as its own.
16. A tie for highest life is the same as a loss. No robot wins, and the
    square ends the turn unowned.
17. Every robot that does not win returns to the square it came from.
18. If a returning robot finds another robot in its origin square, a
    second conflict is resolved there under the same rules.
19. A robot that loses a second conflict in the same resolution is
    placed on an available adjacent square: one of the 8 neighboring
    squares that is unoccupied and not owned by another robot.
    The neighborhood is centered on the square the robot failed to
    return to, and when several neighbors are available one is chosen
    at random.
20. If no adjacent square is available, the twice-defeated robot dies.

## Illegal Moves

21. Attempting to move off the board, or into a square owned by another
    robot, is a solo conflict: the robot loses a random number of life
    points and stays where it was. The random number uses the same 1–10
    range as rule 14.

## Territory

22. Winning a conflict on a square makes the winner the owner of that
    square (conquest).
23. A robot that occupies the same square for 3 consecutive turns owns
    the square (occupation).
24. No robot may enter a square owned by a different robot. The owner
    may occupy its own squares freely.
25. When a robot dies, all squares it owned are released and become
    unowned.

## Ranged Combat

26. A robot may attack any square on the board, committing a number of
    points up to its current life as the attack's strength.
27. Ranged combat is resolved after the turn. If a robot is in the
    target square at resolution time, it loses the full committed
    amount. If the square is empty, the attack misses and has no effect.
28. Attacking costs the attacker nothing. Committed points are projected
    force, not spent life. An attack on an undefended robot is free.
29. A robot may defend, committing a number of points up to its current
    life.
30. Defense is counter-fire: every robot that attacks a defender that
    turn is hit back for the defender's full committed amount. Multiple
    attackers each take the full amount.
31. Defense does not reduce incoming damage. The defender still takes
    the attacker's full committed amount.
32. A robot that defends but is not attacked that turn loses 1 life
    point.

## Sensing

33. A robot's only perception of the board is the map of owned squares.
    A robot can never see another robot's position.
34. Being attacked does not reveal the attacker. A robot knows the
    damage it took, not where it came from.
35. A robot knows its own position, its own life total, and the
    outcomes of events it takes part in (conflicts fought, moves
    bounced, damage taken). Still open: whether the ownership map
    identifies which robot owns a square, and whether deaths are
    announced.

## Death and Victory

36. A robot dies when its life points reach 0 or less.
37. A robot also dies by displacement under rule 20, regardless of its
    life total.
38. Mutual kills are allowed. All deaths in the same resolution stand.
39. The last robot alive wins. If the last robots die in the same
    resolution, the game is a tie: no winner, no loser.

## Turn Resolution Order

40. Each turn resolves in this sequence:
    1. All robots declare their actions blind and simultaneously.
    2. Moves are executed; move costs and rest gains are applied.
    3. Conflicts on shared squares are resolved, including return
       conflicts and displacement (rules 13–20).
    4. Ranged attacks and counter-fire are resolved against post-move
       positions (rules 26–32).
    5. Deaths are processed; owned squares of the dead are released.
    6. Occupation streaks are updated; ownership by occupation vests.
