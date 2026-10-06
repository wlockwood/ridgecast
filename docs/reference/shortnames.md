# Shortnames

A shortname is the compact label RidgeCast draws for a node when
**View → Node Labels → Short Names** is on. It also appears in the network
list, the node editor title, and exported map labels.

If you type a shortname in the node editor, RidgeCast always uses it. If you
leave it blank, RidgeCast generates one from the node's name. The generated
shortname appears as grey hint text in the editor's **Shortname** box.

## Settings

All three settings are near the bottom of the **Settings** window.

| Setting | What it does |
| --- | --- |
| **Target Shortname Length** | The longest a generated shortname should be, counted in characters as you see them. An emoji or an accented letter counts as one. |
| **Shortname Fallback** | What to do if approved abbreviations can't shorten a name enough. See [Fallback](#fallback). |
| **Shortname Region** | Turns on local place aliases for one region. See [Place aliases](#place-aliases). |

RidgeCast remembers these settings with your other map display preferences.
They apply to every network and are not saved inside network files.

## How a name is shortened

RidgeCast tries the steps below in order. It stops as soon as the name fits,
so a name that already fits is never changed.

1. **Tidy spaces.** Leading and trailing spaces are dropped, and runs of
   spaces become one.
2. **Remove spaces between words.** `Cedar Creek` becomes `CedarCreek`.
   Letter case is kept as written.
3. **Apply approved abbreviations.** `Mountain` → `Mtn`, `Creek` → `Crk`,
   `Repeater` → `Rpt`, `North` → `N`, `Highway` → `Hwy`. A word only shrinks
   when the whole word matches, so `Northgate` is not touched.
4. **Apply place aliases** for the chosen **Shortname Region**, such as
   `Olympia` → `Oly`.
5. **Fallback**, if you chose one. Ordinary words are then shortened letter
   by letter.

When more than one abbreviation could apply, the one that saves the most
characters goes first. Ties go to the word nearer the start.

For example, with the Shortname Region set to Washington,
`Olympia North Mountain Repeater Alt 12` passes through
`OlympiaNorthMountainRepeaterAlt12`, `OlympiaNorthMtnRptAlt12` and
`OlympiaNMtnRptAlt12`, and reaches `OlyNMtnRptAlt12`. That is 15 characters,
so it fits a target of 15.

A smaller target only ever continues the same sequence. Lowering the target
never makes RidgeCast undo an abbreviation or choose a different one.

## What is never changed

These parts are kept exactly as written, so the shortname still identifies the
right site:

- **Numbers.** This includes leading zeros, decimals, signs and fractions:
  `007`, `1.2`, `-12`, `1/2`.
- **Amateur radio callsigns**, kept as one unit in every common written
  form:
  - any capitalization (`W7ABC`, `w7abc`)
  - special-event and digit-first prefixes (`K7A`, `4X1AB`, `2E0ABC`)
  - location prefixes and portable suffixes after a slash (`VE7/W7ABC`,
    `W7ABC/P`, `/M`, `/MM`, `/AM`, `/QRP`, `/7`)
  - APRS SSIDs from 0 to 15 (`W7ABC-9`)
  - slashed zeros, whether typed as `Ø`, `∅`, `⌀` or a zero with a
    combining slash (`KØABC`)
  - full-width characters (`Ｗ７ＡＢＣ`)

  A callsign always keeps a space between itself and the words, numbers and
  slashes around it.
- **Other letter-and-digit codes**, such as `Node12` and `v1.2`.
- **The word `Alt`**, in any capitalization. It must stand alone as its own
  word, so `Saltwater` doesn't count.
- **Directions.** `North` can become `N` and `Northeast` can become `NE`, but
  a direction is never dropped, and `NE` is never cut down to `N`.
- **Abbreviations you already typed.** For example `PDX`, `Mtn`, `Rpt` and
  all-capital codes are never expanded or shortened further.
- **Words in other scripts.** No English rules are applied to them.
- **Punctuation.** Only spaces are ever removed.

Some spaces always stay, so separate things don't merge into one:

- Between two numbers: `Repeater 1 2` never becomes `Repeater12`.
- Between two directions: `N E` never becomes `NE`.
- Next to a call sign or code: `W7ABC 12` stays as it is.

Separately written emoji or flag symbols are never joined into a different
symbol.

## When a name can't fit

Sometimes even the shortest approved form is longer than the target. With no
fallback, RidgeCast then shows that shortest form, longer than the target,
rather than cutting the name somewhere unrecognizable. The node editor shows
a note under the Shortname box when this happens. To fix it, type your own
shortname, raise the target, or choose a fallback.

## Fallback

| Choice | Effect |
| --- | --- |
| **None (show longer name)** | The default. Only approved abbreviations are used. |
| **Clip Word Endings** | Trims the last letter off the longest ordinary word, one letter at a time. `Cougar Lookout` at a target of 8 becomes `CougLook`. |
| **Drop Vowels, Then Clip** | Removes inner vowels from the longest ordinary word first, then trims its end. `Cougar Lookout` at a target of 8 becomes `CogrLokt`. |

Both fallbacks are experimental: they have not yet been tested for whether
readers still recognize the names. They never shorten a word below three
letters. They don't touch numbers, codes, directions, abbreviations, `Alt`,
words of three letters or fewer, or words in other scripts.

## Place aliases

A place alias replaces a town name with a local short form. Each alias
applies only when you choose its region as the **Shortname Region**. RidgeCast
does not work out the region from node locations.

| Region | Alias |
| --- | --- |
| Oregon | Portland → `PDX` |
| Washington | Olympia → `Oly` |

With no region chosen, no place aliases are used.

## Where the abbreviations come from

Feature words, street types, compass directions and state codes follow
[USPS Publication 28](https://pe.usps.com/text/pub28/), written in label
capitalization (`Mtn`, not `MTN`). Only forms that read clearly in a label
are included: for example, `Hill` and `Island` are left alone. `Station`
becomes `Stn`, as in earlier RidgeCast versions, rather than the postal `STA`.

Each entry's source is recorded in `src/shortname/dictionaries/sources.json`.

US state names are only replaced with codes, such as `North Carolina` → `NC`,
when a program using RidgeCast's shortname library marks that text as the
state's name. The desktop app never does this, so `Mount Washington` keeps
`Washington`.
