// Script originally by worthawholebean, heavily modified by Manendra. Public domain; feel free to modify or distribute.
// This is a script to do 1-day Hardcore Community Service runs. See README.md for details.

import <canadv.ash>
import <hccs_combat.ash>
import <hccs_lib.ash>
import <c2t_cartographyHunt.ash>

int TEST_HP = 1;
int TEST_MUS = 2;
int TEST_MYS = 3;
int TEST_MOX = 4;
int TEST_FAMILIAR = 5;
int TEST_WEAPON = 6;
int TEST_SPELL = 7;
int TEST_NONCOMBAT = 8;
int TEST_ITEM = 9;
int TEST_HOT_RES = 10;
int TEST_COIL_WIRE = 11;

// test order will be stats, hot, item, NC, Fam, weapon, spell

int START_TIME = gametime_to_int();

familiar default_familiar = $familiar[melodramedary];
item default_familiar_equipment = $item[dromedary drinking helmet];

void use_default_familiar() {
    use_familiar(default_familiar);
    if (default_familiar_equipment != $item[none]) {
        equip(default_familiar_equipment);
    }
}

boolean try_use(int quantity, item it) {
    if (available_amount(it) > 0) {
        return use(quantity, it);
    } else {
        return false;
    }
}

boolean use_all(item it) {
    return use(available_amount(it), it);
}

boolean try_equip(item it) {
    if (available_amount(it) > 0) {
        return equip(it);
    } else {
        return false;
    }
}

void assert_meat(int meat) {
    if (my_meat() < meat) error('Not enough meat.');
}

void autosell_all(item it) {
    autosell(item_amount(it), it);
}

void wish_effect(effect ef) {
    if (have_effect(ef) == 0) {
        cli_execute('genie effect ' + ef.name);
    } else {
        print('Already have effect ' + ef.name + '.');
    }
}

void gene_tonic(string ph){
	
	switch (to_string(ph))
	{
		case 'elf':
			if ((have_effect($effect[1601]) == 0) && (available_amount($item[7399]) == 0) && (get_property('dnaSyringe') == 'elf'))	{
			cli_execute('camp dnapotion 1');
			if (available_amount($item[7399]) == 0) {
				error('something went wrong getting your gene tonic');
			}
			else {
				print('successfully created gene tonic: elf');
			}
		} else {
				print('You already have elf DNA');
		}
		case 'construct':
			if ((have_effect($effect[1588]) == 0) && (available_amount($item[7386]) == 0) && (get_property('dnaSyringe') == 'construct'))	{
			cli_execute('camp dnapotion 1');
			if (available_amount($item[7386]) == 0) {
				error('something went wrong getting your gene tonic');
			}
			else {
				print('successfully created gene tonic: construct');
			}
		} else {
				print('You already have construct DNA');
		}
		case 'pirate':
			if ((have_effect($effect[1598]) == 0) && (available_amount($item[7396]) == 0) && (get_property('dnaSyringe') == 'pirate'))	{
			cli_execute('camp dnapotion 1');
			if (available_amount($item[7396]) == 0) {
				error('something went wrong getting your gene tonic');
			}
			else {
				print('successfully created gene tonic: pirate');
			}
		} else {
				print('You already have pirate DNA');
		}
	}
}
		

void synthesis_effect(effect ef, item it1, item it2) {
    if (have_effect(ef) == 0) {
        sweet_synthesis(it1, it2);
    } else {
        print('Already have effect ' + ef.name + '.');
    }
}

effect[int] tail(effect[int] arr) {
    effect[int] result;
    foreach idx in arr {
        if (idx > 0) {
            result[idx - 1] = arr[idx];
        }
    }
    return result;
}

int[item] with(int[item] map, item it1) {
    int[item] result;
    foreach it in map {
        result[it] = map[it];
    }
    result[it1]++;
    return result;
}

int[item] with(int[item] map, item it1, item it2) {
    int[item] result;
    foreach it in map {
        result[it] = map[it];
    }
    result[it1]++;
    result[it2]++;
    return result;
}

record candy_pair {
    boolean success;
    int[item] used;
    item it1;
    item it2;
};

boolean[item] npc_candies = $items[jaba&ntilde;ero-flavored chewing gum, lime-and-chile-flavored chewing gum, pickle-flavored chewing gum, tamarind-flavored chewing gum];

boolean[item] candy_forms(item candy) {
    boolean[item] result = { candy: true };
    if (candy == $item[peppermint sprout]) {
        result[$item[peppermint twist]] = true;
    }
    return result;
}

// This is a simple backtracking algorithm to find a way to use our candy to synthesize the things we want.
candy_pair synthesis_plan(effect ef, int[item] candies, effect[int] subsequent, int[item] used) {
    if (ef == $effect[none]) {
        candy_pair result;
        result.success = true;
        return result;
    }

    print('Looking for solutions for effect ' + ef.name + '.');
    foreach it1 in candies {
        int count1 = candies[it1] - used[it1];
        if (count1 == 0) continue;

        foreach form1 in candy_forms(it1) {
            if ($effects[Synthesis: Strong, Synthesis: Smart, Synthesis: Cool, Synthesis: Hardy, Synthesis: Energy] contains ef) {
                // Complex + Simple
                foreach it2 in npc_candies {
                    if (sweet_synthesis_result(form1, it2) != ef) continue;
                    int[item] new_used = with(used, it1);
                    candy_pair next_pair = synthesis_plan(subsequent[0], candies, tail(subsequent), new_used);
                    if (next_pair.success) {
                        print('>> PLAN: For effect ' + ef.name + ', ' + form1.name + ' and ' + it2.name + '.');
                        candy_pair result;
                        result.success = true;
                        result.used = new_used;
                        result.it1 = form1;
                        result.it2 = it2;
                        return result;
                    }
                }
            } else {
                // Complex + Complex
                foreach it2 in candies {
                    if (it2 == it1 && count1 == 1) continue;
                    int count2 = candies[it2] - used[it2];
                    if (count2 == 0) continue;

                    foreach form2 in candy_forms(it2) {
                        if (sweet_synthesis_result(form1, form2) != ef) continue;

                        print('> Testing pair ' + form1.name + ' ' + form2.name + '.');
                        int[item] new_used = with(used, it1, it2);
                        candy_pair next_pair = synthesis_plan(subsequent[0], candies, tail(subsequent), new_used);
                        if (next_pair.success) {
                            print('>> PLAN: For effect ' + ef.name + ', ' + form1.name + ' and ' + form2.name + '.');
                            candy_pair result;
                            result.success = true;
                            result.used = new_used;
                            result.it1 = form1;
                            result.it2 = form2;
                            return result;
                        }
                    }
                }
            }
        }
    }

    // Didn't find a working configuration.
    candy_pair result;
    result.success = false;
    return result;
}

// Only necessary for complex-candy synthesis, since we can get simple candy from Gno-Mart.
void synthesis_plan(effect ef, effect[int] subsequent) {
    if (have_effect(ef) == 0) {
        print('');
        print('Finding candies for ' + ef.name + '.');

        int[item] candies;
        int[item] inventory = get_inventory();
        foreach it in inventory {
            if (it.candy_type == 'complex') {
                candies[it] = inventory[it];
            }
        }

        int[item] empty;
        candy_pair pair = synthesis_plan(ef, candies, subsequent, empty);
        if (pair.success) {
            // This should turn any peppermint sprouts into peppermint twists.
            retrieve_item(1, pair.it1);
            if (npc_candies contains pair.it2) {
                // Buy NPC candy if necessary.
                ensure_item(1, pair.it2);
            } else {
                // This should turn any peppermint sprouts into peppermint twists.
                retrieve_item(1, pair.it2);
            }
            sweet_synthesis(pair.it1, pair.it2);
        } else {
            error('Failed to synthesisze effect ' + ef.name + '. Please plan it out and re-run me.');
        }
    } else {
        print('Already have effect ' + ef.name + '.');
    }
}

void shrug(effect ef) {
    if (have_effect(ef) > 0) {
        cli_execute('shrug ' + ef.name);
    }
}

// We have Stevedave's, Ur-Kel's on at all times during leveling (managed via mood); third and fourth slots are variable.
boolean[effect] song_slot_3 = $effects[Power Ballad of the Arrowsmith, The Magical Mojomuscular Melody, The Moxious Madrigal, Ode to Booze, Jackasses' Symphony of Destruction];
boolean[effect] song_slot_4 = $effects[Carlweather's Cantata of Confrontation, The Sonata of Sneakiness, Fat Leon's Phat Loot Lyric, Polka of Plenty];
void open_song_slot(effect song) {
    boolean[effect] song_slot;
    if (song_slot_3 contains song) song_slot = song_slot_3;
    else if (song_slot_4 contains song) song_slot = song_slot_4;
    foreach shruggable in song_slot {
        shrug(shruggable);
    }
}

void ensure_song(effect ef) {
    if (have_effect(ef) == 0) {
        open_song_slot(ef);
        if (!cli_execute(ef.default) || have_effect(ef) == 0) {
            error('Failed to get effect ' + ef.name + '.');
        }
    } else {
        print('Already have effect ' + ef.name + '.');
    }
}

void ensure_ode(int turns) {
    while (have_effect($effect[Ode to Booze]) < turns) {
        ensure_mp_tonic(50);
        open_song_slot($effect[Ode to Booze]);
        use_skill(1, $skill[The Ode to Booze]);
    }
}

boolean summon_bricko_oyster(int max_summons) {
    if (get_property_int('_brickoFights') >= 3) return false;
    if (available_amount($item[BRICKO oyster]) > 0) return true;
    while (get_property_int('libramSummons') < max_summons && (available_amount($item[BRICKO eye brick]) < 1 || available_amount($item[BRICKO brick]) < 8)) {
        use_skill(1, $skill[Summon BRICKOs]);
    }
    return use(8, $item[BRICKO brick]);
}

void fight_sausage_if_guaranteed() {
    if (sausage_fight_guaranteed()) {
        equip($item[Iunion Crown]);
        equip($slot[shirt], $item[none]);
        equip($item[Fourth of May Cosplay Saber]);
        equip($item[Kramco Sausage-o-Matic&trade;]);
        equip($item[old sweatpants]);
        equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
        equip($slot[acc2], $item[Powerful Glove]);
        equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);

        use_default_familiar();

        adventure_kill($location[The Neverending Party]);
    }
}

boolean stat_ready() {
    // Synth, Ben-Gal balm, Rage of the Reindeer, Quiet Determination, wad of used tape, Brutal brogues
    float muscle_multiplier = 5.2;
    int buffed_muscle = max(60 + (1 + numeric_modifier('muscle percent') / 100 + muscle_multiplier) * my_basestat($stat[Mysticality]), my_buffedstat($stat[Muscle]));
    boolean muscle_met = buffed_muscle - my_basestat($stat[Muscle]) >= 1770;
    print('Buffed muscle: ' + floor(buffed_muscle) + ' (' + muscle_met + ')');
    // Synth, Hair spray, runproof mascara, Quiet Desperation, wad of used tape, Beach Comb, Beach Comb buff
    float moxie_multiplier = 4.7;
    int buffed_moxie = max(60 + (1 + numeric_modifier('moxie percent') / 100 + 3.9) * my_basestat($stat[Mysticality]), my_buffedstat($stat[Moxie]));
    boolean moxie_met = buffed_moxie - my_basestat($stat[Moxie]) >= 1770;
    print('Buffed moxie: ' + floor(buffed_moxie) + ' (' + moxie_met + ')');
    return muscle_met && moxie_met;
}

boolean test_done(int test_num) {
    print('Checking test ' + test_num + '...');
    string text = visit_url('council.php');
    return !text.contains_text('<input type=hidden name=option value=' + test_num + '>');
}

void do_test(int test_num) {
    if (!test_done(test_num)) {
        visit_url('choice.php?whichchoice=1089&option=' + test_num);
        if (!test_done(test_num)) {
            error('Failed to do test ' + test_num + '. Maybe we are out of turns.');
        }
    } else {
        print('Test ' + test_num + ' already completed.');
    }
}

// Don't buy stuff from NPC stores.
set_property('_saved_autoSatisfyWithNPCs', get_property('autoSatisfyWithNPCs'));
set_property('autoSatisfyWithNPCs', 'false');

// Do buy stuff from coinmasters (hermit).
set_property('_saved_autoSatisfyWithCoinmasters', get_property('autoSatisfyWithCoinmasters'));
set_property('autoSatisfyWithCoinmasters', 'true');

// Initialize council.
visit_url('council.php');

// All combat handled by our consult script (hccs_combat.ash).
cli_execute('ccs bean-hccs');

// Turn off Lil' Doctor quests.
set_choice(1340, 3);

// Default equipment.
equip($item[Iunion Crown]);
equip($slot[shirt], $item[none]);
equip($item[vampyric cloake]);
equip($item[Fourth of May Cosplay Saber]);
// equip($item[Kramco Sausage-o-Matic&trade;]);
equip($item[old sweatpants]);
equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
equip($slot[acc2], $item[Powerful Glove]);
equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);

if (!test_done(TEST_COIL_WIRE)) {
    // Ice house remaindered skeleton
    // Ceiling fan, juice bar, foreign language tapes, paint sk8 gnome
    // Sauceror, Opossum, Astral 6-pack, pet sweater
    // Clanmate fortunes (could do BAFH/CheeseFax)
    set_clan("Bonus Adventures from Hell");
    if (get_property_int('_clanFortuneConsultUses') < 3) {
        while (get_property_int('_clanFortuneConsultUses') < 3) {
            cli_execute('fortune cheesefax');
            cli_execute('wait 5');
        }
    }

    if (my_level() == 1 && my_spleen_use() == 0) {
        while (get_property_int('_universeCalculated') < get_property_int('skillLevel144')) {
            cli_execute('numberology 69');
        }
    }
    
    // retrieve_item(1, $item[fish hatchet]);

	// get cowboy boots
	visit_url('place.php?whichplace=town_right&action=townright_ltt');

    // Chateau piggy bank
    visit_url('place.php?whichplace=chateau&action=chateau_desk1');
    // autosell(1, $item[gremlin juice]);
    // autosell(1, $item[ectoplasm <i>au jus</i>]);
    // autosell(1, $item[clove-flavored lip balm]);

    // Sell pork gems + tent
    visit_url('tutorial.php?action=toot');
    try_use(1, $item[letter from King Ralph XI]);
    try_use(1, $item[pork elf goodies sack]);
    autosell(5, $item[baconstone]);
    autosell(5, $item[porquoise]);
    autosell(5, $item[hamethyst]);

    // Buy toy accordion
    ensure_item(1, $item[toy accordion]);

	// make pantogram pants for hilarity and spell damage
    if (available_amount($item[pantogram pants]) == 0) {
        retrieve_item(1, $item[ten-leaf clover]);
	    cli_execute('pantogram hot|hilarity|silent');
    }

    ensure_song($effect[The Magical Mojomuscular Melody]);
   
    if (have_effect($effect[Inscrutable Gaze]) == 0) {
        ensure_mp_tonic(10);
        ensure_effect($effect[Inscrutable Gaze]);
    }

    // Campsite
    if (have_effect($effect[That\'s Just Cloud-Talk, Man]) == 0) {
        visit_url('place.php?whichplace=campaway&action=campaway_sky');
    }

    // Depends on Ez's Bastille script.
    cli_execute('bastille myst brutalist'); 

    // Upgrade saber for fam wt
    visit_url('main.php?action=may4');
    run_choice(4);

    // Put on some regen gear
    equip($item[Iunion Crown]);
    equip($slot[shirt], $item[none]);
    equip($item[Fourth of May Cosplay Saber]);
    // equip($item[Kramco Sausage-o-Matic&trade;]);
    equip($item[old sweatpants]);
    equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
    equip($slot[acc2], $item[Powerful Glove]);
    equip($slot[acc3], $item[Retrospecs]);

    ensure_create_item(1, $item[borrowed time]);
    use(1, $item[borrowed time]);

    // NOTE: No turn 0 sausage fight!

    // QUEST - Coil Wire
    do_test(TEST_COIL_WIRE);
}

if (my_turncount() < 60) error('Something went wrong coiling wire.');

if (!test_done(TEST_HP)) {
    
    // Campsite
    if (have_effect($effect[That\'s Just Cloud-Talk, Man]) == 0) {
        visit_url('place.php?whichplace=campaway&action=campaway_sky');
    }

	// Grab fish hatchett here, for fam wt, -combat, and muscle tests
	retrieve_item(1, $item[fish hatchet]);
	
    // pulls wrench from deck
	if(get_property_int('_deckCardsDrawn') == 0) {
		// cli_execute('cheat buff items');
		// cli_execute('cheat rope');
		cli_execute('cheat wrench');
	}

    cli_execute('call detective_solver.ash');
	buy(1, $item[shoe gum]);
	
	// learn extract and digitize
	cli_execute('terminal educate extract');
	cli_execute('terminal educate digitize');

    item love_potion = $item[Love Potion #0];
    effect love_effect = $effect[Tainted Love Potion];
    if (have_effect(love_effect) == 0) {
        if (available_amount(love_potion) == 0) {
            use_skill(1, $skill[Love Mixology]);
        }
        visit_url('desc_effect.php?whicheffect=' + love_effect.descid);
        if (love_effect.numeric_modifier('mysticality') > 10
                && love_effect.numeric_modifier('muscle') > -30
                && love_effect.numeric_modifier('moxie') > -30
                && love_effect.numeric_modifier('maximum hp percent') > -0.001) {
            use(1, love_potion);
        }
    }

    // Boxing Daycare
    ensure_effect($effect[Uncucumbered]);

    // Cast inscrutable gaze
    ensure_effect($effect[Inscrutable Gaze]);

    // Shower lukewarm
    ensure_effect($effect[Thaumodynamic]);

    // Beach Comb
    ensure_effect($effect[You Learned Something Maybe!]);

    // Get beach access.
    if (available_amount($item[bitchin\' meatcar]) == 0) {
        ensure_item(1, $item[cog]);
        ensure_item(1, $item[sprocket]);
        ensure_item(1, $item[spring]);
        ensure_item(1, $item[empty meat tank]);
        ensure_item(1, $item[sweet rims]);
        ensure_item(1, $item[tires]);
        create(1, $item[bitchin' meatcar]);
    }

    // Depends on Ez's Bastille script.
    cli_execute('bastille myst brutalist');

    // if (get_property('_horsery') != 'crazy horse') cli_execute('horsery crazy');

    // Tune moon sign to Blender. Have to do this now to get chewing gum.
    if (!get_property_boolean('moonTuned')) {
        if (get_property_int('_campAwaySmileBuffs') == 0) {
            // See if we can get Smile of the Blender before we tune.
            visit_url('place.php?whichplace=campaway&action=campaway_sky');
        }

        // Unequip spoon.
        equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
        equip($slot[acc2], $item[Powerful Glove]);
        equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);

        // Actually tune the moon.
        visit_url('inv_use.php?whichitem=10254&doit=96&whichsign=8');
    }

	cli_execute('retrocape mysticality thrill');
	
	// cross streams for a stat boost
	if (!get_property_boolean('_streamsCrossed')) {
		cli_execute('crossstreams');
	}

    equip($item[Iunion Crown]);
    equip($slot[shirt], $item[none]);
	equip($item[10647]); //retrocape
    equip($item[Fourth of May Cosplay Saber]);
    // equip($item[Kramco Sausage-o-Matic&trade;]);
    equip($item[old sweatpants]);
    equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
    equip($slot[acc2], $item[Powerful Glove]);
    equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);

    if (get_property_int('_brickoFights') == 0 && summon_bricko_oyster(7) && available_amount($item[BRICKO oyster]) > 0) {
        if (available_amount($item[bag of many confections]) > 0) error('We should not have a bag yet.');
        use_familiar($familiar[Stocking Mimic]);
        equip($slot[familiar], $item[none]);
        if (my_hp() < .8 * my_maxhp()) {
            visit_url('clan_viplounge.php?where=hottub');
        }
        ensure_mp_tonic(32);
        set_hccs_combat_mode(MODE_OTOSCOPE);
        use(1, $item[BRICKO oyster]);
        autosell(1, $item[BRICKO pearl]);
        set_hccs_combat_mode(MODE_NULL);
    }

    // Prep Sweet Synthesis.
    if (my_garden_type() == 'peppermint') {
        cli_execute('garden pick');
    } else {
        print('WARNING: This script is built for peppermint garden. Switch gardens or find other candy.');
    }

    if (get_property_int('_candySummons') == 0) {
        use_skill(1, $skill[Summon Crimbo Candy]);
    }

    // This is the sequence of synthesis effects; synthesis_plan will, if possible, come up with a plan for allocating candy to each of these.
    effect[int] subsequent = { $effect[Synthesis: Smart], $effect[Synthesis: Strong], $effect[Synthesis: Cool], $effect[Synthesis: Collection] };
    synthesis_plan($effect[Synthesis: Learning], subsequent);
    synthesis_plan($effect[Synthesis: Smart], tail(subsequent));

    if (round(numeric_modifier('mysticality experience percent')) < 100) {
        error('Insufficient +stat%.');
    }

    // Use ten-percent bonus
    try_use(1, $item[a ten-percent bonus]);

	// Scavenge for gym equipment
	if (get_property("_daycareGymScavenges").to_int() < 1) {
            visit_url("/place.php?whichplace=town_wrong&action=townwrong_boxingdaycare");
            string pg = run_choice(3);
            if (pg.contains_text("[free]")) run_choice(2);
            run_choice(5);
            run_choice(4);
	}
	
	// ensure_effect($effect[hulkien]);
    ensure_effect($effect[Favored by Lyle]);
    ensure_effect($effect[Starry-Eyed]);
    ensure_effect($effect[Triple-Sized]);
    ensure_effect($effect[Feeling Excited]);
    ensure_song($effect[The Magical Mojomuscular Melody]);
    ensure_npc_effect($effect[Glittering Eyelashes], 5, $item[glittery mascara]);
	
    // Plan is for Beach Comb + PK buffs to fall all the way through to item -> hot res -> fam weight.
    ensure_effect($effect[Fidoxene]);
    ensure_effect($effect[Do I Know You From Somewhere?]);

	// uses familiar jacks to get camel equipment
	if ((available_amount($item[10580]) == 0) && (get_property_int('tomeSummons') < 3)) {
		cli_execute('create 1 box of familiar jacks');
		use_familiar($familiar[melodramedary]);
		use(1, $item[box of familiar jacks]);
		equip($item[dromedary drinking helmet]);
	}
	
	// 10 snojo fights to while +stat is on, also getting ice wine
	if (get_property('_snojoFreeFights').to_int()<10) {
		use_familiar($familiar[garbage fire]);
		set_property('choiceAdventure1310', '3'); // moxie for ice wine, because it sells for more
		visit_url("place.php?whichplace=snojo&action=snojo_controller");
		if ((available_amount($item[gene tonic: construct]) == 0) && (get_property('dnaSyringe') != 'construct')) {
			adventure_macro($location[The X-32-F Combat Training Snowman],
            m_new().m_item($item[DNA extraction syringe]).m_skill($skill[saucestorm]).m_repeat());
			gene_tonic('construct');
		}
		set_hccs_combat_mode(MODE_KILL);
		while (get_property('_snojoFreeFights').to_int()<5) {
			adv1($location[The X-32-F Combat Training Snowman],-1,"");
		}
		use_familiar($familiar[Melodramedary]);
		equip($item[dromedary drinking helmet]);
		while (get_property('_snojoFreeFights').to_int()<10) {
			adv1($location[The X-32-F Combat Training Snowman],-1,"");
		}
		set_hccs_combat_mode(MODE_NULL);
	}
	if (available_amount($item[burning newspaper]) > 0) {
		cli_execute('create 1 burning paper crane');
	}
	
	// Don't use Kramco here.
    equip($slot[off-hand], $item[none]);
	
	if ((have_effect($effect[holiday yoked]) == 0) && (get_property_int('_kgbTranquilizerDartUses') < 3)) {
		equip($slot[acc1], $item[kremlin\'s greatest briefcase]);
		use_familiar($familiar[ghost of crimbo carols]);
		adventure_macro($location[noob cave],
            m_new().m_skill($skill[KGB tranquilizer dart]).m_repeat());
	}

    // Chateau rest
    while (get_property_int('timesRested') < total_free_rests()) {
        visit_url('place.php?whichplace=chateau&action=chateau_restbox');
    }

    while (summon_bricko_oyster(11) && available_amount($item[BRICKO oyster]) > 0) {
        use_default_familiar();
        if (my_hp() < .8 * my_maxhp()) {
            visit_url('clan_viplounge.php?where=hottub');
        }
        ensure_mp_tonic(32);
        set_hccs_combat_mode(MODE_OTOSCOPE);
        use(1, $item[BRICKO oyster]);
        autosell(1, $item[BRICKO pearl]);
        set_hccs_combat_mode(MODE_NULL);
    }

    ensure_effect($effect[Song of Bravado]);

    if (available_amount($item[flask of baconstone juice]) > 0) {
        ensure_effect($effect[Baconstoned]);
    }

    if (get_property('boomBoxSong') != 'Total Eclipse of Your Meat') {
        cli_execute('boombox meat');
    }

    // Get buff things
    ensure_sewer_item(1, $item[turtle totem]);
    ensure_sewer_item(1, $item[saucepan]);

    // Don't use Kramco here.
    equip($slot[off-hand], $item[none]);

/*
    // Tomato in pantry (free kill)
    if (available_amount($item[tomato juice of powerful power]) == 0 && available_amount($item[tomato]) == 0 && have_effect($effect[Tomato Power]) == 0) {
        cli_execute('mood apathetic');
        use_default_familiar();

        ensure_effect($effect[Musk of the Moose]);
        ensure_effect($effect[Carlweather's Cantata of Confrontation]);
        ensure_effect($effect[Singer's Faithful Ocelot]);
        ensure_song($effect[Fat Leon's Phat Loot Lyric]);
        ensure_mp_tonic(150); // For Snokebomb and Shattering Punch.

        find_monster_then($location[The Haunted Pantry], $monster[possessed can of tomatoes], m_new().m_skill($skill[Shattering Punch]));
        if (available_amount($item[tomato]) == 0) error("No tomato!");
    }
*/

    // Fruits in skeleton store (Saber YR)
    boolean missing_ointment = available_amount($item[ointment of the occult]) == 0 && available_amount($item[grapefruit]) == 0 && have_effect($effect[Mystically Oiled]) == 0;
    boolean missing_oil = available_amount($item[oil of expertise]) == 0 && available_amount($item[cherry]) == 0 && have_effect($effect[Expert Oiliness]) == 0;
    if (my_class() != $class[Pastamancer] && (missing_oil || missing_ointment)) {
        cli_execute('mood apathetic');

        if (get_property('questM23Meatsmith') == 'unstarted') {
            // Have to start meatsmith quest.
            visit_url('shop.php?whichshop=meatsmith&action=talk');
            run_choice(1);
        }
        if (!can_adv($location[The Skeleton Store], false)) error('Cannot open skeleton store!');
        adv1($location[The Skeleton Store], -1, '');
        if (!$location[The Skeleton Store].noncombat_queue.contains_text('Skeletons In Store')) {
            error('Something went wrong at skeleton store.');
        }
        find_monster_saber_yr($location[The Skeleton Store], $monster[novelty tropical skeleton]);
    } 

	// become a human fish hybrid
	if ((get_property_boolean('_dnaHybrid') == false) && (get_property('dnaSyringe') != 'fish')) {
		ensure_effect($effect[ode to booze]);
		use_familiar($familiar[frumious bandersnatch]);
		set_hccs_combat_mode(MODE_NULL);
		set_auto_attack('HCCS_DNA_RUN');
		// if (split_string($location[Barf Mountain].noncombat_queue, ";")) 
		adv1($location[The Bubblin\' Caldera], -1, '');
		adv1($location[The Bubblin\' Caldera], -1, '');
		c2t_cartographyHunt($location[The Bubblin\' Caldera], $monster[1797]); // maps for a fish
		run_combat();
		use_default_familiar();
		cli_execute('hottub'); // removing lava effect
		set_auto_attack(0);
	}
	
	if ((get_property_boolean('_dnaHybrid') == false) && (get_property('dnaSyringe') == 'fish')) {
		cli_execute('camp dnainject');
	}	

	// Get inner elf for levelling
/*	if ((have_effect($effect[inner elf]) == 0) && (get_property_int('_kgbTranquilizerDartUses') < 3)) {        	
		cli_execute("/whitelist hobopolis vacation home");
		ensure_effect($effect[blood bubble]);
		use_familiar($familiar[machine elf]);
		set_hccs_combat_mode(MODE_CUSTOM,
            m_new()
                .m_skill($skill[KGB tranquilizer dart]));
		set_property('choiceAdventure326', '1');
		adv1($location[The Slime Tube], -1, '');
		use_default_familiar();
		set_hccs_combat_mode(MODE_NULL);
		cli_execute("/whitelist alliance from hell"); 
	}	else {
		 print('Something went wrong with getting inner elf');
	}
*/
    if (!get_property_boolean('hasRange')) {
        ensure_item(1, $item[Dramatic&trade; range]);
        use(1, $item[Dramatic&trade; range]);
    }
	
    use_skill(1, $skill[Advanced Saucecrafting]);
	use_skill(1, $skill[Prevent Scurvy and Sobriety]);
	
    ensure_potion_effect($effect[Mystically Oiled], $item[ointment of the occult]);

    // Maximize familiar weight
	cli_execute('fold makeshift garbage shirt');
    equip($item[makeshift garbage shirt]);
    equip($item[Fourth of May Cosplay Saber]);
	equip($slot[off-hand], $item[none]);
    equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
    equip($slot[acc2], $item[Brutal brogues]);
    equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);

    cli_execute('mood hccs');
	
    // LOV tunnel for elixirs, epaulettes, and heart surgery
    if (!get_property_boolean('_loveTunnelUsed')) {
        use_default_familiar();        
        ensure_effect($effect[carol of the bulls]);
        ensure_effect($effect[carol of the hells]);
        set_choice(1222, 1); // Entrance
        set_choice(1223, 1); // Fight LOV Enforcer
        set_choice(1224, 2); // LOV Epaulettes
        set_choice(1225, 1); // Fight LOV Engineer
        set_choice(1226, 2); // Open Heart Surgery
        set_choice(1227, 1); // Fight LOV Equivocator
        set_choice(1228, 3); // Take chocolate
        set_auto_attack('HCCS_LOV_tunnel');
        adv1($location[The Tunnel of L.O.V.E.], -1, "");
        set_auto_attack(0);
    }

    equip($item[LOV epaulettes]);

	// spend 5 turns in DMT, getting abstraction: joy and hopefully certainty	
    while (get_property('_machineTunnelsAdv') < 5) {
		use_familiar($familiar[machine elf]);
		set_hccs_combat_mode(MODE_NULL);
		if ((available_amount($item[abstraction: thought]) == 0) && (available_amount($item[abstraction: certainty]) == 0) && (get_property('_machineTunnelsAdv') < 5)) {
			set_auto_attack('melfgetthought');
			adv1($location[the deep machine tunnels], -1, "");
            set_auto_attack(0);
		} else if  ((available_amount($item[abstraction: thought]) >= 1) && (available_amount($item[abstraction: certainty]) == 0) && (get_property('_machineTunnelsAdv') < 5)) {
			set_auto_attack('melfgetcertainty');
			adv1($location[the deep machine tunnels], -1, "");
            set_auto_attack(0);
		} else {
		    adventure_kill($location[the deep machine tunnels]);
        }
    }

	use_default_familiar();

	//witchess fights
    if(get_campground() contains $item[Witchess Set] && get_property("_witchessFights").to_int() < 5) {
		equip($item[fourth of may cosplay saber]);
        use_default_familiar();
		while(get_property("_witchessFights").to_int() < 2) {
	    set_hccs_combat_mode(MODE_KILL);
            visit_url("campground.php?action=witchess");
            run_choice(1);
            visit_url("choice.php?option=1&pwd="+my_hash()+"&whichchoice=1182&piece=1942", false);
            run_combat();
            set_hccs_combat_mode(MODE_NULL);
	}
        while(get_property("_witchessFights").to_int() == 2) { // fight a witchess king for dented scepter
			set_auto_attack('witchess witch');
			ensure_effect($effect[carol of the bulls]);
            visit_url("campground.php?action=witchess");
            run_choice(1);
            visit_url("choice.php?option=1&pwd="+my_hash()+"&whichchoice=1182&piece=1940", false);
            run_combat();
            set_auto_attack(0);
        }
		while(get_property("_witchessFights").to_int() == 3) { // fight a witchess witch for battle broom
			set_auto_attack('witchess witch');
			ensure_effect($effect[carol of the bulls]);
            visit_url("campground.php?action=witchess");
            run_choice(1);
            visit_url("choice.php?option=1&pwd="+my_hash()+"&whichchoice=1182&piece=1941", false);
            run_combat();
            set_auto_attack(0);
        }
    }

	// get witchess buff, this should fall all the way through to fam wt
	if (have_effect($effect[puzzle champ]) == 0) {
		cli_execute('witchess');
	}

    // Professor 9x free sausage fight @ NEP
    if (get_property_int('_sausageFights') == 0) {
        use_familiar($familiar[Pocket Professor]);
        try_equip($item[Pocket Professor memory chip]);
        equip($item[Kramco Sausage-o-Matic&trade;]);
        equip($slot[acc2], $item[Brutal brogues]);
        equip($slot[acc3], $item[Beach Comb]);

        while (get_property_int('_sausageFights') == 0) {
            if (my_hp() < .8 * my_maxhp()) {
                visit_url('clan_viplounge.php?where=hottub');
            }

            // Just here to party.
            set_choice(1322, 2);
            adventure_copy($location[The Neverending Party], $monster[sausage goblin]);
        }
    } else {
		error('YOU FUCKED UP THE KRAMCO CHAIN AGAIN, YOU DUMBASS! Go kill crayon elves instead.');
	}

    // Breakfast

    // Visiting Looking Glass in clan VIP lounge
    visit_url('clan_viplounge.php?action=lookingglass&whichfloor=2');
    cli_execute('swim item');
    while (get_property_int('_genieWishesUsed') < 3) {
        cli_execute('genie wish for more wishes');
    }

    // Visiting the Ruined House
    //  visit_url('place.php?whichplace=desertbeach&action=db_nukehouse');

    use_skill(1, $skill[Advanced Cocktailcrafting]);
    use_skill(1, $skill[Pastamastery]);
    use_skill(1, $skill[Spaghetti Breakfast]);
    use_skill(1, $skill[Grab a Cold One]);
    use_skill(1, $skill[Acquire Rhinestones]);
    use_skill(1, $skill[Perfect Freeze]);
	use_skill(1, $skill[summon kokomo resort pass]);
	autosell(1, $item[kokomo resort pass]);
    autosell(3, $item[coconut shell]);
    autosell(3, $item[magical ice cubes]);
    autosell(3, $item[little paper umbrella]);

    // Autosell stuff
    // autosell(1, $item[strawberry]);
    // autosell(1, $item[orange]);
    autosell(1, $item[razor-sharp can lid]);
    // autosell(5, $item[red pixel]);
    autosell(5, $item[green pixel]);
    autosell(5, $item[blue pixel]);
    autosell(5, $item[white pixel]);


    if (have_effect($effect[Carlweather\'s Cantata of Confrontation]) > 0) {
        cli_execute('shrug Carlweather\'s Cantata of Confrontation');
    }

    cli_execute('mood hccs');

    use_familiar($familiar[God Lobster]);
    while (get_property('_godLobsterFights') < 2) {
        // Get equipment from the fight.
        set_property('choiceAdventure1310', '1');
        try_equip($item[God Lobster\'s Scepter]);
        visit_url('main.php?fightgodlobster=1');
        set_hccs_combat_mode(MODE_KILL);
        run_combat();
        visit_url('choice.php');
        if (handling_choice()) run_choice(1);
        set_hccs_combat_mode(MODE_NULL);
    }

    if (get_property("_witchessFights").to_int() == 4) { // fight a witchess queen for pointy crown
			set_auto_attack('witchess witch');
			ensure_effect($effect[carol of the bulls]);
            visit_url("campground.php?action=witchess");
            run_choice(1);
            visit_url("choice.php?option=1&pwd="+my_hash()+"&whichchoice=1182&piece=1939", false);
            run_combat();
            set_auto_attack(0);
        }

    use_default_familiar();

    equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);

    // 17 free NEP fights
    while ((get_property_int('_neverendingPartyFreeTurns') < 10)
            || (have_skill($skill[Chest X-Ray]) && get_property_int('_chestXRayUsed') < 3)
            || (have_skill($skill[Gingerbread Mob Hit]) && !get_property_boolean('_gingerbreadMobHitUsed'))) {
        ensure_npc_effect($effect[Glittering Eyelashes], 5, $item[glittery mascara]);
        ensure_song($effect[The Magical Mojomuscular Melody]);
        ensure_song($effect[Polka of Plenty]);
		ensure_effect($effect[inscrutable gaze]);
		ensure_effect($effect[pride of the puffin]);
		ensure_effect($effect[drescher\'s annoying noise]);
        ensure_song($effect[ur-kel\'s aria of annoyance]);
        ensure_effect($effect[Feeling Excited]);
		
        cli_execute('mood execute');
        
        /* if (have_effect($effect[Tomes of Opportunity]) == 0) {
            // NEP noncombat. Get stat buff if we don\'t have it. This WILL spend an adventure if we\'re out.
            set_choice(1324, 1);
            set_choice(1325, 2);
        } else { */
        // Otherwise fight.
        set_choice(1324, 5);
        // }

        ensure_mp_sausage(100);
        if ((get_property_int('_neverendingPartyFreeTurns') < 10) && (get_property_int('_feelPrideUsed') < 3)) {
            set_hccs_combat_mode(MODE_FEEL_PRIDE);
            adv1($location[The Neverending Party], -1, '');
            set_hccs_combat_mode(MODE_NULL);
        } else if (get_property_int('_neverendingPartyFreeTurns') < 10) {
            adventure_kill($location[The Neverending Party]);
        } else {
            adventure_free_kill($location[The Neverending Party]);
        }
    }   
/*
    // Spend our free runs finding gobbos. We do this in the Haiku Dungeon since there is a single skippable NC.
    use_familiar($familiar[Frumious Bandersnatch]);

    equip($item[Fourth of May Cosplay Saber]);
    // equip($item[latte lovers member's mug]);
    equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
    equip($slot[acc2], $item[Brutal brogues]);
    equip($slot[acc3], $item[Beach Comb]);

    while (get_property_int('_banderRunaways') < my_familiar_weight() / 5 && !get_property('latteUnlocks').contains_text('chili')) {
        // Find latte ingredient.
        ensure_ode(1);
        adventure_run_unless_free($location[The Haunted Kitchen]);
    }

    while (get_property_int('_banderRunaways') < my_familiar_weight() / 5 && !get_property('latteUnlocks').contains_text('carrot')) {
        // Find latte ingredient.
        ensure_ode(1);
        adventure_run_unless_free($location[The Dire Warren]);
    }

    if (get_property('latteUnlocks').contains_text('chili') && get_property_int('_latteRefillsUsed') == 0) {
        cli_execute('latte refill pumpkin chili carrot');
    }

    // equip($item[fish hatchet]);
    equip($item[Kramco Sausage-o-Matic&trade;]);
    equip($slot[acc1], $item[Lil\' Doctor&trade; Bag]);

    while ((get_property_int('_banderRunaways') < (familiar_weight($familiar[Frumious Bandersnatch]) + weight_adjustment()) / 5)) {
             // Save reflex hammers. || (have_skill($skill[Reflex Hammer]) && get_property_int('_reflexHammerUsed') < 3))) {
        ensure_song($effect[The Sonata of Sneakiness]);
        ensure_effect($effect[Smooth Movements]);
        if (get_property_int('_powerfulGloveBatteryPowerUsed') <= 90) {
            ensure_effect($effect[Invisible Avatar]);
        }
        if (get_property_int('garbageShirtCharge') <= 8) {
            equip($slot[shirt], $item[none]);
        }
        if (get_property_int('_banderRunaways') < my_familiar_weight() / 5) {
            ensure_ode(1);
        } else {
            use_default_familiar();
        }

        // Skip fairy gravy NC
        set_choice(297, 3);
        ensure_mp_sausage(100);
        adventure_run_unless_free($location[The Haiku Dungeon]);
    }

    if (have_effect($effect[The Sonata of Sneakiness]) > 0) cli_execute('uneffect Sonata of Sneakiness');
*/
    equip($item[Fourth of May Cosplay Saber]);
	cli_execute('fold makeshift garbage shirt');
	equip($item[makeshift garbage shirt]);
    use_default_familiar();

    if (get_property('boomBoxSong') != 'These Fists Were Made for Punchin\'') {
        cli_execute('boombox damage');
    }

    // Reset location so maximizer doesn't get confused.
    set_location($location[none]);

    if (my_class() == $class[Pastamancer]) use_skill(1, $skill[Bind Undead Elbow Macaroni]);
    else ensure_potion_effect($effect[Expert Oiliness], $item[oil of expertise]);

    // synthesis_plan($effect[Synthesis: Strong], tail(tail(subsequent)));

    // ensure_effect($effect[Gr8ness]);
    // ensure_effect($effect[Tomato Power]);
    ensure_effect($effect[Song of Starch]);
    ensure_effect($effect[Big]);
    ensure_song($effect[Power Ballad of the Arrowsmith]);
    ensure_effect($effect[Rage of the Reindeer]);
    ensure_effect($effect[Quiet Determination]);
    ensure_effect($effect[Disdain of the War Snapper]);
    ensure_npc_effect($effect[Go Get \'Em, Tiger!], 5, $item[Ben-Gal&trade; balm]);

    use_familiar($familiar[disembodied hand]);

    maximize('hp', false);

    // QUEST - Donate Blood (HP)
    if (my_maxhp() - my_buffedstat($stat[muscle]) - 3 < 1770) {
        error('Not enough HP to cap.');
    }

    do_test(TEST_HP);
}

if (!test_done(TEST_MUS)) {
    if (my_class() == $class[Pastamancer]) use_skill(1, $skill[Bind Undead Elbow Macaroni]);
    else ensure_potion_effect($effect[Expert Oiliness], $item[oil of expertise]);

	if (my_inebriety() == 0) {
		ensure_ode(4);
		try_use(1, $item[astral six-pack]);
		drink(4, $item[astral pilsner]);
	}

    ensure_effect($effect[Big]);
    ensure_effect($effect[Song of Bravado]);
    ensure_song($effect[Stevedave\'s Shanty of Superiority]);
    ensure_song($effect[Power Ballad of the Arrowsmith]);
    ensure_effect($effect[Rage of the Reindeer]);
    ensure_effect($effect[Quiet Determination]);
    ensure_effect($effect[Disdain of the War Snapper]);
    // ensure_effect($effect[Tomato Power]);
    ensure_npc_effect($effect[Go Get \'Em, Tiger!], 5, $item[Ben-Gal&trade; balm]);
    // ensure_effect($effect[Ham-Fisted]);
	create(1, $item[philter of phorce]);
	ensure_effect($effect[Phorcefullness]);
    maximize('muscle', false);
	
	if ((my_class() == $class[Pastamancer]) && ((my_buffedstat($stat[muscle]) - my_basestat($stat[mysticality]) < 1770))) {
        error('Not enough moxie to cap.');
    } else if ((my_buffedstat($stat[muscle]) - my_basestat($stat[muscle]) < 1770)) {
		error('Not enough moxie to cap.');
	}
	
    // cli_execute('modtrace mus');
    // abort();

    do_test(TEST_MUS);
}

if (!test_done(TEST_MYS)) {
    ensure_effect($effect[Big]);
    ensure_effect($effect[Song of Bravado]);
    ensure_song($effect[Stevedave\'s Shanty of Superiority]);
    ensure_song($effect[The Magical Mojomuscular Melody]);
    ensure_effect($effect[Quiet Judgement]);
    // ensure_effect($effect[Tomato Power]);
    ensure_effect($effect[Mystically Oiled]);
    ensure_npc_effect($effect[Glittering Eyelashes], 5, $item[glittery mascara]);
    maximize('mysticality', false);
    if (my_buffedstat($stat[mysticality]) - my_basestat($stat[mysticality]) < 1770) {
        error('Not enough mysticality to cap.');
    }
    do_test(TEST_MYS);
}

if (!test_done(TEST_MOX)) {
    if (my_class() == $class[Pastamancer]) use_skill(1, $skill[Bind Penne Dreadful]);
    else ensure_potion_effect($effect[Expert Oiliness], $item[oil of expertise]);

    effect[int] subsequent = { $effect[Synthesis: Collection] };
    synthesis_plan($effect[Synthesis: Cool], subsequent);

    // Beach Comb
    ensure_effect($effect[Pomp & Circumsands]);

    use(1, $item[Bird-a-Day Calendar]);
    ensure_effect($effect[Blessing of the Bird]);

    // Should be 11% NC and 50% moxie, will fall through to NC test
    ensure_effect($effect[Blessing of your favorite Bird]);

    ensure_effect($effect[Big]);
    ensure_effect($effect[Song of Bravado]);
    ensure_song($effect[Stevedave\'s Shanty of Superiority]);
    ensure_song($effect[The Moxious Madrigal]);
    ensure_effect($effect[Quiet Desperation]);
    // ensure_effect($effect[Tomato Power]);
    ensure_npc_effect($effect[Butt-Rock Hair], 5, $item[hair spray]);
    use(available_amount($item[rhinestone]), $item[rhinestone]);
    if (have_effect($effect[Unrunnable Face]) == 0) {
        try_use(1, $item[runproof mascara]);
    }
    maximize('moxie', false);
    if ((my_class() == $class[Pastamancer]) && ((my_buffedstat($stat[moxie]) - my_basestat($stat[mysticality]) < 1770))) {
        error('Not enough moxie to cap.');
    } else if ((my_buffedstat($stat[moxie]) - my_basestat($stat[moxie]) < 1770)) {
		error('Not enough moxie to cap.');
	}
	
    do_test(TEST_MOX);
}

if (!test_done(TEST_HOT_RES)) {
    ensure_mp_sausage(500);
	use_default_familiar();
    fight_sausage_if_guaranteed();

    // Make sure no moon spoon.
    equip($slot[acc1], $item[Eight Days a Week Pill Keeper]);
    equip($slot[acc2], $item[Powerful Glove]);
    equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);

	if (available_amount($item[heat-resistant gloves]) == 0) {
		cli_execute('mood apathetic');
        adv1($location[LavaCo&trade; Lamp Factory], -1, '');
		equip($item[Fourth of May Cosplay Saber]);
		equip($item[vampyric cloake]);
		set_hccs_combat_mode(MODE_MISTFORM);
        /* set_hccs_combat_mode(MODE_CUSTOM,
            m_new()
                .m_skill($skill[extract])
				.m_skill($skill[Meteor Shower])
				.m_skill($skill[Become a Cloud of Mist])
                .m_skill($skill[Use the Force])); */
        set_property("choiceAdventure1387", "3");
		c2t_cartographyHunt($location[LavaCo&trade; Lamp Factory], $monster[1789]);
		run_combat();
		saber_yr();
		set_hccs_combat_mode(MODE_NULL);
	}
		
    if (have_effect($effect[Synthesis: Hot]) == 0) {
        ensure_item(2, $item[jaba&ntilde;ero-flavored chewing gum]);
        sweet_synthesis($item[jaba&ntilde;ero-flavored chewing gum], $item[jaba&ntilde;ero-flavored chewing gum]);
    }

	// add +5 hot res to KGB, relies on Ezandora's script, naturally
	cli_execute('briefcase e hot');

	// set retrocape to elemental resistance
	cli_execute('retrocape mus hold');


    ensure_effect($effect[Blood Bond]);
    ensure_effect($effect[Leash of Linguini]);
    ensure_effect($effect[Empathy]);
    ensure_effect($effect[feeling peaceful]);

    // Pool buff. This will fall through to fam weight.
    ensure_effect($effect[Billiards Belligerence]);

    /* if (have_effect($effect[Rainbowolin]) == 0) {
        cli_execute('pillkeeper elemental');
    } */

	if ((available_amount($item[metal meteoroid]) > 0) && (available_amount($item[meteorite guard]) == 0)) {
		cli_execute('create 1 meteorite guard');
	}
		

    ensure_item(1, $item[tenderizing hammer]);
    cli_execute('smash * ratty knitted cap');
    cli_execute('smash * red-hot sausage fork');
    autosell(10, $item[hot nuggets]);
    autosell(10, $item[twinkly powder]);

    if (available_amount($item[hot powder]) > 0) {
        ensure_effect($effect[Flame-Retardant Trousers]);
    }

    if (available_amount($item[sleaze powder]) > 0 || available_amount($item[lotion of sleaziness]) > 0) {
        ensure_potion_effect($effect[Sleazy Hands], $item[lotion of sleaziness]);
    }

    // wish for healthy green glow, should fall through
	// wish_effect($effect[healthy green glow]);
	
    ensure_effect($effect[Elemental Saucesphere]);
    ensure_effect($effect[Astral Shell]);

    // Build up 100 turns of Deep Dark Visions for spell damage later.
    while (have_skill($skill[Deep Dark Visions]) && have_effect($effect[Visions of the Deep Dark Deeps]) < 80) {
        if (my_mp() < 20) {
            ensure_create_item(1, $item[magical sausage]);
            eat(1, $item[magical sausage]);
        }
        while (my_hp() < my_maxhp()) {
            use_skill(1, $skill[Cannelloni Cocoon]);
        }
        if (my_mp() < 100) {
            ensure_create_item(1, $item[magical sausage]);
            eat(1, $item[magical sausage]);
        }
        if (round(numeric_modifier('spooky resistance')) < 10) {
            ensure_effect($effect[Does It Have a Skull In There??]);
            if (round(numeric_modifier('spooky resistance')) < 10) {
                abort('Not enough spooky res for Deep Dark Visions.');
            }
        }
        use_skill(1, $skill[Deep Dark Visions]);
    }

	// drink a hot socks, should fall through to fam wt
	/*if (have_effect($effect[1701]) == 0) { // hip to the jive
        if (my_inebriety() > inebriety_limit() - 3) {
            error('Something went wrong. We are too drunk.');
        }
        assert_meat(5000);
        ensure_ode(3);
        cli_execute('drink Hot socks');		
    } */


    // Beach comb buff.
    ensure_effect($effect[Hot-Headed]);

    // Use pocket maze
    if (available_amount($item[pocket maze]) > 0) ensure_effect($effect[Amazing]);

    // if (get_property('_horsery') != 'pale horse') cli_execute('horsery pale');

    // ensure_asdon_effect($effect[Driving Safely]);

    use_familiar($familiar[Exotic Parrot]);
   if (available_amount($item[cracker]) == 0) {
        retrieve_item(1, $item[box of Familiar jacks]);
        use(1, $item[box of Familiar Jacks]);
    }
    equip($item[cracker]);

    // Mafia sometimes can't figure out that multiple +weight things would get us to next tier.
    maximize('hot res, 0.01 familiar weight', false);

/*	if ((have_effect($effect[Rainbowolin]) == 0) && (round(numeric_modifier('hot resistance')) < 59)) {
        cli_execute('pillkeeper elemental');
    }
*/
    if (round(numeric_modifier('hot resistance')) < 59) {
        error('Something went wrong building hot res.');
    }

	// cli_execute('modtrace Hot Resistance');
	// abort();

    do_test(TEST_HOT_RES);

}

if (!test_done(TEST_NONCOMBAT)) {
    if (my_hp() < 30) use_skill(1, $skill[Cannelloni Cocoon]);
    ensure_effect($effect[Blood Bond]);
    ensure_effect($effect[Leash of Linguini]);
    ensure_effect($effect[Empathy]);

    if (get_property('_godLobsterFights') < 3) {
        if (my_hp() < 0.8 * my_maxhp()) use_skill(1, $skill[Cannelloni Cocoon]);
        use_familiar($familiar[God Lobster]);
        // Get -combat buff.
        set_property('choiceAdventure1310', '2');
        equip($item[God Lobster\'s Ring]);
        visit_url('main.php?fightgodlobster=1');
        set_hccs_combat_mode(MODE_KILL);
        run_combat();
        if (handling_choice()) run_choice(2);
        set_hccs_combat_mode(MODE_NULL);
    }
	
	// setting KGB to NC, relies on Ezandora's script
	cli_execute('briefcase e -combat');
	
    // Pool buff. Should fall through to weapon damage.
    ensure_effect($effect[Billiards Belligerence]);

    equip($slot[acc3], $item[Powerful Glove]);
	
	ensure_effect($effect[gummed shoes]);
    ensure_effect($effect[The Sonata of Sneakiness]);
    ensure_effect($effect[Smooth Movements]);
    ensure_effect($effect[Invisible Avatar]);
    ensure_effect($effect[Silent Running]);

    // Rewards
    ensure_effect($effect[Throwing Some Shade]);
    // ensure_effect($effect[A Rose by Any Other Material]);
	
    use_familiar($familiar[Disgeist]);

    // Pastamancer d1 is -combat.
	if (my_class() == $class[pastamancer]) {	
		ensure_effect($effect[Blessing of the Bird]);
	}

    maximize('-combat, 0.01 familiar weight', false);

    if (round(numeric_modifier('combat rate')) > -40) {
        error('Not enough -combat to cap.');
    }
	
	// cli_execute('modtrace combat rate');
	// abort();
	
    do_test(TEST_NONCOMBAT);
}

if (!test_done(TEST_FAMILIAR)) {
    // Get gobbo fight.
    fight_sausage_if_guaranteed();

    // These should have fallen through all the way from leveling.
    ensure_effect($effect[Fidoxene]);
    ensure_effect($effect[Do I Know You From Somewhere?]);

    // Pool buff.
    ensure_effect($effect[Billiards Belligerence]);

    if (my_hp() < 30) use_skill(1, $skill[Cannelloni Cocoon]);
    ensure_effect($effect[Blood Bond]);
    ensure_effect($effect[Leash of Linguini]);
    ensure_effect($effect[Empathy]);
	ensure_effect($effect[robot friends]);
	ensure_effect($effect[human-machine hybrid]);
	
	/* if ((available_amount($item[abstraction: joy]) > 0) && (have_effect($effect[joy]) == 0)) {
		chew($item[abstraction: joy]);
	} */

    if ((available_amount($item[cracker]) > 0) && (get_property_int('tomeSummons') < 3)) {
        // This is the best familiar weight accessory.
        use_familiar($familiar[Exotic Parrot]);
        equip($item[cracker]);
    }

    if (have_effect($effect[Meteor Showered]) == 0) {
        equip($item[Fourth of May Cosplay Saber]);
        adventure_macro($location[The Neverending Party],
            m_new().m_skill($skill[Meteor Shower]).m_skill($skill[Use the Force]));
    }

	use_familiar($familiar[exotic parrot]);
	
    maximize('familiar weight', false);

	// cli_execute('modtrace familiar weight');
	// abort();

    do_test(TEST_FAMILIAR);
}

if (!test_done(TEST_WEAPON)) {
    // Get gobbo fight.
    fight_sausage_if_guaranteed();

	// Get inner elf for weapon damage
	if ((have_effect($effect[inner elf]) == 0) && (get_property_int('_snokebombUsed') < 3)) {        	
		cli_execute("/whitelist hobopolis vacation home");
		ensure_effect($effect[blood bubble]);
		use_familiar($familiar[machine elf]);
		set_hccs_combat_mode(MODE_CUSTOM,
            m_new()
                .m_skill($skill[snokebomb]));
		set_property('choiceAdventure326', '1');
		adv1($location[The Slime Tube], -1, '');
		use_default_familiar();
		set_hccs_combat_mode(MODE_NULL);
		cli_execute("/whitelist alliance from hell"); 
	}	else {
		 print('Something went wrong with getting inner elf');
	}
	
	
	// Paint crayon elf for DNA and ghost buff (Saber YR)
	if (!get_property_boolean('_chateauMonsterFought')) {
        string chateau_text = visit_url('place.php?whichplace=chateau', false);
        matcher m = create_matcher('alt="Painting of a? ([^(]*) .1."', chateau_text);
        if (m.find() && m.group(1) == 'Black Crayon Crimbo Elf') {
            cli_execute('mood apathetic');
			use_familiar($familiar[ghost of crimbo carols]);
            equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);
			if (get_property_int('_reflexHammerUsed') == 3) {
				error('You do not have any banishes left');
			}
            set_hccs_combat_mode(MODE_CUSTOM,
                m_new()
                    .m_item($item[DNA extraction syringe])
                    .m_skill($skill[Reflex Hammer]));
            visit_url('place.php?whichplace=chateau&action=chateau_painting', false);
            run_combat();
			use_default_familiar();
        } else {
            error('Wrong painting.');
        }
		
    }

	gene_tonic('elf');
	ensure_effect($effect[human-elf hybrid]);

// maybe try just setting autoattack to HCCS_Spit

// fax an ungulith to get corrupted marrow, meteor showered, and spit upon (if applicable)
	if ((available_amount($item[corrupted marrow]) == 0) && (have_effect($effect[cowrruption]) == 0)) {
        print('Your camel spit level is ' + get_property('camelSpit'), 'green');
		if (available_amount($item[photocopied monster]) == 0) {
            if (get_property_boolean('_photocopyUsed')) error('Already used fax for the day.');
            cli_execute('/whitelist alliance from hell');
            chat_private('cheesefax', 'fax ungulith');
            for i from 1 to 5 {
                wait(5);
                cli_execute('fax receive');
                if (get_property('photocopyMonster') == 'ungulith') break;
                // otherwise got the wrong monster, put it back.
                cli_execute('fax send');
            }
            if (available_amount($item[photocopied monster]) == 0) error('Failed to fax in ungulith.');
        }
        cli_execute('mood apathetic');
        equip($item[Fourth of May Cosplay Saber]);
		if (get_property_int('camelSpit') == 100) {
			use_familiar($familiar[melodramedary]);
			set_auto_attack('HCCS_Spit');
			/* set_hccs_combat_mode(MODE_CUSTOM,
            m_new()
                .m_skill($skill[extract])
				.m_skill($skill[Meteor Shower])
				.m_skill($skill[spit on me]) // spit on me
                .m_skill($skill[Use the Force])); */
			set_property("choiceAdventure1387", "3");
			use(1, $item[photocopied monster]);
			set_hccs_combat_mode(MODE_NULL);
			set_auto_attack(0);
            cli_execute('set camelSpit = 0');
			use_default_familiar();
		} else {
			print('your camel is not full enough', 'green');
			abort();
			/*set_hccs_combat_mode(MODE_CUSTOM,
				m_new()
					.m_skill($skill[Meteor Shower])
					.m_skill($skill[Use the Force]));
			set_property("choiceAdventure1387", "3");
			use(1, $item[photocopied monster]);
			set_hccs_combat_mode(MODE_NULL); */
		}
    }


    if (have_effect($effect[In a Lather]) == 0) {
        if (my_inebriety() > inebriety_limit() - 2) {
            error('Something went wrong. We are too drunk.');
        }
        assert_meat(500);
        ensure_ode(2);
        cli_execute('drink Sockdollager');
    }

    if (available_amount($item[twinkly nuggets]) > 0) {
        ensure_effect($effect[Twinkly Weapon]);
    }

    ensure_effect($effect[Carol of the Bulls]);
    ensure_effect($effect[Song of the North]);
    ensure_effect($effect[Rage of the Reindeer]);
    ensure_effect($effect[Frenzied, Bloody]);
    // ensure_effect($effect[Scowl of the Auk]);
    ensure_effect($effect[Disdain of the War Snapper]);
    ensure_effect($effect[Tenacity of the Snapper]);
    ensure_song($effect[Jackasses\' Symphony of Destruction]);
    if (available_amount($item[lov elixir \#3]) > 0) {
        ensure_effect($effect[The Power of LOV]);
    }
    

    if (available_amount($item[vial of hamethyst juice]) > 0) {
        ensure_effect($effect[Ham-Fisted]);
    }

	// make KGB set to weapon
	cli_execute('briefcase e weapon');
	
	// wish for pyramid power, should fall through to spell
	// cli_execute('genie effect pyramid power');
	
    // Hatter buff
    /* ensure_item(1, $item[goofily-plumed helmet]);
    ensure_effect($effect[Weapon of Mass Destruction]); */

    // Beach Comb
    if (!get_property('_beachHeadsUsed').contains_text('6')) {
        ensure_effect($effect[Lack of Body-Building]);
    }

    // Boombox potion - did we get one?
    if (available_amount($item[Punching Potion]) > 0) {
        ensure_effect($effect[Feeling Punchy]);
    }

    // Pool buff. Should have fallen through.
    ensure_effect($effect[Billiards Belligerence]);

    // Corrupted marrow
    ensure_effect($effect[Cowrruption]);

    // Pastamancer d1 is weapon damage.
    ensure_effect($effect[Blessing of the Bird]);

    ensure_npc_effect($effect[Engorged Weapon], 1, $item[Meleegra&trade; pills]);

    // wish_effect($effect[Outer Wolf&trade;]);

    // this is just an assert, effectively.
    ensure_effect($effect[Meteor Showered]);

    ensure_effect($effect[Bow-Legged Swagger]);

    // Get flimsy hardwood scraps.
    visit_url('shop.php?whichshop=lathe');
    if (available_amount($item[flimsy hardwood scraps]) > 0) {
        retrieve_item(1, $item[ebony epee]);
    }
	
	use_familiar($familiar[disembodied hand]);
	
    maximize('weapon damage', false);

    int weapon_turns() {
        return 60 - floor(numeric_modifier('weapon damage') / 25 + 0.001) - floor(numeric_modifier('weapon damage percent') / 25 + 0.001);
    }

    if (weapon_turns() > 2) {
        error('Something went wrong with weapon damage.');
    }

	// cli_execute('modtrace weapon damage');
	// abort();

    do_test(TEST_WEAPON);
}

if (!test_done(TEST_SPELL)) {
    // This will use an adventure.
    ensure_effect($effect[Simmering]);

    ensure_effect($effect[Song of Sauce]);
    ensure_effect($effect[Carol of the Hells]);
    ensure_effect($effect[Arched Eyebrow of the Archmage]);
    ensure_song($effect[Jackasses\' Symphony of Destruction]);
    ensure_effect($effect[The Magic of LOV]);
    // Pool buff
    ensure_effect($effect[Mental A-cue-ity]);

    // Beach Comb
    ensure_effect($effect[We\'re All Made of Starfish]);

    // Tea party
    ensure_sewer_item(1, $item[mariachi hat]);
    // ensure_effect($effect[Full Bottle in front of Me]);

    use_skill(1, $skill[Spirit of Cayenne]);

    if (available_amount($item[flask of baconstone juice]) > 0) {
        ensure_effect($effect[Baconstoned]);
    }

    ensure_item(1, $item[obsidian nutcracker]);

	// Get inner elf for spell damage
	if ((have_effect($effect[inner elf]) == 0) && (get_property_int('_snokebombUsed') < 3)) {        	
		cli_execute("/whitelist hobopolis vacation home");
		ensure_effect($effect[blood bubble]);
		use_familiar($familiar[machine elf]);
		set_hccs_combat_mode(MODE_CUSTOM,
            m_new()
                .m_skill($skill[snokebomb]));
		set_property('choiceAdventure326', '1');
		adv1($location[The Slime Tube], -1, '');
		use_default_familiar();
		set_hccs_combat_mode(MODE_NULL);
		cli_execute("/whitelist alliance from hell"); 
	}	else {
		 print('Something went wrong with getting inner elf');
	}

	// Meteor showered
    if (have_effect($effect[Meteor Showered]) == 0) {
        equip($item[Fourth of May Cosplay Saber]);
        adventure_macro($location[Noob Cave],
            m_new().m_skill($skill[Meteor Shower]).m_skill($skill[Use the Force]));
    }

	if (my_class() == $class[sauceror]) {
		cli_execute('barrelprayer buff');
	}

    // Sigils of Yeg = 200% SD
    if (!get_property_boolean('_cargoPocketEmptied') && have_effect($effect[Sigils of Yeg]) == 0) {
        if (available_amount($item[Yeg\'s Motel hand soap]) == 0) cli_execute('cargo 177');
        ensure_effect($effect[Sigils of Yeg]);
    }

    if (round(numeric_modifier('spell damage percent')) % 50 >= 40) {
        ensure_item(1, $item[soda water]);
        ensure_potion_effect($effect[Concentration], $item[cordial of concentration]);
    }

    use_familiar($familiar[disembodied hand]);

    maximize('spell damage', false);

    int spell_turns() {
        return 60 - floor(numeric_modifier('spell damage') / 50 + 0.001) - floor(numeric_modifier('spell damage percent') / 50 + 0.001);
    }

    while (spell_turns() > my_adventures()) {
        eat(1, $item[magical sausage]);
    }
	
	// cli_execute('modtrace spell damage');
	// abort();
	
    do_test(TEST_SPELL);
}

if (!test_done(TEST_ITEM)) {
    ensure_mp_sausage(500);

    fight_sausage_if_guaranteed();

    autosell(1, $item[lava-proof pants]);
    autosell(1, $item[heat-resistant gloves]);

	//getting a lil ninja costume for the tot
	if ((available_amount($item[9140]) == 0) && (get_property_int('_shatteringPunchUsed') < 3)) {
		set_hccs_combat_mode(MODE_CUSTOM,
            m_new()
                .m_skill($skill[shattering punch]));
		c2t_cartographyHunt($location[The Haiku Dungeon], $monster[716]);
		run_combat();
		set_hccs_combat_mode(MODE_NULL);
		set_location($location[none]);
	}
	
	// use abstraction: certainty if you have it
	/* if ((available_amount($item[abstraction: certainty]) > 0) && (have_effect($effect[certainty]) == 0)) {
		chew($item[abstraction: certainty]);
	} */
		
	// pulls wheel of fortune from deck, gets rope and wrench for later
	if(get_property_int('_deckCardsDrawn') == 5) {
		cli_execute('cheat buff items');
	}
	// get pirate DNA and make a gene tonic
	if ((get_property('dnaSyringe') != 'pirate') && (have_effect($effect[Human-Pirate Hybrid]) == 0)) {
		equip($slot[acc1], $item[Kremlin\'s Greatest Briefcase]);
		if (get_property_int('_kgbTranquilizerDartUses') >= 3) {
			error('Out of KGB banishes');
		}
		adv1($location[Pirates of the Garbage Barges], -1, '');
		adventure_macro($location[Pirates of the Garbage Barges],
            m_new().m_item($item[DNA extraction syringe]).m_skill($skill[KGB tranquilizer dart]));
		gene_tonic('pirate');
		ensure_effect($effect[Human-Pirate Hybrid]);
	}

    if (have_effect($effect[Bat-Adjacent Form]) == 0) {
        if (get_property_int('_reflexHammerUsed') >= 3) error('Out of reflex hammers!');
        equip($slot[acc3], $item[Lil\' Doctor&trade; Bag]);
        adventure_macro($location[The Neverending Party],
            m_new().m_skill($skill[Become a Bat]).m_skill($skill[Reflex Hammer]));
    }

    if (!get_property_boolean('_clanFortuneBuffUsed')) {
        ensure_effect($effect[There\'s No N In Love]);
    }

    ensure_effect($effect[Fat Leon\'s Phat Loot Lyric]);
    ensure_effect($effect[Singer\'s Faithful Ocelot]);
    ensure_effect($effect[The Spirit of Taking]);
    ensure_effect($effect[items.enh]);

    effect[int] subsequent;
    synthesis_plan($effect[Synthesis: Collection], subsequent);

	// see what class we are, maybe a couple other buffs 
	if (my_class() == $class[pastamancer]) {
		cli_execute('barrelprayer buff');
	} else if (my_class() == $class[sauceror]) {
		use_skill(1, $skill[7323]); // seek out a bird
	}

    // Use bag of grain.
    // 	ensure_effect($effect[Nearly All-Natural]);

    ensure_effect($effect[Feeling Lost]);
    ensure_effect($effect[Steely-Eyed Squint]);

    if (get_property_int('_campAwaySmileBuffs') == 1) {
        // See if we can get Big Smile of the Blender.
        visit_url('place.php?whichplace=campaway&action=campaway_sky');
    }
	
    use_familiar($familiar[Trick-or-Treating Tot]);
	equip($item[9140]); // ninja costume for 150% item

    maximize('item, 2 booze drop, -equip broken champagne bottle, -equip surprisingly capacious handbag', false);
	
	// cli_execute('modtrace item');
	// abort();
	
    do_test(TEST_ITEM);

}

set_property('autoSatisfyWithNPCs', true);
set_property('autoSatisfyWithCoinmasters', get_property('_saved_autoSatisfyWithCoinmasters'));
set_property('hpAutoRecovery', '0.8');

cli_execute('mood default');
cli_execute('ccs default');
cli_execute('boombox food');
cli_execute('/whitelist alliance from hell');

print('This loop took '+((gametime_to_int()-START_TIME)/1000)+' seconds, for a 1 day, '+my_turncount()+' turn HCCS run.', 'green');
