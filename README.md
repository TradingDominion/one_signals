# ONE_signals

This is a tool that will allow you to visually display signals stored within a CSV file.

The pop-up window remains always on top of other windows.

![](https://i.imgur.com/HD8wklX.png)

The CSV file needs to have the first column being the date, in the format of yyyy-MM-dd, 
and can then have up to 3 extra columns which will be used to display any signal information.

Sample CSV file contents:
```
Date,STFSv3aggr,DASTFSv2
2000-01-03,0,-4
2000-01-04,-1,-2
```

By selecting the "Link with ONE" checkbox, any time you click on "Prev Date" or "Next Date" then the relevant
hotkeys will be sent through to OptionNet Explorer (ONE) in order to shift the date one day backward/forward.
