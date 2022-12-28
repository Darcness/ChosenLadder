# ChosenLadder

ChosenLadder is a Raid Administration assistant for The Chosen guild on Bloodsail Buccaneers - US East / Wrath

## Features
1. Ladder window based on Suicide Kings rules
2. Auctioning system for items to bid

### Ladder
1. Ladder window allows for Import/Export of names to manually construct the list
2. Checkboxes to confirm members of the raid as present.
  a. Members of the raid that are not present are preserved in the ladder (rather than moved up)
3. Dunk button to Dunk a player to the bottom of the list
4. Master Looter permissions required to perform any actions
5. Local history of Dunks can be printed

### Auctions
1. Auctions are run to auction off items in the raid
2. Bids are placed by sending whispers to the Master Looter
3. Bids are forced to follow current minimum bid rules
  a. 50 minimum, +10 to 300, +50 to 1000, +100 beyond
4. Local history of Auctions can be printed

### Loot
1. Loot window tracks all items which are BoP and tradeable
2. Loot window can start Auctions or Dunk sessions
3. Loot window can be cleared of individual items once they are manually handled

## Usage
**/cl**, **/clhelp** - Displays the help list
**/clladder** - Displays the Ladder window
**/clauction <start/top> [<itemLink>]** - Starts an auction (for the linked item) or stops the current auction
**/cllog <auction/ladder>** - Prints the log for auctions or ladder dunks