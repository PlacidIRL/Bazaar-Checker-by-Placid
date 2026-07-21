# Bazaar Checker by Placid

WotLK 3.3.5 addon for Project Ascension. Keeps a wishlist of items you're
after, then instantly scans the Bazaar vendor's entire rotating stock (all
~11 pages / ~106 slots) the moment you open its window, and alerts you if
anything on your wishlist is available.

## Install

Folder name must stay `Bazaar Checker by Placid` inside your
`Interface\AddOns` directory (this folder already matches, so you can copy
it there as-is).

## Slash commands

- `/bazaar` or `/bzc` — toggle the wishlist window
- `/bazaar <itemID or item link>` — add an item to your wishlist directly
- `/bazaar rescan` — manually re-scan the currently open vendor (mainly
  useful for troubleshooting)

## Managing your wishlist

There are three equivalent ways to reach the same wishlist (adding/removing
in one instantly updates the others):

1. **Esc -> Interface -> AddOns -> Bazaar Checker** — a panel embedded in
   the standard Blizzard AddOns options list.
2. The standalone popup window (`/bazaar`, `/bzc`, or the minimap button).
3. `/bazaar <itemID or item link>` typed directly.

In any of these: **shift-click** an item (from your bags, a tooltip, etc.)
into the add box to insert its link, or just type a numeric item ID, then
hit **Add** or Enter. Every wishlisted item is listed with its icon and
colored name; click the small red icon on the right of a row to **remove**
it.

The popup window can also be dragged to move it; position is remembered
between sessions.

## How scanning works

- Triggers automatically on `MERCHANT_SHOW` (the moment you open a vendor
  window) — no need to click through pages, since `GetMerchantNumItems()` /
  `GetMerchantItemLink()` already cover the vendor's full stock regardless
  of which page is currently displayed. The scan is a single instant pass.
- To avoid pestering you at every random vendor in the game, a vendor only
  counts as "the Bazaar" if **either** its NPC name matches
  `BazaarChecker.VENDOR_NAME` ("Tiraxis" by default, see `Core.lua`) **or**
  at least one of its items is actually priced in Bazaar Tokens (item ID
  `975001`). Either signal alone is enough - this way a vendor still gets
  recognized even if the extended-cost API doesn't behave as expected.
  Ordinary vendors are silently ignored.
- **Found:** for each wishlisted item currently in stock, you get a chat
  message, a sound, and a popup showing the item link, its icon, and a
  **Buy** button that purchases it on the spot. If the item's Bazaar Token
  price is readable through the standard cost API it's shown with the token
  icon; otherwise (see note below) the vendor page number is shown instead,
  so you can find it fast and check the exact price there.
- **Not found:** if it's confirmed to be the Bazaar vendor but none of your
  wishlisted items are currently available (stock rotates), you get a single
  chat message saying so.
- Items that are sold out for the current rotation (`numAvailable == 0`)
  are treated as unavailable and won't trigger an alert.
