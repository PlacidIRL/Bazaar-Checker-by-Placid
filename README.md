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

## If nothing seems to happen

If `/bazaar` (or the AddOns panel) doesn't open anything and there's no
error text on screen, WotLK hides Lua errors by default, so a broken addon
often looks like it's just doing nothing. To see what's actually happening:

1. Type `/console scriptErrors 1` then `/reload` — this turns on-screen Lua
   error messages on, so any load error becomes visible.
2. Check the AddOns list at the character-select screen (bottom-left
   **AddOns** button) — confirm `Bazaar Checker by Placid` is checked/enabled,
   and if it's grayed out, tick **Load out of date AddOns**.

`RefreshWishlistUI`, `ShowFoundItems`, and `ScanVendor` are all wrapped in
`pcall`, so a crash in any of them prints a red `[Bazaar Checker] ... error:`
line to chat instead of just doing nothing - if you ever see one of those,
paste it back for a precise fix rather than needing `scriptErrors` at all.

## Notes / things to double-check in-game

- On this server, the Bazaar Token price shown on vendor rows isn't reachable
  through `GetMerchantItemInfo`'s price field, `GetMerchantItemCostInfo` /
  `GetMerchantItemCostItem` (both return 0), or even the item's tooltip —
  confirmed by testing, including on a guaranteed-loaded first-page item. It's
  most likely rendered by a custom client/server modification rather than
  Blizzard's native vendor cost system, so it isn't something any addon's Lua
  can currently read. The popup shows the vendor page number instead (see
  `Scanner.lua`'s `page` calculation) so you can find the item and check its
  exact price there. `GetBazaarTokenCost` in `Scanner.lua` is left in place in
  case a future server update exposes it properly - it'll be used
  automatically the moment it starts returning real values.
- The Bazaar Token item ID is assumed to be `975001` (per Project
  Ascension). Update `BazaarChecker.BAZAAR_TOKEN_ITEM_ID` in `Core.lua` if
  that ever needs to change.
- The vendor itself is recognized by name (`Tiraxis`, The Ethereal Bazaar,
  NPC ID 48039) as the primary signal, with token-priced stock as a backup
  signal. If the vendor's name is ever different in-game, update
  `BazaarChecker.VENDOR_NAME` in `Core.lua`.
- `RefreshWishlistUI` is wrapped in `pcall`, so if the wishlist window/panel
  ever gets stuck not reflecting an add/remove, watch chat for a red
  `UI refresh error:` message — that pinpoints the exact Lua error instead of
  failing silently.
