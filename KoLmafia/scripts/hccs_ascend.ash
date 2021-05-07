if (!get_workshed().contains_text("DNA")) { print("You have the wrong workshed item", "red"); abort();}
if (my_garden_type() != "peppermint") { print("You have the wrong garden", "red"); abort();}
print("you're about to ascend! wait, is that good?", "green");

if (!visit_url("charpane.php").contains_text("Astral Spirit")) visit_url("ascend.php?action=ascend&confirm=on&confirm2=on");
if (!visit_url("charpane.php").contains_text("Astral Spirit")) abort("Failed to ascend.");
visit_url("afterlife.php?action=pearlygates");
visit_url("afterlife.php?action=buydeli&whichitem=5046");
visit_url("afterlife.php?action=ascend&confirmascend=1&whichsign=2&gender=1&whichclass=4&whichpath=25&asctype=3&nopetok=1&noskillsok=1&pwd", true);  