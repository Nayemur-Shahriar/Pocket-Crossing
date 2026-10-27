# Pocket Crossing M14.6 — LAN Friends Play

## Status and continuity

M14.6 is implemented on the supplied **pc M14.5.zip** baseline. The saved recovery checkpoint already contained the core account, LAN, race, replication and UI components. This run restored that checkpoint rather than rebuilding Local Play. The previously interrupted late fixes and tests were absent from that checkpoint; they were recovered and freshly tested. Detailed current results are in **M14_6_VALIDATION.md**. This is a development update ready for physical LAN acceptance testing, not a claim that native Windows/Android acceptance or mobile performance has passed. **M15 has not started.**

The remaining work completed includes reliable discrete hop inputs, per-match input-sequence reset, swipe preservation across render frames, local collision feedback, remote power-up captions, overlapping name-label spacing, results-column alignment, Android discovery lock lifetime, simultaneous-disconnect handling, tests, visual inspection, resource-pack verification, documentation and the installable delta ZIP.

The source comparison confirms that all four map Resources, all six theme Resources, the Local Play controller, SaveData, player hop controller, camera, section activation and input router remain byte-for-byte unchanged. Shared damage decisions and water rider ownership received small compatibility changes; their original regression tests passed. No new campaign/maps were added.

## Files

**M14_6_FILES.txt** lists every created and modified file against the user's uploaded ZIP, including source UID companions, tests, screenshots and documentation. Existing files modified are:

- `project.godot`: adds the Account autoload.
- `scenes/main.tscn`: selects ModeGame and ModeHUD, retaining the existing scene hierarchy.
- `scripts/core/local_profiles.gd`: validates stable device IDs, renamed accounts, separate Friends times and bounded reward receipts in the existing version-1 database.
- `scripts/core/game.gd`: delegates the shared collision decision to CollisionRules; existing life-loss presentation and flow remain.
- `scripts/actors/floating_platform.gd`: tracks multiple rider owners so one departure does not release another rider.
- `scripts/world/water_support.gd`: registers/releases each adapter's own rider token, including cleanup.
- `export_presets.cfg`: enables only the two LAN/discovery permissions described below.
- `tests/map_campaign_tests.gd`, `tests/map_route_tests.gd`, `tools/capture_maps.gd`: use the preserved M14.5 startup fixture for the original profile/menu tests.

The new `scenes/m145_main.tscn` is a regression fixture preserving the old startup, not another gameplay implementation. New production scripts are modular: Device Account, Mode Game/HUD, LAN Session, Discovery, Android Discovery Lock, LAN Race, LAN Replica, LAN Config, Race Feed and Collision Rules.

## Account and migration

One normal installation uses one account. First launch asks for a username; later launches open the mode menu. The normal UI has no Add Profile or Switch Profile action. Names use 3–16 letters, digits or underscores; surrounding spaces are trimmed and display capitalization is preserved. A random 16-byte/32-hex identifier is stored locally, never derived from hardware.

The previously active M14.5 profile is adopted; when there is no active key, an existing profile is selected. Other legacy profiles remain archived in the database without a normal switching UI. Their progression is not deleted. Once a device identity exists it is reused. Rename changes the display name on the same record/ID, retaining coins, purchased maps, characters, settings and Local best times. A failed save rolls back the rename. Existing verified temporary-file/backup recovery remains in use.

Clearing app data or reinstalling can reset this offline identity. There is no online authentication, cloud recovery or hardware lock. Friends data is optional extra data in the existing database rather than a separate replacement for Local progress.

## Menu, networking and lobby

The mode menu offers **LOCAL PLAY**, **FRIENDS PLAY** and **SETTINGS**. Friends Play offers Host, Join and Back. Join shows discovered games and a secondary Enter Host IP path. Settings supports renaming and sound. Local Map Select returns to the mode menu.

| Component | Responsibility |
| --- | --- |
| `LanSession` | Exclusive ENet transport, handshake, trusted roster/map, readiness, clock, inputs, snapshots, results and disconnects |
| `LanDiscovery` | Bounded UDP query/reply discovery and stale-entry expiry |
| `LanConfig` / `resources/network/lan.tres` | Ports, capacity, snapshot rate, timeout and content version |
| `LanRace` | One authoritative world, independent racer progress, damage, powers, finish order and result rows |
| `LanReplica` | Client presentation of road vehicles, train/warnings, boats and players |
| `ModeGame` / `ModeHUD` | Mode boundaries, mobile-sized menus, lobby/countdown/race/results UI |
| `RaceFeed` | Bounded, expiring event queue with finish/disconnect priority |
| `DeviceAccount` | Stable local identity, migration, rename and once-only result settlement |

Transport is Godot ENet over UDP. The host is both server and racer; clients send cardinal hop commands, not positions, coins, scores or finish declarations. Client-to-client relaying is disabled. The host's trusted roster is sent to all clients explicitly. Ports are centrally configurable: **game UDP 42420**, **discovery UDP 42421**. Protocol is `pocket-crossing-lan-1`, with content revision `m14.6-four-maps-1`; bump the content revision when changing bundled multiplayer content incompatibly.

Only 2–4 admitted racers participate. A few additional temporary transport connections permit useful rejection messages rather than silent connection failure. Duplicate names are compared after trim/lowercase; duplicate IDs, wrong versions, a fifth player and mid-match joins are rejected. Invalid skins fall back to Pip. Pending unresponsive handshakes and stale clients time out.

Only the host selects one of its unlocked maps. Guests can play that bundled map while it remains locked in their own account. Map previews/names appear on all devices. Every roster/map revision clears readiness and reloads/acknowledges the selected state; START is disabled until at least two admitted racers are ready. Guests cannot change the map or start the next match.

## Discovery and Android setup

Join broadcasts a small discovery query approximately every two seconds. Hosts reply to the query sender. Processing is bounded to 16 packets per frame, 2 KiB per packet and 32 listed hosts; stale entries expire after six seconds. Host IP display filters loopback, IPv6 and link-local addresses. Multiple usable IPv4 addresses may be shown; choose the shared LAN interface.

Only these Android export permissions were changed:

- `INTERNET`: required for ENet and UDP sockets, including offline LAN use.
- `CHANGE_WIFI_MULTICAST_STATE`: allows a Wi-Fi multicast lock for devices that filter discovery packets.

`AndroidDiscoveryLock` uses Godot's built-in AndroidRuntime/Java bridge and checks Java exceptions. The lock is acquired only while discovery is active and released when leaving. Other platforms skip it. No extra Android plugin, Gradle dependency, unrelated permission or account service was added. The existing standard-template export configuration and blank SDK override values remain unchanged.

The Android Java branch could not be executed on a physical device here. APK/AAB generation, actual merged Android manifest and target SDK verification are not claimed. The resource pack is tested separately; it does not prove a native APK works. If a particular Android version/OEM imposes additional local-network access behavior, verify that on the intended export template/device before release. Manual IP remains available if discovery is filtered, though it cannot bypass a router's client isolation.

## Countdown and synchronization

Starting creates a fresh match ID and loading barrier. After all connected peers acknowledge the current map revision, the host schedules GO about 5.2 seconds into its clock. Ping/response samples estimate the host-clock offset using the lowest observed round-trip sample. Every peer derives its 5–1/GO display from that same future timestamp. Commands are ignored before the racing phase; the race timer starts at GO. Match IDs, sequence checks and input rate bounds prevent stale/repeated commands carrying across retries.

Discrete inputs use a reliable ordered RPC channel. World snapshots use a separate unreliable ordered channel at a configured 20 Hz. Snapshot payloads are compressed; decoding is size-bounded and does not instantiate serialized Objects. Control/results messages are reliable. This is intentionally friendly LAN networking, not a public-server anti-cheat product; the host is trusted.

The host alone advances the original Road/Railway/Water simulation. Clients disable those hazard simulations and interpolate received presentation states:

- **Road:** vehicle instance/type/lane/direction/paint/speed/position, with replicas created/removed as necessary.
- **Railway:** warning/safe/passing state, timing and train position, using the original signal/train visuals.
- **Water:** pooled platform positions, current lane motion and elapsed presentation time. Water rescue/support/boundary decisions remain host-side.
- **Players:** position, cell, visibility/hop, lives, goals, collected pickups, score/coins, rank/finish and shield/power caption.

Themes and weather come from the existing bundled map Resource; decorative particles are not synchronized individually. The same camera and screen-space HUD/touch controls are retained. Compact multiplayer maps remain active as a whole so one player's camera cannot deactivate another player's hazards. A future expansion to very long LAN maps would need activation based on all racers rather than the single local camera.

Client motion follows interpolated host snapshots. There is no complex local prediction, rollback or host migration. Weak/high-latency Wi-Fi can therefore introduce visible input delay; this must be judged on real target phones.

## Independent racer state and shared world

Each racer uses the original player scene and water support adapter. Players do not physically block each other. Small name labels identify remote racers; YOU identifies the local racer, and labels separate vertically when actors overlap.

Every racer has its own five destination slots, lives, respawn state, pickup ledger, temporary power-ups, score and finish time. Another racer reaching a slot does not claim yours. Your own occupied slot cannot be counted twice. Only the local player's occupied destinations/pickup removals are shown strongly. Collected coin visuals reuse the existing pickup effect.

CollisionRules is shared with Local Play. Host damage consumes the existing shield before a life; a water rescue follows the existing spawn reset approach. One death does not reset other racers. The local victim receives hit sound/flash and Android vibration if enabled; remote deaths use the short event feed rather than loud per-player sound spam.

Shield and multiplier are personal. Slow Traffic acts on the one shared hazard world, benefiting everyone, using the strongest active slowdown rather than diverging per-client hazard speeds. Power durations remain temporary. Multiple water-support owners may ride one platform; releasing one owner's support does not release the others. The existing authoritative platform/world-edge rule is preserved.

## Finish, feed, coins and results

Finish is awarded only after the host observes five valid, independent destinations. Unique ranks follow finish order; finishes processed in one simulation tick use peer ID as a deterministic tie breaker. Score is supplementary and cannot reorder finish ranks. Finished racers stop crossing, retain their rank and can observe remaining racers. No sixth character is spawned. The race continues until everybody is finished, out or disconnected.

The feed is capped at eight queued entries. Entries display for about three seconds then expire/fade; finish/disconnect messages take priority. It does not stack unlimited UI or run continuous rocket celebrations while other players are crossing. Local Play's existing new-best rocket celebration is unchanged.

The host broadcasts one final result table: rank, player, host completion time, status, score and earned coins. Every peer displays the same rows. DNF/disconnected racers are below finishers. Host controls replay or return to lobby/change map; guests wait or leave.

Each coin is collectible once per player per match, not stolen globally by the first racer. Legitimate coins are settled on each local device when final results arrive. Match receipts prevent duplicate awards; the latest 64 are retained. Friends best time is separate from Local best time, and guest participation never grants a map unlock. Earned coins can later purchase maps normally. Leaving/aborting before final result settlement does not bank provisional match coins. No client balance is accepted as authority.

## Pause, interruption and cleanup

Friends pause opens a local overlay; the SceneTree and other racers continue. Host End Match requires its explicit confirmation action. Background notifications open the local overlay without globally pausing networking. A short interruption may recover; one exceeding the configured ten-second liveness timeout is treated as a disconnect. A disconnected unfinished racer is DNF, without reconnecting mid-race. Host loss sends clients safely back to Friends Play. Rejoin is supported after returning to a lobby, not inside a running race.

Leaving closes ENet and discovery, removes remote actors/replicas/supports, clears roster/feed/ranks/pickups and restores the original local player/camera/activation. Local Play neither starts a server nor broadcasts discovery. Fresh Local Play after network cleanup is part of the integration tests.

## Performance and test boundaries

Network state is bounded: four actors, fixed-rate compressed snapshots, bounded discovery and feed, pooled existing platforms/trains and no per-decoration replication. Actual payload/node measurements and current assertion totals are in the validation report. Headless performance is not a phone frame-rate, GPU, thermal or battery measurement.

Tests use actual independent Godot processes and localhost ENet sockets. They exercise real hop commands, pause, replicated hazards and moving shared-platform support. To make end-of-match assertions deterministic and fast, **goal/coin arrivals and shield damage include controlled host fixtures**. These are not a claim that humans naturally played every LAN crossing. The preserved Local route suites separately exercise the existing game routes. Captured screenshots come from actual rendered Linux gameplay/lobby/results, not invented UI mockups.

## Exact Windows and physical-device checklist

1. Back up the project and saves. Install the update into your existing project and open with Godot 4.5.2. Start normally using the Play triangle. Existing account should open the mode menu automatically. Check coins, characters, unlocked maps and Local best times. Rename in Settings, restart, and confirm all values survive.
2. Test a genuinely separate fresh save/user installation. Create a 3–16-character username; reject invalid names. Confirm there is no normal Add Player/Switch Player option. Multiple Windows test instances must use distinct test user-data directories/accounts, otherwise they share the same saved identity and should be rejected as duplicates.
3. Put Windows/Android devices on one Wi-Fi. Allow the game through Windows Firewall for the private LAN. Host on Windows, join from Android; then reverse roles. Also test Windows→Windows and Android→Android. Verify discovery and manual IP separately. No Internet service should be required.
4. **Hotspot:** Phone A enables its hotspot. B/C/D connect to that hotspot. A opens Friends Play → Host Game. B/C/D open Join Game. If no listing appears, choose Enter Host IP and type A's displayed hotspot IPv4. Start with two devices, then three and four. Some hotspots isolate clients or filter broadcast; try a shared router if manual IP also fails.
5. Check each admitted player/skin/name/readiness. Try duplicate names differing only by case, a mismatched build, a fifth client and a join during a running match. Each should get a clear refusal without losing account data.
6. Host changes among its unlocked maps. All guests see the same preview/name; readiness resets. Guests cannot change the map or start. Select a map locked on a guest; after playing and restarting that guest, it must still be locked.
7. Start a race. Compare 5–4–3–2–1/GO and timers side-by-side. Attempt movement before GO. Test Windows arrows/WASD, Android split-touch buttons/holds and swipes. Input should remain responsive after pause/resume and replay.
8. Naturally play all four maps, especially River Delta and Night Express. Compare road positions/types, train warnings/arrivals and boats on devices. Two players ride one boat; one hops off while the other remains. Ride near the world edge: a supported racer should not die before its platform fully clears the boundary.
9. Cause road, train and water deaths independently. Check local flash/sound/vibration, shared temporary feed, unchanged other-player lives/goals and correct respawn. Test shield once, temporary slowdown shared by all, and personal multiplier. Lose all lives; remain connected as DNF/observer.
10. Collect the same coin independently, revisit it and verify no second award. Use the same destination with two different racers. Revisit your own occupied destination and verify no additional crossing. Finish five different destinations.
11. Finish in a known order, including close finishes. Check unique ranks, exact matching results (name/time/score/status) on every device, DNF below finishers, no sixth character and continuation after first place. Save rewards once, replay/return to menu/restart and verify Friends best/coins persist while Local best/unlocks remain unchanged.
12. Pause one client while another moves. Test brief backgrounding and more than ten seconds of backgrounding/network loss. Close the host during lobby/countdown/race. Clients must leave cleanly. Confirm End Match prompts first and returns everyone to lobby without leftover effects.
13. Replay, switch map, return to lobby, leave, then start Local Play. Check no remote names/actors, no network HUD, normal five destinations, coins/unlock purchases, character selection, water/railway, pause/retry, Local best saving and rocket new-best celebration.
14. On Android run a four-player race for several minutes. Watch FPS, input latency, train readability, boat jitter, rain/night visibility, device heat and battery use. Repeat after several replays and map changes. These checks remain required; no physical Android performance pass is asserted.

## Limitations and next milestone

No Internet matchmaking, backend, public leaderboard, chat, host migration, mid-race reconnect, prediction or release/publishing work is included. A trusted LAN host controls results. UDP discovery depends on router/hotspot policy and Android behavior. Physical Windows/Android cross-platform runs, final exported APK permissions and mobile performance remain acceptance gates. Do not treat this build as certified for M15 until that checklist is completed. M15 remains a separate user-approved milestone.

Technical reference: Godot 4.5 SceneMultiplayer documents disabling `server_relay` for host-only communication: https://docs.godotengine.org/en/4.5/classes/class_scenemultiplayer.html . AndroidRuntime/Java bridge: https://docs.godotengine.org/en/4.5/tutorials/platform/android/javaclasswrapper_and_androidruntimeplugin.html .
