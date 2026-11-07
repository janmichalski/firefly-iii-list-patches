# Firefly III transaction list patches

Two small template patches for [Firefly III](https://github.com/firefly-iii/firefly-iii) 6.7.9 that make transaction lists usable on laptop-sized screens:

1. **Month boxes below the list.** The monthly summary boxes (for example "January · Transactions 42") no longer cover the right side of the transaction table.
2. **Column chooser.** A gear icon in the table header lets you hide columns you don't need, such as the running balance, budget or category.

They are useful if you run Firefly III yourself with Docker and look at it in a browser window that is not very wide.

## What the problem looks like

You open *Transactions → All transactions* on a 14–16" laptop, or in a browser window about 1000–1400 px wide. Bank imports often come with long descriptions, like `EXAMPLE STORE SP. Z O.O. 01PL CARD-PAYMENT REF 4815162342`, and those make the table wider than the space it is given. The table runs under the column of month boxes on the right, so the month boxes cover the last columns: category, budget, the *Actions* button and the selection checkbox. You can't read them, and you can't click them.

After patch 1 the table takes the full width of the page and the month boxes sit in a row underneath it. After patch 2 you can click the gear in the table header and untick the columns you don't use, so the table stays narrow enough to fit without scrolling.

## What does this fix in everyday use?

- **Patch 1** fixes the overlap on the four transaction list pages: withdrawals, deposits, transfers and all transactions. Other pages with month boxes keep the side-by-side layout: account, category, tag, "without category" and "without budget". On those pages patch 2 still stops the overlap, because there the table scrolls horizontally inside its own card instead.
- **Patch 2** applies to every page that uses the standard transaction list. That includes accounts, categories, budgets, tags, bills, recurring transactions and search. You can hide the running balance, date, source account, destination account, category and budget. The description, amount, *Actions* and the checkbox always stay visible.
- Your column choice is saved in the browser (`localStorage`), not in Firefly III. It applies to all lists in that browser. On another device or browser you set it again.
- Nothing changes in your data. Both patches only change how pages are drawn.

## Upstream status

The overlap is a known Firefly III bug in the new layout introduced with 6.7.x:

- [firefly-iii/firefly-iii#13159 – Month Filters overlapping on the transaction listing](https://github.com/firefly-iii/firefly-iii/issues/13159): closed, with a pointer to the discussion below. The reporter shows the same problem on the demo site, caused by long descriptions.
- [Discussion #12746 – New UI feedback](https://github.com/orgs/firefly-iii/discussions/12746): the maintainer's feedback thread for the new layout.

Users have asked for column customisation several times:

- [firefly-iii/firefly-iii#12268 – Customizable columns in transaction list view](https://github.com/firefly-iii/firefly-iii/issues/12268): closed as a duplicate of other open requests.
- [firefly-iii/firefly-iii#6304 – Transactions](https://github.com/firefly-iii/firefly-iii/issues/6304): tracking issue for the transaction list in the new layout.

These patches were not submitted upstream. They were written with AI assistance, and the Firefly III contribution policy does not accept AI-assisted contributions. Check the issues above before you install: a newer Firefly III release may already fix the overlap.

## How it works

Both patches replace one Blade template each inside the official `fireflyiii/core` image, using read-only Docker bind mounts. You don't need your own image, and no Firefly III source is changed on disk.

| Patch | File replaced in the container | Change |
|---|---|---|
| 1 | `resources/views/transactions/index.blade.php` | The list column becomes full width. The month boxes move to their own row below it, as a responsive grid (`repeat(auto-fill, minmax(12rem, 1fr))`). |
| 2 | `resources/views/components/lists/groups-large.blade.php` | Adds the gear menu and a small script that hides cells with a matching `data-ff-col` attribute and recalculates `colspan` for pagination and split-transaction rows. Wraps the table in Bootstrap's `table-responsive` so it scrolls instead of overflowing. Opens the *Actions* dropdowns with Popper's `fixed` strategy, so the scroll container doesn't clip them. |

The exact changes against the 6.7.9 originals are in [`patches/`](patches/). You can use the patches on their own: mount only the file you want.

## Requirements and tested version

- Firefly III **6.7.9** (`fireflyiii/core`), Docker Compose deployment, default layout.
- Tested on a Raspberry Pi (ARM64) with Firefox on a desktop, window about 1400 px wide. The overlap is gone, the month boxes are shown below the list, columns hide and show again, and the choice survives a page reload.
- Both patched templates compile with Firefly III's Blade compiler, and the result passes `php -l`.
- **Not tested:** other browsers, phones, every page that uses the list, and hiding columns on a list that contains split transactions. That last one is handled in the code but was not checked visually.

## Installation

1. Clone this repository next to your Firefly III `compose.yaml`:

   ```bash
   git clone https://github.com/janmichalski/firefly-iii-list-patches.git
   ```

2. Check that your image still contains the original templates these patches were made from:

   ```bash
   firefly-iii-list-patches/scripts/check-upstream.sh fireflyiii/core:version-6.7.9
   ```

   Use the same image reference as your `compose.yaml`. Continue only if both lines say `OK`.

3. Add the volume lines from [`compose.override.example.yaml`](compose.override.example.yaml) to the Firefly III app service. You can also save the file as `compose.override.yaml`. Keep `:ro` at the end of each line.

4. Recreate the app container. This only restarts the web app, not the database:

   ```bash
   docker compose up -d app
   ```

## Checking that it works

1. Open *Transactions → All transactions* and reload the page with `Ctrl` + `Shift` + `R`.
2. The month boxes are below the table, not next to it.
3. Click the gear in the top-right corner of the table header and untick *Budget*. The column disappears right away, and it stays hidden after a reload.
4. Open the *Actions* menu on the last row. The whole menu is visible.

## Before every Firefly III upgrade

A mounted file always wins over the one in the image. If upstream changes either template, mounting the old patched file would hide those changes, and pages could break. Run the check against the **new** image before you upgrade:

```bash
firefly-iii-list-patches/scripts/check-upstream.sh fireflyiii/core:<new-version>
```

- `OK` for both files: keep the mounts.
- `CHANGED`: remove the mounts first (see below), upgrade, and check whether upstream fixed the problem. If it didn't, re-apply the changes from `patches/` to the new originals.

## Rollback

Remove the two volume lines, or delete `compose.override.yaml`, and recreate the container:

```bash
docker compose up -d app
```

Firefly III then uses its own templates again. The column choice stays in browser storage but no longer does anything. You can clear it in the browser console:

```js
localStorage.removeItem('ff3.transactionList.hiddenColumns')
```

## License

The patched templates are derived from Firefly III, which is licensed under the GNU Affero General Public License v3.0. This repository uses the same license; see [LICENSE](LICENSE). This project is not affiliated with or endorsed by Firefly III.
