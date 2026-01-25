import { Biome } from '../types/biome.js';

// Combat lookups
export const ENEMY_TYPE_HOOKS: Record<Biome, string[]> = {
  [Biome.Township]: [
    'drunk_miner', 'desperate_newcomer', 'crooked_official', 'gang_member',
    'debt_collector', 'claim_shark', 'sly_grog_seller', 'license_hunter',
    'deserter_trooper', 'card_sharp'
  ],
  [Biome.TheDiggings]: [
    'claim_jumper', 'rival_digger', 'wild_dog_pack', 'bushrangers',
    'desperate_fossicker', 'gold_fever_victim', 'equipment_thief',
    'territorial_prospector', 'sunstruck_wanderer', 'claim_dispute_gang'
  ],
  [Biome.TheBush]: [
    'bushranger', 'wild_boar', 'snake_nest', 'lost_madman',
    'escaped_convict', 'feral_bullock', 'territorial_dingo',
    'stranded_traveller', 'wounded_roo', 'fever_hermit'
  ],
  [Biome.TheMines]: [
    'corrupted_miner', 'cave_horror', 'thing_in_dark', 'collapsed_dead',
    'shaft_lurker', 'gas_maddened_worker', 'tunnel_stalker', 'pit_crawler',
    'deep_dweller', 'changed_foreman'
  ],
  [Biome.TheWaste]: [
    'scavenger', 'ghost_echo', 'twisted_wildlife', 'waste_walker',
    'dust_shambler', 'bleached_wanderer', 'hollow_digger', 'carrion_stalker',
    'dried_remnant', 'void_touched_beast'
  ],
  [Biome.TheScar]: [
    'transformed_human', 'scar_horror', 'reality_fracture', 'the_changed',
    'geometry_walker', 'unravelled_one', 'between_thing', 'fractured_echo',
    'void_manifest', 'wrongness_made_flesh'
  ],
  [Biome.SacredSite]: [
    'guardian_spirit', 'corrupted_elder', 'taboo_breaker', 'ancient_wrath',
    'boundary_keeper', 'awakened_defender', 'trespass_punisher', 'stone_warden',
    'broken_seal_horror', 'desecration_echo'
  ],
  [Biome.TheRiver]: [
    'river_pirate', 'crocodile', 'drowned_thing', 'smuggler_gang',
    'paddle_steamer_crew', 'cargo_thieves', 'water_snake', 'mudbank_lurker',
    'upstream_horror', 'ferryman_gone_wrong'
  ],
};

export const ENVIRONMENTAL_CONTEXTS: Record<Biome, string[]> = {
  [Biome.Township]: [
    'back_alley', 'saloon', 'warehouse', 'outskirts', 'general_store',
    'assay_office', 'boarding_house', 'livery_stable', 'gold_buyers_tent',
    'commissioners_camp'
  ],
  [Biome.TheDiggings]: [
    'open_pit', 'claim_boundary', 'water_hole', 'equipment_cache',
    'puddling_area', 'cradle_station', 'tailings_heap', 'windlass_pit',
    'sluice_race', 'mullock_pile'
  ],
  [Biome.TheBush]: [
    'dense_scrub', 'dried_creek', 'rocky_outcrop', 'abandoned_camp',
    'hollow_log', 'termite_mound', 'ghost_gum_stand', 'cattle_track',
    'stockmans_hut', 'burnt_clearing'
  ],
  [Biome.TheMines]: [
    'narrow_tunnel', 'flooded_shaft', 'collapsed_section', 'deep_cavern',
    'ore_face', 'winze_descent', 'stope_chamber', 'timbered_drive',
    'ventilation_rise', 'cribbing_room'
  ],
  [Biome.TheWaste]: [
    'poisoned_ground', 'abandoned_settlement', 'bone_field', 'toxic_pool',
    'salted_earth', 'rusted_equipment', 'dried_waterhole', 'collapsed_shaft_mouth',
    'bleached_camp', 'dust_hollow'
  ],
  [Biome.TheScar]: [
    'warped_terrain', 'reality_bleed', 'transformed_zone', 'the_edge',
    'angle_wrong_clearing', 'folded_space', 'colour_wound', 'impossible_gorge',
    'geometry_fracture', 'threshold_point'
  ],
  [Biome.SacredSite]: [
    'sacred_ground', 'ancient_stones', 'spirit_tree', 'forbidden_circle',
    'ochre_pit', 'carved_boulder', 'song_line_crossing', 'water_dreaming',
    'boundary_marker', 'painted_overhang'
  ],
  [Biome.TheRiver]: [
    'riverbank', 'rapids', 'river_island', 'crossing_point',
    'paddle_steamer_wreck', 'fish_trap', 'billabong', 'snag_pile',
    'ferry_landing', 'reedy_shallows'
  ],
};

// Choice lookups
export const CONSEQUENCE_HOOKS: Record<Biome, string[]> = {
  [Biome.Township]: ['reputation_change', 'law_attention', 'merchant_relation', 'gang_notice'],
  [Biome.TheDiggings]: ['claim_dispute', 'resource_gain', 'rival_enmity', 'partner_trust'],
  [Biome.TheBush]: ['survival_impact', 'path_discovery', 'ally_gained', 'enemy_made'],
  [Biome.TheMines]: ['corruption_exposure', 'sanity_cost', 'secret_learned', 'trapped_deeper'],
  [Biome.TheWaste]: ['contamination', 'ghost_encounter', 'resource_found', 'past_revealed'],
  [Biome.TheScar]: ['transformation_risk', 'reality_shift', 'power_gained', 'humanity_lost'],
  [Biome.SacredSite]: ['spiritual_debt', 'blessing_curse', 'taboo_broken', 'wisdom_gained'],
  [Biome.TheRiver]: ['trade_opportunity', 'passage_secured', 'smuggler_contact', 'danger_avoided'],
};

export const DILEMMA_WEIGHTS: Record<Biome, { moral: number; practical: number; survival: number }> = {
  [Biome.Township]: { moral: 3, practical: 2, survival: 1 },
  [Biome.TheDiggings]: { moral: 1, practical: 3, survival: 2 },
  [Biome.TheBush]: { moral: 1, practical: 2, survival: 3 },
  [Biome.TheMines]: { moral: 2, practical: 1, survival: 3 },
  [Biome.TheWaste]: { moral: 1, practical: 2, survival: 3 },
  [Biome.TheScar]: { moral: 3, practical: 1, survival: 2 },
  [Biome.SacredSite]: { moral: 3, practical: 1, survival: 2 },
  [Biome.TheRiver]: { moral: 2, practical: 3, survival: 1 },
};

// Rest lookups
export const DREAM_HOOKS: Record<Biome, string[]> = {
  [Biome.Township]: [
    'memory_of_home', 'gold_vision', 'warning_dream', 'debt_mounting',
    'faces_in_crowd', 'the_empty_chair', 'ledger_bleeding', 'familiar_stranger',
    'hanging_tree', 'gold_teeth_smile'
  ],
  [Biome.TheDiggings]: [
    'gold_fever_dream', 'buried_alive', 'strike_it_rich', 'hands_in_earth',
    'claim_jumper_face', 'the_colour_spreading', 'nugget_heartbeat',
    'endless_digging', 'drowned_in_tailings', 'golden_tears'
  ],
  [Biome.TheBush]: [
    'lost_in_wilderness', 'animal_stalking', 'escape_path', 'trees_closing_in',
    'circling_back', 'wrong_stars', 'the_silence_watching', 'smoke_without_fire',
    'footsteps_following', 'hollow_log_calling'
  ],
  [Biome.TheMines]: [
    'darkness_consuming', 'whispers_below', 'transformation_horror', 'candle_dying',
    'wrong_direction', 'walls_breathing', 'the_face_in_rock', 'depth_without_end',
    'timbering_groans', 'the_thing_you_dug'
  ],
  [Biome.TheWaste]: [
    'past_sins', 'ghost_visitation', 'contamination_spread', 'dried_waterhole',
    'the_last_one_left', 'bones_speaking', 'dust_filling_mouth',
    'sun_that_burns_cold', 'empty_claims_calling', 'the_price_paid'
  ],
  [Biome.TheScar]: [
    'reality_fracture', 'other_self', 'the_change_coming', 'geometry_wrong',
    'colours_unnamed', 'self_dissolving', 'time_looping', 'voice_from_within',
    'the_threshold', 'becoming_something'
  ],
  [Biome.SacredSite]: [
    'ancestor_message', 'spiritual_journey', 'forbidden_knowledge',
    'the_seal_broken', 'watching_stones', 'memory_of_land', 'the_old_warning',
    'something_contained', 'threshold_guardian', 'the_weight_of_knowing'
  ],
  [Biome.TheRiver]: [
    'drowning', 'river_spirit', 'distant_shore', 'current_pulling',
    'faces_below_surface', 'upstream_source', 'the_barge_of_dead',
    'muddy_embrace', 'wrong_reflection', 'fish_with_knowing_eyes'
  ],
};

export const INTERRUPTION_BY_REST_TYPE: Record<'safe' | 'risky' | 'sacred', 'none' | 'low' | 'medium' | 'high'> = {
  safe: 'none',
  risky: 'high',
  sacred: 'low',
};

// Passage lookups
export const TRAVEL_EVENT_HOOKS: Record<Biome, string[]> = {
  [Biome.Township]: [
    'road_encounter', 'fellow_traveler', 'checkpoint', 'shortcut_found',
    'license_inspection', 'street_brawl', 'runaway_cart', 'town_crier',
    'drunken_miner', 'pickpocket_attempt'
  ],
  [Biome.TheDiggings]: [
    'equipment_breakdown', 'rival_sighting', 'claim_marker', 'water_source',
    'boundary_dispute', 'lucky_find', 'abandoned_shaft', 'puddler_accident',
    'claim_jumper', 'old_hand_advice'
  ],
  [Biome.TheBush]: [
    'wildlife_encounter', 'weather_change', 'lost_trail', 'hidden_cache',
    'bushranger_sign', 'snake_in_path', 'billabong_discovery', 'smoke_on_horizon',
    'selector_hut', 'dingo_pack'
  ],
  [Biome.TheMines]: [
    'cave_in_risk', 'gas_pocket', 'strange_sounds', 'flooded_passage',
    'timber_creak', 'candle_flicker', 'abandoned_tools', 'narrow_squeeze',
    'ladder_rot', 'deep_echo'
  ],
  [Biome.TheWaste]: [
    'toxic_cloud', 'ghost_sighting', 'ruin_discovery', 'contamination',
    'dead_silence', 'mirage_shimmer', 'bleached_bones', 'equipment_remains',
    'dust_devil', 'tainted_water'
  ],
  [Biome.TheScar]: [
    'reality_warp', 'terrain_shift', 'echo_of_past', 'the_pull',
    'memory_bleed', 'compass_spin', 'doubled_path', 'time_slip',
    'impossible_shadow', 'void_whisper'
  ],
  [Biome.SacredSite]: [
    'spirit_presence', 'sacred_marker', 'forbidden_path', 'blessing_curse',
    'guardian_warning', 'dreaming_vision', 'boundary_stone', 'ancestor_whisper',
    'protection_failing', 'songline_crossing'
  ],
  [Biome.TheRiver]: [
    'rapids', 'sandbank', 'river_crossing', 'boat_trouble', 'snag_hazard',
    'ferry_wait', 'river_pirates', 'flooding_concern', 'fish_kill', 'current_pull'
  ],
};

export const ENVIRONMENTAL_STORYTELLING: Record<Biome, string[]> = {
  [Biome.Township]: [
    'bustling_streets', 'quiet_backroads', 'crowded_paths', 'empty_lots',
    'canvas_town', 'sly_grog_alley', 'assay_office_queue', 'auction_yard',
    'notice_board', 'trooper_post'
  ],
  [Biome.TheDiggings]: [
    'scarred_earth', 'abandoned_claims', 'busy_pits', 'equipment_graveyards',
    'mullock_heaps', 'cradle_lines', 'windlass_silhouettes', 'puddling_machines',
    'tent_rows', 'sluice_channels'
  ],
  [Biome.TheBush]: [
    'untamed_wilderness', 'old_trails', 'animal_tracks', 'settler_remnants',
    'eucalypt_stands', 'dry_creek_beds', 'ringbarked_trees', 'selector_fences',
    'campfire_ashes', 'wallaby_paths'
  ],
  [Biome.TheMines]: [
    'carved_tunnels', 'support_beams', 'ore_veins', 'forgotten_tools',
    'candle_niches', 'air_shafts', 'ladder_ways', 'quartz_seams',
    'water_pools', 'pick_marks'
  ],
  [Biome.TheWaste]: [
    'blighted_land', 'collapsed_structures', 'poisoned_streams', 'bone_scattered',
    'rust_stains', 'ash_drifts', 'cracked_earth', 'abandoned_camps',
    'dead_trees', 'silence_pools'
  ],
  [Biome.TheScar]: [
    'warped_geography', 'impossible_angles', 'color_bleeding', 'reality_tears',
    'folded_ground', 'shadow_pools', 'stone_ripples', 'light_bends',
    'echo_walls', 'void_seepage'
  ],
  [Biome.SacredSite]: [
    'ancient_markings', 'spirit_signs', 'sacred_geometry', 'offering_sites',
    'ochre_traces', 'stone_arrangements', 'hand_stencils', 'waterhole_guardians',
    'dreaming_paths', 'silence_zones'
  ],
  [Biome.TheRiver]: [
    'flowing_waters', 'riverside_camps', 'crossing_points', 'boat_wrecks',
    'reed_beds', 'landing_stages', 'fish_traps', 'rope_ferries',
    'flood_marks', 'cargo_debris'
  ],
};

export const RESOURCE_COSTS: Record<Biome, { type: string; amount: number; optional?: boolean }> = {
  [Biome.Township]: { type: 'time', amount: 1 },
  [Biome.TheDiggings]: { type: 'supplies', amount: 1 },
  [Biome.TheBush]: { type: 'supplies', amount: 2 },
  [Biome.TheMines]: { type: 'light', amount: 1 },
  [Biome.TheWaste]: { type: 'health', amount: 1, optional: true },
  [Biome.TheScar]: { type: 'sanity', amount: 1 },
  [Biome.SacredSite]: { type: 'offering', amount: 1, optional: true },
  [Biome.TheRiver]: { type: 'supplies', amount: 1 },
};

// StateCheck lookups
export const CONDITION_HOOKS: Record<Biome, string[]> = {
  [Biome.Township]: ['has_gold', 'reputation_level', 'law_standing', 'merchant_contact'],
  [Biome.TheDiggings]: ['has_claim', 'tool_condition', 'water_supply', 'rival_status'],
  [Biome.TheBush]: ['survival_skill', 'supplies_level', 'navigation_ability', 'wildlife_knowledge'],
  [Biome.TheMines]: ['light_source', 'corruption_level', 'sanity_check', 'depth_reached'],
  [Biome.TheWaste]: ['contamination_level', 'ghost_seen', 'past_action', 'resource_threshold'],
  [Biome.TheScar]: ['transformation_stage', 'reality_anchor', 'humanity_remaining', 'power_level'],
  [Biome.SacredSite]: ['spiritual_debt', 'taboo_status', 'blessing_active', 'offering_made'],
  [Biome.TheRiver]: ['boat_access', 'river_knowledge', 'trade_reputation', 'crossing_fee'],
};

export const BRANCH_TEMPLATES: Record<Biome, Array<{ success: string; failure: string }>> = {
  [Biome.Township]: [
    { success: 'welcomed', failure: 'turned_away' },
    { success: 'discount_offered', failure: 'price_gouged' },
    { success: 'info_shared', failure: 'deceived' }
  ],
  [Biome.TheDiggings]: [
    { success: 'claim_secured', failure: 'claim_jumped' },
    { success: 'find_water', failure: 'dehydration' },
    { success: 'avoid_conflict', failure: 'ambushed' }
  ],
  [Biome.TheBush]: [
    { success: 'path_found', failure: 'lost' },
    { success: 'danger_avoided', failure: 'encounter_forced' },
    { success: 'shelter_found', failure: 'exposed' }
  ],
  [Biome.TheMines]: [
    { success: 'safe_passage', failure: 'trapped' },
    { success: 'resist_whispers', failure: 'corrupted' },
    { success: 'find_exit', failure: 'deeper_in' }
  ],
  [Biome.TheWaste]: [
    { success: 'avoid_contamination', failure: 'poisoned' },
    { success: 'ghost_peace', failure: 'haunted' },
    { success: 'find_cache', failure: 'dead_end' }
  ],
  [Biome.TheScar]: [
    { success: 'maintain_self', failure: 'transformed' },
    { success: 'harness_power', failure: 'overwhelmed' },
    { success: 'find_path', failure: 'lost_in_unreality' }
  ],
  [Biome.SacredSite]: [
    { success: 'blessed', failure: 'cursed' },
    { success: 'wisdom_gained', failure: 'spirit_angered' },
    { success: 'passage_granted', failure: 'barred' }
  ],
  [Biome.TheRiver]: [
    { success: 'safe_crossing', failure: 'swept_away' },
    { success: 'trade_success', failure: 'cheated' },
    { success: 'passage_secured', failure: 'stranded' }
  ],
};

// Trade lookups
export const PRICING_HOOKS: Record<string, string[]> = {
  general_store: ['act_inflation', 'supply_scarcity', 'reputation_discount'],
  gunsmith: ['weapon_demand', 'ammo_shortage', 'quality_tier'],
  apothecary: ['medicine_rarity', 'desperation_markup', 'bulk_discount'],
  black_market: ['risk_premium', 'contact_trust', 'contraband_type'],
  equipment_seller: ['equipment_wear', 'claim_rush_prices', 'competitor_rates'],
  water_vendor: ['drought_severity', 'distance_premium', 'purity_grade'],
  claim_broker: ['gold_speculation', 'location_value', 'legal_status'],
  traveling_merchant: ['journey_risk', 'rarity_factor', 'desperation_level'],
  hermit_trader: ['barter_preference', 'trust_level', 'strange_requests'],
  river_trader: ['transport_cost', 'river_conditions', 'cargo_type'],
  ferryman: ['crossing_danger', 'time_urgency', 'load_weight'],
  smuggler: ['contraband_heat', 'official_presence', 'discretion_fee'],
};

// Transition lookups (partial - only for key biomes)
export const NARRATIVE_SUMMARIES: Partial<Record<Biome, string[]>> = {
  [Biome.Township]: [
    'The township reveals its true nature as desperation takes hold.',
    'Order crumbles as the gold fever spreads through every street.'
  ],
  [Biome.TheDiggings]: [
    'The diggings have changed—something stirs beneath the turned earth.',
    'Competition gives way to something darker in the pits.'
  ],
  [Biome.TheMines]: [
    'The mines go deeper than any map shows, and something knows you are here.',
    'Darkness becomes more than absence of light.'
  ],
  [Biome.TheScar]: [
    'The scar pulses with wrongness that seeps into everything.',
    'Reality itself begins to unravel at the edges.'
  ],
  [Biome.SacredSite]: [
    'The sacred site awakens to judge those who trespass.',
    'Ancient powers stir, neither welcoming nor hostile—yet.'
  ],
};

export const WORLD_STATE_SHIFTS: Partial<Record<Biome, string[][]>> = {
  [Biome.Township]: [
    ['law_weakens', 'prices_rise', 'desperation_spreads'],
    ['strangers_arrive', 'old_powers_stir', 'secrets_surface']
  ],
  [Biome.TheDiggings]: [
    ['claims_consolidate', 'violence_increases', 'deep_sounds_heard'],
    ['water_scarcity', 'madness_spreads', 'the_wrong_gold']
  ],
  [Biome.TheMines]: [
    ['deeper_access', 'corruption_spreads', 'the_below_wakes'],
    ['miners_vanish', 'ore_changes', 'whispers_intensify']
  ],
  [Biome.TheScar]: [
    ['reality_fractures', 'transformation_accelerates', 'the_pull_strengthens'],
    ['boundaries_dissolve', 'the_changed_multiply', 'escape_closes']
  ],
  [Biome.SacredSite]: [
    ['spirits_active', 'taboos_strengthen', 'judgment_approaches'],
    ['veil_thins', 'ancestors_watch', 'power_available']
  ],
};
