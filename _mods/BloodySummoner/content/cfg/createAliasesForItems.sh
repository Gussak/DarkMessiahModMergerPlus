#!/bin/bash

# this is just an example, the list had all food
echo '
item_food_bread02_cooked
' |sed -r -e 's@.*@alias gskSummon& "Test_CreateEntity &; gskHurtme015; gskSmnWORK"@g' -e 's@^alias gskSummonitem_food@alias gskSummon@g'

