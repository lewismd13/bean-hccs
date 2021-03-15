buy(1, $item[foreign language tapes]);
buy(1, $item[swiss piggy bank]);
buy(1, $item[ceiling fan]);

use(1, $item[peppermint pip packet]);
take_stash(1, $item[little geneticist DNA-splicing lab]);
use(1, $item[little geneticist DNA-splicing lab]);


if (pvp_attacks_left() > 0) {
    cli_execute('pvp loot kar');
}