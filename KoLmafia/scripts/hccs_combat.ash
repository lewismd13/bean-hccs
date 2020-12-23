import <hccs_lib.ash>

// multi_fight() stolen from Aenimus: https://github.com/Aenimus/aen_cocoabo_farm/blob/master/scripts/aen_combat.ash.
// Thanks! Licensed under MIT license.
void multi_fight() {
    while (in_multi_fight()) run_combat();
    if (choice_follows_fight()) visit_url("choice.php");
}

/*string update_state(string page_text) {
    if (page_text == "") abort("Empty page text!");
    _current_state.finished = false;
    _current_state.round = -1;
    _current_state.current_choice = -1;
    _current_state.current_monster = $monster[none];
    if (page_text.contains_text("choice.php")) {
        matcher m_choice = create_matcher("whichchoice value=(\\d+)", page_text);
        m_choice.find();
        _current_state.current_choice = m_choice.group(1).to_int();
        return page_text;
    } else if (page_text.contains_text("Combat!")) {
        if (!page_text.contains_text("WINWINWIN")
                && !page_text.contains_text("FREEFREEFREE")
                && !page_text.contains_text("You lose.")
                && !page_text.contains_text("You run away")
                && !page_text.contains_text("adventure.php")) {
            return run_combat("save_adventure_result");
        } else if (page_text.contains_text("href=fight.php") || page_text.contains_text("href=\"fight.php")) {
            // In chained combat. See what's going on.
            return update_state(visit_url("fight.php"));
        } else {
            _current_state.finished = true;
        }
    } else if (page_text.contains_text("Adventure Results:")) {
        // Non-choice noncombat.
        _current_state.finished = true;
    } else {
        abort("Unrecognized adventure result.");
    }
    return page_text;
}

string update_state(buffer page_text) {
    return update_state(page_text.to_string());
}

adventure_result m_submit(buffer macro) {
    update_state(macro.m_submit());
    return _current_state;
}*/

buffer m_new() {
    buffer buf;
    return buf;
}

buffer m_new(string init) {
    buffer buf;
    buf.append(init);
    return buf;
}

string m_submit(buffer macro) {
    print(`Submitting macro: {macro}`);
    return visit_url("fight.php?action=macro&macrotext=" + url_encode(macro), true, true);
}

buffer m_step(buffer macro, string next) {
    if (macro.length() > 0) macro.append(";");
    macro.append(next);
    return macro;
}

string m_monster(monster m) {
    return `monstername "{m.name}"`;
}

buffer m_skill(buffer macro, skill sk) {
    if (have_skill(sk)) {
        string name = sk.name.replace_string("%fn, ", "");
        return macro.m_step(`skill {name}`);
    } else {
        return macro;
    }
}

buffer m_item(buffer macro, item it) {
    return macro.m_step(`use {it.name}`);
}

buffer m_repeat(buffer macro) {
    return macro.m_step("repeat");
}

string m_repeat_submit(buffer macro) {
    return macro.m_step("repeat").m_submit();
}

buffer m_if(buffer macro, string condition, string next) {
    return macro.m_step(`if {condition}`).m_step(next).m_step("endif");
}

buffer m_if(buffer macro, string condition, string next1, string next2) {
    return macro.m_if(condition, `{next1};{next2}`);
}

buffer m_if(buffer macro, string condition, string next1, string next2, string next3) {
    return macro.m_if(condition, `{next1};{next2};{next3}`);
}

buffer m_external_if(buffer macro, boolean condition, buffer next) {
    if (condition) return macro;
    else return macro.m_step(next);
}

// Aborted attempt at manual combat handling.
/*string save_adventure_result(int round, monster opp, string text) {
    _current_state.round = round;
    _current_state.current_monster = opp;
    return "";
}

adventure_result adventure_manual(location loc) {
    if (my_hp() < .6 * my_maxhp()) {
        restore_hp(my_maxhp());
    }
    string page = visit_url(loc.to_url());
    update_state(page);
    print(`Round: {_current_state.round}`);
    print(`Monster: {_current_state.current_monster}`);
    print(`Choice: {_current_state.current_choice}`);
    print(`Finished: {_current_state.finished}`);
    return _current_state;
}

adventure_result adventure_state() {
    string fight = visit_url("fight.php");
    if (fight != "") {
        update_state(fight);
    } else {
        string choice = visit_url("choice.php");
        if (choice != "") {
            update_state(choice);
        } else {
            _current_state.finished = true;
            _current_state.round = -1;
            _current_state.current_choice = -1;
            _current_state.current_monster = $monster[none];
        }
    }
    return _current_state;
}*/

string MODE_NULL = "";
string MODE_CUSTOM = "custom";
string MODE_FIND_MONSTER_SABER_YR = "findsaber";
string MODE_FIND_MONSTER_THEN = "findthen";
string MODE_SABER_YR = "saber";
string MODE_COPY = "copy";
string MODE_FREE_KILL = "freekill";
string MODE_KILL = "kill";
string MODE_OTOSCOPE = "otoscope";
string MODE_RUN_UNLESS_FREE = "run";
string MODE_MISTFORM = "mist";

void set_hccs_combat_mode(string mode) {
    set_property("_hccsCombatMode", mode);
}

void set_hccs_combat_mode(string mode, string arg) {
    set_property("_hccsCombatMode", mode);
    set_property("_hccsCombatArg1", arg);
}

void set_hccs_combat_mode(string mode, string arg1, string arg2) {
    set_property("_hccsCombatMode", mode);
    set_property("_hccsCombatArg1", arg1);
    set_property("_hccsCombatArg2", arg2);
}

string get_hccs_combat_mode() {
    return get_property("_hccsCombatMode");
}

string get_hccs_combat_arg1() {
    return get_property("_hccsCombatArg1");
}

string get_hccs_combat_arg2() {
    return get_property("_hccsCombatArg2");
}

monster[string] banished_monsters() {
    string banished_string = get_property("banishedMonsters");
    string[int] banished_components = banished_string.split_string(":");
    monster[string] result;
    if (banished_components.count() < 3) return result;
    for idx from 0 to banished_components.count() / 3 - 1 {
        monster foe = banished_components[idx * 3].to_monster();
        string banisher = banished_components[idx * 3 + 1];
        print(`Banished {foe.name} using {banisher}`);
        result[banisher] = foe;
    }
    return result;
}

boolean used_banisher_in_zone(monster[string] banished, string banisher, location loc) {
    print(`Checking to see if we\'ve used {banisher} in {loc}.`);
    if (!(banished contains banisher)) return false;
    print(`Used it to banish {banished[banisher].name}`);
    return (loc.get_location_monsters() contains banished[banisher]);
}

void main(int initround, monster foe, string page) {
    string mode = get_hccs_combat_mode();
    location loc = my_location();
    string monster_name = get_hccs_combat_arg1();
    monster desired = monster_name.to_monster();
    if (mode == MODE_CUSTOM) {
        m_new(get_hccs_combat_arg1()).m_repeat_submit();
    } else if (mode == MODE_SABER_YR) {
        buffer macro = m_new();
        string skill_name = get_hccs_combat_arg1();
        if (skill_name.to_skill() != $skill[none]) {
            macro = macro.m_skill(skill_name.to_skill());
        }
        macro
            .m_skill($skill[Use the Force])
            .m_repeat_submit();
    } else if (mode == MODE_FIND_MONSTER_THEN) {
        monster[string] banished = banished_monsters();
        if (foe == desired) {
            set_property("_hccsCombatFound", "true");
            m_new(get_hccs_combat_arg2()).m_repeat_submit();
        } else if (my_mp() >= 50 && have_skill($skill[Snokebomb]) && get_property_int("_snokebombUsed") < 3 && !used_banisher_in_zone(banished, "snokebomb", loc)) {
            use_skill(1, $skill[Snokebomb]);
        /* } else if (have_skill($skill[Reflex Hammer]) && get_property_int("_reflexHammerUsed") < 3 && !used_banisher_in_zone(banished, "Reflex Hammer", loc)) {
            use_skill(1, $skill[Reflex Hammer]); */
        } else if (have_skill($skill[Macrometeorite]) && get_property_int("_macrometeoriteUses") < 10) {
            use_skill(1, $skill[Macrometeorite]);
        } else if (have_skill($skill[CHEAT CODE: Replace Enemy]) && get_property_int("_powerfulGloveBatteryPowerUsed") <= 80) {
            int original_battery = get_property_int("_powerfulGloveBatteryPowerUsed");
            use_skill(1, $skill[CHEAT CODE: Replace Enemy]);
            int new_battery = get_property_int("_powerfulGloveBatteryPowerUsed");
            if (new_battery == original_battery) {
                print("WARNING: Mafia is not updating PG battery charge.");
                set_property("_powerfulGloveBatteryPowerUsed", "" + (new_battery + 10));
            }
            // Hopefully at this point it comes back to the consult script.
        }
    } else if (mode == MODE_COPY) {
        if (foe != desired) {
            abort(`Ran into the wrong monster while trying to copy {desired.name}.`);
        }
        int weight = familiar_weight($familiar[Pocket Professor]) + weight_adjustment();
        int lectures_used = get_property_int("_pocketProfessorLectures");
        boolean have_chip = equipped_amount($item[Pocket Professor memory chip]) > 0;
        int max_lectures = floor((weight - 1) ** 0.5) + 1 + (have_chip ? 2 : 0);
        m_new()
            .m_skill($skill[Curse of Weaksauce])
            .m_skill($skill[Sing Along])
            // .m_external_if(lectures_used == max_lectures, m_new().m_skill($skill[Meteor Shower]))
            .m_skill($skill[Lecture on Relativity])
            .m_skill($skill[Saucegeyser])
            .m_repeat_submit();
    } else if (mode == MODE_FREE_KILL) {
        if (foe.attributes.contains_text("FREE")) {
            m_new()
                .m_skill($skill[Curse of Weaksauce])
                .m_skill($skill[Sing Along])
                .m_skill($skill[Saucegeyser])
                .m_repeat_submit();
        } else if (have_skill($skill[Chest X-Ray]) && get_property_int("_chestXRayUsed") < 3) {
            use_skill(1, $skill[Chest X-Ray]);
        } /* else if (have_skill($skill[Shattering Punch]) && get_property_int("_shatteringPunchUsed") < 1) {
            use_skill(1, $skill[Shattering Punch]);
        } */ else if (have_skill($skill[Gingerbread Mob Hit]) && !get_property_boolean("_gingerbreadMobHitUsed")) {
            use_skill(1, $skill[Gingerbread Mob Hit]);
        }
    } else if (mode == MODE_KILL) {
        if (foe == desired) {
            m_new()
                .m_skill($skill[Curse of Weaksauce])
                .m_skill($skill[Sing Along])
                .m_skill($skill[Transcendent Olfaction])
                .m_skill($skill[Gallapagosian Mating Call])
                .m_skill($skill[Saucegeyser])
                .m_repeat_submit();
        } else {
            m_new()
                .m_skill($skill[Curse of Weaksauce])
                .m_skill($skill[Sing Along])
                .m_skill($skill[Saucegeyser])
                .m_repeat_submit();
        }
    } else if (mode == MODE_OTOSCOPE) {
        m_new()
            .m_skill($skill[Curse of Weaksauce])
            .m_skill($skill[Sing Along])
            .m_skill($skill[Otoscope])
            .m_skill($skill[Saucegeyser])
            .m_repeat_submit();
    } else if (mode == MODE_RUN_UNLESS_FREE) {
        if (foe.attributes.contains_text('FREE')) {
            m_new()
                .m_skill($skill[Curse of Weaksauce])
                .m_skill($skill[Sing Along])
                .m_skill($skill[Saucegeyser])
                .m_repeat_submit();
        } else if (my_familiar() == $familiar[Frumious Bandersnatch]
                && have_effect($effect[Ode to Booze]) > 0
                && get_property_int("_banderRunaways") < my_familiar_weight() / 5) {
            int banderRunaways = get_property_int("_banderRunaways");
            runaway();
            if (get_property_int("_banderRunaways") == banderRunaways) {
                print("WARNING: Mafia is not tracking bander runaways correctly.");
                set_property_int("_banderRunaways", banderRunaways + 1);
            }
        /* } else if (have_skill($skill[Reflex Hammer]) && get_property_int("_reflexHammerUsed") < 3) {
            use_skill(1, $skill[Reflex Hammer]); */
        } else if (my_mp() >= 50 && have_skill($skill[Snokebomb]) && get_property_int("_snokebombUsed") < 3) {
            use_skill(1, $skill[Snokebomb]);
        } else {
            abort("Something went wrong.");
        }
    } else if (mode == MODE_MISTFORM) {
		m_new()
				.m_skill($skill[Meteor Shower])
				.m_skill($skill[Become a Cloud of Mist])
                .m_skill($skill[Use the Force])
				.m_repeat_submit();
	} else {
        abort("Unrecognized mode.");
    }

    multi_fight();
}

void saber_yr() {
    if (!handling_choice()) error('No choice?');
    if (last_choice() == 1387 && count(available_choice_options()) > 0) {
        run_choice(3);
    }
}

void adventure_macro(location loc, buffer macro) {
    set_hccs_combat_mode(MODE_CUSTOM, macro);
    adv1(loc, -1, "");
    set_hccs_combat_mode(MODE_NULL, '');
}

void adventure_saber_yr(location loc, skill sk) {
    set_hccs_combat_mode(MODE_SABER_YR, sk.name);
    set_property("choiceAdventure1387", "3");
    adv1(loc, -1, "");
    set_hccs_combat_mode(MODE_NULL, '');
}

void find_monster_then(location loc, monster foe, buffer macro) {
    set_hccs_combat_mode(MODE_FIND_MONSTER_THEN, foe.name, macro);
    set_property("_hccsCombatFound", "false");
    while (get_property("_hccsCombatFound") != "true") {
        adv1(loc, -1, "");
    }
    set_hccs_combat_mode(MODE_NULL, '');
}

void find_monster_saber_yr(location loc, monster foe) {
    set_property("choiceAdventure1387", "3");
    find_monster_then(loc, foe, m_new().m_skill($skill[Use the Force]));
}

void adventure_copy(location loc, monster foe) {
    set_hccs_combat_mode(MODE_COPY, foe.name);
    adv1(loc, -1, "");
    set_hccs_combat_mode(MODE_NULL, '');
}

void adventure_kill(location loc) {
    set_hccs_combat_mode(MODE_KILL);
    adv1(loc, -1, "");
    set_hccs_combat_mode(MODE_NULL);
}

void adventure_kill(location loc, monster foe) {
    set_hccs_combat_mode(MODE_KILL, foe.name);
    adv1(loc, -1, "");
    set_hccs_combat_mode(MODE_NULL, '');
}

void adventure_free_kill(location loc) {
    set_hccs_combat_mode(MODE_FREE_KILL);
    adv1(loc, -1, "");
    set_hccs_combat_mode(MODE_NULL);
}

void adventure_run_unless_free(location loc) {
    set_hccs_combat_mode(MODE_RUN_UNLESS_FREE);
    adv1(loc, -1, "");
    set_hccs_combat_mode(MODE_NULL);
}