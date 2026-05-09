# Lookup Data

Per-biome lookup tables for type-specific node fields. Hooks are short string keys; LLM expands them in prose.

## Combat — Enemy type hooks

| Biome | Enemies |
|-------|---------|
| township     | drunk_miner, desperate_newcomer, crooked_official, gang_member, debt_collector, claim_shark, sly_grog_seller, license_hunter, deserter_trooper, card_sharp |
| the_diggings | claim_jumper, rival_digger, wild_dog_pack, bushrangers, desperate_fossicker, gold_fever_victim, equipment_thief, territorial_prospector, sunstruck_wanderer, claim_dispute_gang |
| the_bush     | bushranger, wild_boar, snake_nest, lost_madman, escaped_convict, feral_bullock, territorial_dingo, stranded_traveller, wounded_roo, fever_hermit |
| the_mines    | corrupted_miner, cave_horror, thing_in_dark, collapsed_dead, shaft_lurker, gas_maddened_worker, tunnel_stalker, pit_crawler, deep_dweller, changed_foreman |
| the_waste    | scavenger, ghost_echo, twisted_wildlife, waste_walker, dust_shambler, bleached_wanderer, hollow_digger, carrion_stalker, dried_remnant, void_touched_beast |
| the_scar     | transformed_human, scar_horror, reality_fracture, the_changed, geometry_walker, unravelled_one, between_thing, fractured_echo, void_manifest, wrongness_made_flesh |
| sacred_site  | guardian_spirit, corrupted_elder, taboo_breaker, ancient_wrath, boundary_keeper, awakened_defender, trespass_punisher, stone_warden, broken_seal_horror, desecration_echo |
| the_river    | river_pirate, crocodile, drowned_thing, smuggler_gang, paddle_steamer_crew, cargo_thieves, water_snake, mudbank_lurker, upstream_horror, ferryman_gone_wrong |

## Combat — Environmental contexts

| Biome | Contexts |
|-------|----------|
| township     | back_alley, saloon, warehouse, outskirts, general_store, assay_office, boarding_house, livery_stable, gold_buyers_tent, commissioners_camp |
| the_diggings | open_pit, claim_boundary, water_hole, equipment_cache, puddling_area, cradle_station, tailings_heap, windlass_pit, sluice_race, mullock_pile |
| the_bush     | dense_scrub, dried_creek, rocky_outcrop, abandoned_camp, hollow_log, termite_mound, ghost_gum_stand, cattle_track, stockmans_hut, burnt_clearing |
| the_mines    | narrow_tunnel, flooded_shaft, collapsed_section, deep_cavern, ore_face, winze_descent, stope_chamber, timbered_drive, ventilation_rise, cribbing_room |
| the_waste    | poisoned_ground, abandoned_settlement, bone_field, toxic_pool, salted_earth, rusted_equipment, dried_waterhole, collapsed_shaft_mouth, bleached_camp, dust_hollow |
| the_scar     | warped_terrain, reality_bleed, transformed_zone, the_edge, angle_wrong_clearing, folded_space, colour_wound, impossible_gorge, geometry_fracture, threshold_point |
| sacred_site  | sacred_ground, ancient_stones, spirit_tree, forbidden_circle, ochre_pit, carved_boulder, song_line_crossing, water_dreaming, boundary_marker, painted_overhang |
| the_river    | riverbank, rapids, river_island, crossing_point, paddle_steamer_wreck, fish_trap, billabong, snag_pile, ferry_landing, reedy_shallows |

## Combat — Difficulty curves (1–5)

| Biome | Distribution |
|-------|-------------|
| township     | 1, 2, 2, 3 |
| the_diggings | 2, 2, 3, 3 |
| the_bush     | 2, 3, 3, 4 |
| the_mines    | 3, 3, 4, 4, 5 |
| the_waste    | 3, 4, 4, 5 |
| the_scar     | 4, 4, 5, 5 |
| sacred_site  | 2, 3, 4, 5 |
| the_river    | 2, 2, 3, 3, 4 |

## Choice — Consequence hooks

| Biome | Hooks |
|-------|-------|
| township     | reputation_change, law_attention, merchant_relation, gang_notice |
| the_diggings | claim_dispute, resource_gain, rival_enmity, partner_trust |
| the_bush     | survival_impact, path_discovery, ally_gained, enemy_made |
| the_mines    | corruption_exposure, sanity_cost, secret_learned, trapped_deeper |
| the_waste    | contamination, ghost_encounter, resource_found, past_revealed |
| the_scar     | transformation_risk, reality_shift, power_gained, humanity_lost |
| sacred_site  | spiritual_debt, blessing_curse, taboo_broken, wisdom_gained |
| the_river    | trade_opportunity, passage_secured, smuggler_contact, danger_avoided |

## Choice — Dilemma weights (moral / practical / survival)

| Biome | Moral | Practical | Survival |
|-------|------:|----------:|---------:|
| township     | 3 | 2 | 1 |
| the_diggings | 1 | 3 | 2 |
| the_bush     | 1 | 2 | 3 |
| the_mines    | 2 | 1 | 3 |
| the_waste    | 1 | 2 | 3 |
| the_scar     | 3 | 1 | 2 |
| sacred_site  | 3 | 1 | 2 |
| the_river    | 2 | 3 | 1 |

## Rest — Dream hooks

| Biome | Dreams |
|-------|--------|
| township     | memory_of_home, gold_vision, warning_dream, debt_mounting, faces_in_crowd, the_empty_chair, ledger_bleeding, familiar_stranger, hanging_tree, gold_teeth_smile |
| the_diggings | gold_fever_dream, buried_alive, strike_it_rich, hands_in_earth, claim_jumper_face, the_colour_spreading, nugget_heartbeat, endless_digging, drowned_in_tailings, golden_tears |
| the_bush     | lost_in_wilderness, animal_stalking, escape_path, trees_closing_in, circling_back, wrong_stars, the_silence_watching, smoke_without_fire, footsteps_following, hollow_log_calling |
| the_mines    | darkness_consuming, whispers_below, transformation_horror, candle_dying, wrong_direction, walls_breathing, the_face_in_rock, depth_without_end, timbering_groans, the_thing_you_dug |
| the_waste    | past_sins, ghost_visitation, contamination_spread, dried_waterhole, the_last_one_left, bones_speaking, dust_filling_mouth, sun_that_burns_cold, empty_claims_calling, the_price_paid |
| the_scar     | reality_fracture, other_self, the_change_coming, geometry_wrong, colours_unnamed, self_dissolving, time_looping, voice_from_within, the_threshold, becoming_something |
| sacred_site  | ancestor_message, spiritual_journey, forbidden_knowledge, the_seal_broken, watching_stones, memory_of_land, the_old_warning, something_contained, threshold_guardian, the_weight_of_knowing |
| the_river    | drowning, river_spirit, distant_shore, current_pulling, faces_below_surface, upstream_source, the_barge_of_dead, muddy_embrace, wrong_reflection, fish_with_knowing_eyes |

## Rest — Type → interruption chance

| Rest type | Interruption |
|-----------|-------------|
| safe   | none |
| risky  | high |
| sacred | low  |

## Rest — Types per biome

| Biome | Types available |
|-------|----------------|
| township     | safe, safe |
| the_diggings | risky |
| the_bush     | risky, risky |
| the_mines    | risky |
| the_waste    | risky |
| the_scar     | (none — no rest possible) |
| sacred_site  | sacred, sacred |
| the_river    | risky, safe |

## Passage — Travel event hooks

| Biome | Hooks |
|-------|-------|
| township     | road_encounter, fellow_traveler, checkpoint, shortcut_found, license_inspection, street_brawl, runaway_cart, town_crier, drunken_miner, pickpocket_attempt |
| the_diggings | equipment_breakdown, rival_sighting, claim_marker, water_source, boundary_dispute, lucky_find, abandoned_shaft, puddler_accident, claim_jumper, old_hand_advice |
| the_bush     | wildlife_encounter, weather_change, lost_trail, hidden_cache, bushranger_sign, snake_in_path, billabong_discovery, smoke_on_horizon, selector_hut, dingo_pack |
| the_mines    | cave_in_risk, gas_pocket, strange_sounds, flooded_passage, timber_creak, candle_flicker, abandoned_tools, narrow_squeeze, ladder_rot, deep_echo |
| the_waste    | toxic_cloud, ghost_sighting, ruin_discovery, contamination, dead_silence, mirage_shimmer, bleached_bones, equipment_remains, dust_devil, tainted_water |
| the_scar     | reality_warp, terrain_shift, echo_of_past, the_pull, memory_bleed, compass_spin, doubled_path, time_slip, impossible_shadow, void_whisper |
| sacred_site  | spirit_presence, sacred_marker, forbidden_path, blessing_curse, guardian_warning, dreaming_vision, boundary_stone, ancestor_whisper, protection_failing, songline_crossing |
| the_river    | rapids, sandbank, river_crossing, boat_trouble, snag_hazard, ferry_wait, river_pirates, flooding_concern, fish_kill, current_pull |

## Passage — Environmental storytelling

| Biome | Beats |
|-------|-------|
| township     | bustling_streets, quiet_backroads, crowded_paths, empty_lots, canvas_town, sly_grog_alley, assay_office_queue, auction_yard, notice_board, trooper_post |
| the_diggings | scarred_earth, abandoned_claims, busy_pits, equipment_graveyards, mullock_heaps, cradle_lines, windlass_silhouettes, puddling_machines, tent_rows, sluice_channels |
| the_bush     | untamed_wilderness, old_trails, animal_tracks, settler_remnants, eucalypt_stands, dry_creek_beds, ringbarked_trees, selector_fences, campfire_ashes, wallaby_paths |
| the_mines    | carved_tunnels, support_beams, ore_veins, forgotten_tools, candle_niches, air_shafts, ladder_ways, quartz_seams, water_pools, pick_marks |
| the_waste    | blighted_land, collapsed_structures, poisoned_streams, bone_scattered, rust_stains, ash_drifts, cracked_earth, abandoned_camps, dead_trees, silence_pools |
| the_scar     | warped_geography, impossible_angles, color_bleeding, reality_tears, folded_ground, shadow_pools, stone_ripples, light_bends, echo_walls, void_seepage |
| sacred_site  | ancient_markings, spirit_signs, sacred_geometry, offering_sites, ochre_traces, stone_arrangements, hand_stencils, waterhole_guardians, dreaming_paths, silence_zones |
| the_river    | flowing_waters, riverside_camps, crossing_points, boat_wrecks, reed_beds, landing_stages, fish_traps, rope_ferries, flood_marks, cargo_debris |

## Passage — Resource cost

| Biome | Type | Amount | Optional |
|-------|------|-------:|:-------:|
| township     | time     | 1 |   |
| the_diggings | supplies | 1 |   |
| the_bush     | supplies | 2 |   |
| the_mines    | light    | 1 |   |
| the_waste    | health   | 1 | ✓ |
| the_scar     | sanity   | 1 |   |
| sacred_site  | offering | 1 | ✓ |
| the_river    | supplies | 1 |   |

## StateCheck — Condition hooks

| Biome | Conditions |
|-------|-----------|
| township     | has_gold, reputation_level, law_standing, merchant_contact |
| the_diggings | has_claim, tool_condition, water_supply, rival_status |
| the_bush     | survival_skill, supplies_level, navigation_ability, wildlife_knowledge |
| the_mines    | light_source, corruption_level, sanity_check, depth_reached |
| the_waste    | contamination_level, ghost_seen, past_action, resource_threshold |
| the_scar     | transformation_stage, reality_anchor, humanity_remaining, power_level |
| sacred_site  | spiritual_debt, taboo_status, blessing_active, offering_made |
| the_river    | boat_access, river_knowledge, trade_reputation, crossing_fee |

## StateCheck — Branch templates (success / failure)

| Biome | Templates |
|-------|----------|
| township     | welcomed/turned_away · discount_offered/price_gouged · info_shared/deceived |
| the_diggings | claim_secured/claim_jumped · find_water/dehydration · avoid_conflict/ambushed |
| the_bush     | path_found/lost · danger_avoided/encounter_forced · shelter_found/exposed |
| the_mines    | safe_passage/trapped · resist_whispers/corrupted · find_exit/deeper_in |
| the_waste    | avoid_contamination/poisoned · ghost_peace/haunted · find_cache/dead_end |
| the_scar     | maintain_self/transformed · harness_power/overwhelmed · find_path/lost_in_unreality |
| sacred_site  | blessed/cursed · wisdom_gained/spirit_angered · passage_granted/barred |
| the_river    | safe_crossing/swept_away · trade_success/cheated · passage_secured/stranded |

## Trade — Trader archetypes

| Biome | Archetypes |
|-------|-----------|
| township     | general_store, gunsmith, apothecary, black_market |
| the_diggings | equipment_seller, water_vendor, claim_broker |
| the_bush     | traveling_merchant, hermit_trader |
| the_mines    | (none) |
| the_waste    | (none) |
| the_scar     | (none) |
| sacred_site  | (none) |
| the_river    | river_trader, ferryman, smuggler |

## Trade — Pricing hooks per archetype

| Archetype | Hooks |
|-----------|-------|
| general_store      | act_inflation, supply_scarcity, reputation_discount |
| gunsmith           | weapon_demand, ammo_shortage, quality_tier |
| apothecary         | medicine_rarity, desperation_markup, bulk_discount |
| black_market       | risk_premium, contact_trust, contraband_type |
| equipment_seller   | equipment_wear, claim_rush_prices, competitor_rates |
| water_vendor       | drought_severity, distance_premium, purity_grade |
| claim_broker       | gold_speculation, location_value, legal_status |
| traveling_merchant | journey_risk, rarity_factor, desperation_level |
| hermit_trader      | barter_preference, trust_level, strange_requests |
| river_trader       | transport_cost, river_conditions, cargo_type |
| ferryman           | crossing_danger, time_urgency, load_weight |
| smuggler           | contraband_heat, official_presence, discretion_fee |

## Transition — Narrative summaries (sample, key biomes)

| Biome | Summaries |
|-------|----------|
| township     | "The township reveals its true nature as desperation takes hold." · "Order crumbles as the gold fever spreads through every street." |
| the_diggings | "The diggings have changed—something stirs beneath the turned earth." · "Competition gives way to something darker in the pits." |
| the_mines    | "The mines go deeper than any map shows, and something knows you are here." · "Darkness becomes more than absence of light." |
| the_scar     | "The scar pulses with wrongness that seeps into everything." · "Reality itself begins to unravel at the edges." |
| sacred_site  | "The sacred site awakens to judge those who trespass." · "Ancient powers stir, neither welcoming nor hostile—yet." |

## Transition — World state shifts

| Biome | Shift sets |
|-------|-----------|
| township     | [law_weakens, prices_rise, desperation_spreads] · [strangers_arrive, old_powers_stir, secrets_surface] |
| the_diggings | [claims_consolidate, violence_increases, deep_sounds_heard] · [water_scarcity, madness_spreads, the_wrong_gold] |
| the_mines    | [deeper_access, corruption_spreads, the_below_wakes] · [miners_vanish, ore_changes, whispers_intensify] |
| the_scar     | [reality_fractures, transformation_accelerates, the_pull_strengthens] · [boundaries_dissolve, the_changed_multiply, escape_closes] |
| sacred_site  | [spirits_active, taboos_strengthen, judgment_approaches] · [veil_thins, ancestors_watch, power_available] |
