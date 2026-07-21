# Bazaar Checker by Placid

A World of Warcraft (3.3.5) addon for Project Ascension that watches a wishlist of items and alerts you the moment any of them are in stock at the Bazaar vendor (Tiraxis, The Ethereal Bazaar), which sells items priced in Bazaar Tokens. It scans the vendor's full stock automatically when you open its window and surfaces matches with a chat message, sound, popup, and one-click Buy button.

## Install
Folder name must stay `Bazaar Checker by Placid` inside your `Interface\AddOns` directory (this folder already matches, so you can copy it there as-is).

## Slash Commands
- `/bazaar` or `/bzc` — toggle the standalone wishlist window
- `/bazaar rescan` or `/bzc rescan` — manually re-scan the currently open vendor
- `/bazaar <item link or item ID>` (or `/bzc ...`) — add that item to your wishlist directly
- `/bazaar` or `/bzc` with no argument and not "rescan" — opens/closes the main wishlist window

## Features
- Wishlist of items (by item ID), addable via shift-click item link, typed item link, or numeric item ID
- Automatic scan of the vendor's entire stock (all pages, not just the visible one) on `MERCHANT_SHOW`
- Vendor recognition by NPC name ("Tiraxis") or by detecting Bazaar Token (item ID 975001) pricing on its stock, so ordinary vendors aren't scanned
- Alert popup listing each matched item's icon, name/link (with tooltip and shift-click-style linking), price (Bazaar Token cost, copper price, or vendor page number as fallback), and a Buy button that repurchases the item's current merchant slot at click time
- Chat message and configurable alert sound on match; chat message when the vendor is confirmed but nothing wishlisted is in stock
- Skips items that are sold out for the current stock rotation
- Standalone draggable wishlist window with a remembered screen position, plus an equivalent panel embedded under Esc -> Interface -> AddOns
- Draggable minimap button (toggles the wishlist window, position remembered) that can be hidden via settings
- Options: alert sound on/off, alert sound choice, minimap button visibility/position
- Saved-variable persistence of wishlist and settings (`BazaarCheckerDB`)
- Defensive `pcall` wrapping around scanning, alert popup rendering, and wishlist UI refresh, so a Lua error prints a visible chat message instead of failing silently

## Bug Fixes vs. the Original
This is an original addon written for Project Ascension — not a modification of an existing addon.
