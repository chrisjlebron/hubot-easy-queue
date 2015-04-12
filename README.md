hubot-easy-queue
================

Script for manually keeping track of a deployment queue in [hubot](https://hubot.github.com/).

:no_bell: No bells and whistles. :no_bell:

:no_entry_sign: :fire: No hot API integrations. :fire: :no_entry_sign:

Just does what it says on the tin.

Commands
--------

-	`hubot queue (list)` - show queue for day
-	`hubot queue me` - add user name to the queue
-	`hubot queue me <issue>` - add issue to the queue for user
-	`hubot queue remove <index>` - remove a list item from queue, by number provided
-	`hubot (queue) deployed` - remove the top list item from queue
-	`hubot queue empty` - empty the queue
-	`hubot queue help` - get list of queue commands

### Secrets

Also works with shortened command `q`. Cuz I care about your time and fingers.
