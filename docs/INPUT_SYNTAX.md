# Input syntax

Type into the timer field and press Return. Case, extra spaces, commas and the word "and" are ignored
(`1 hour and 30 minutes` = `1h 30m`). Only plain digits `0-9` and `.` as the decimal point are understood.

## Durations (start a countdown)

| You type | You get |
|---|---|
| `25` | 25 minutes (a bare number means minutes) |
| `1.5` | 1 minute 30 seconds |
| `90s`, `90 sec`, `90 seconds` | 90 seconds |
| `10m`, `10 min`, `10 minutes` | 10 minutes |
| `2h`, `2 hr`, `2 hours` | 2 hours |
| `2h 30m`, `2h30m`, `1h, 5m, 10s` | units can be combined, in any order, each at most once |
| `1.5h` | 1 hour 30 minutes (decimals are fine) |
| `1:30` | 1 minute 30 seconds (`M:SS`) |
| `1:02:03` | 1 hour 2 minutes 3 seconds (`H:MM:SS`) |

Seconds and minutes after a colon must be below 60. A timer lasts 1 second to 99:59:59.

## Clock times (count down to a time of day)

| You type | You get |
|---|---|
| `5pm`, `5 PM`, `5p`, `at 5pm` | the next 5:00 pm |
| `5:30pm` | the next 5:30 pm |
| `noon`, `midnight` | the next 12:00 / 00:00 |
| `at 17:30` | the next 17:30 (24-hour clock needs `at`) |
| `at 9` | the next 09:00 |

"Next" means later today if the time is still ahead, otherwise tomorrow. `12am` is midnight and `12pm` is noon.
Without `at`, `17:30` is a duration (17 minutes 30 seconds), not a time of day.
A time that does not exist because clocks jump forward is moved to the first valid moment after the jump.

## Adjustments (change a running timer)

Start with `+`, `-`, `add`, `plus`, `subtract` or `minus`, followed by a duration. A bare number is minutes.

| You type | You get |
|---|---|
| `+5m`, `+ 5 min`, `+5`, `add 5 min` | add 5 minutes |
| `plus 30s` | add 30 seconds |
| `-1h`, `subtract 2m`, `minus 30 seconds` | subtract time |

Adjustments take the same duration formats as above, but not clock times.

## Messages you may see

| Message | Why |
|---|---|
| Type a time, like 25 or 1h 30m | the field was empty |
| Try 25, 1h 30m, 1:30, 5pm or +5m | the text is not in any format above |
| Timers can be 1 second to 99 hours | zero, or longer than 99:59:59 |
| That's not a valid time of day | for example `13pm`, `5:60pm` or `at 24:00` |
