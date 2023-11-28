#!/bin/bash

###################################################################
#Script Name  : ddzInstantRewards.sh
#Description  : Send DripDropz Instant Rewards to Delegators
#Args         : See --help for usage instructions
#Author       : Adam Dean & Latheesan K
#Email        : support@dripdropz.io
###################################################################

#Define some colors for the command line
BOLD="\e[1m"
WARN='\033[1;31m'
REKT='\033[1;31m'
SUCCESS='\033[0;32m'
INFO='\033[1;34m'
HELP='\033[1;36m'
LINK='\e[4;1;34m'
NC='\033[0m'

# Show usage help (credit to Martin Lang [ATADA] <https://github.com/gitmachtl/scripts/tree/master/cardano/mainnet>
showUsage() {
echo -e "
###################################################################
#
# Script Name: ${BOLD}$(basename $0)${NC}
#
# Description: Send DripDropz Instant Rewards to Delegators
#
###################################################################

Usage: ${BOLD}$(basename $0)${NC} \\
${BOLD}--appid ${HELP}<appId>${NC} \\
${BOLD}--accesstoken ${HELP}<accessToken>${NC} \\
{ [${BOLD}--flatrate ${HELP}<amount>${NC} |${BOLD}--perada ${HELP}<amount>${NC}] } \\
[${BOLD}--minlovelace ${HELP}<amount>${NC}] \\
[${BOLD}--ticker ${HELP}<pool_ticker>${NC}] \\
[${BOLD}--epoch ${HELP}<epoch_no>${NC}]

Issue rewards to your pool delegators automatically utilizing the DripDropz Instant Rewards API!

Note that you must have an account on DripDropz, have created a Token Bucket and API Key on the Instant Rewards page
<${LINK}https://dripdropz.io/account/instant-reward/api-keys${NC}> and must have sufficient API Credits Balance to account
for all of your eligible delegators.

Note that this script will attempt to send rewards in the most ideal method possible, up to 100 addresses per API
request to minimize server load and maximize your API Credits.

${REKT}**IMPORTANT** THIS SCRIPT SHOULD ONLY BE RUN FROM A RELAY AND NEVER DIRECTLY FROM YOUR BLOCK PRODUCER IN ORDER TO
AVOID EXPOSING YOUR BLOCK PRODUCER'S PRIVATE IP ADDRESS!${NC}

Required Parameters:

  ${BOLD}--appid ${HELP}<appId>${NC}: The App ID for your API Key that you wish to use

  ${BOLD}--accesstoken ${HELP}<accessToken>${NC}: The secret Access Token for the API Key that you wish to use

  One of...

    ${REKT}**Note**${NC} Token quantities must always be specified in the base amount of the token as the system has no
    knowledge of decimal places used for formatting the display of the token.

    Example: 1 \$DRIP must be passed as 1 000 000 (6 decimals)

  ${BOLD}--flatrate ${HELP}<amount>${NC}: A fixed amount that will be sent to all delegators regardless of the delegated
    amount. This should be entered as an integer value in the token's base amount.

    Example: 1 000 000 == 1 \$DRIP

  ${BOLD}--perada ${HELP}<amount>${NC}: An amount of tokens that the user will receive per ADA delegated. This may be
    specified in a floating point (decimal) number to create some interesting scenarios.

    Example: 1 000 == 1 \$DRIP per 1 000 \$ADA delegated. 0.1 == 1 \$DRIP per 10 000 \$ADA delegated.

Optional Parameters:

  ${BOLD}--minlovelace ${HELP}<amount>${NC}: Optionally specify a minimum number of Lovelace that must be delegated in
    order to qualify for rewards. Delegators must stake at least 1 MORE than this amount of Lovelace
    in order to qualify. [Default: 0, user must delegate 1 Lovelace or more]

  ${BOLD}--ticker ${HELP}<pool_ticker>${NC}: The pool ticker issuing the rewards. Will be shown to users in the message
    on DripDropz.

  ${BOLD}--epoch ${HELP}<epoch_no>${NC}: The epoch number rewards are being issued for. Will be shown to users in the
    message on DripDropz.
"
}



while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        if [[ $v == "help" ]]; then
          showUsage
          exit
        fi
        declare $v="$2"
   fi

  shift
done

if [ -z ${appid+x} ]; then
  echo ""
  echo -e "${REKT}ERROR: App ID is not set!${NC}"
  echo ""
  showUsage
  exit
fi

if [ -z ${accesstoken+x} ]; then
  echo ""
  echo -e "${REKT}ERROR: Access Token is not set!${NC}"
  echo ""
  showUsage
  exit
fi

if [ -z ${minlovelace+x} ]; then
  minlovelace=0
fi

echo ""
echo -e "${BOLD}App ID:${NC} ${appid}"
echo -e "${BOLD}Access Token:${NC} ${accesstoken}"
echo -e "${BOLD}Minimum Lovelace is:${NC} ${minlovelace}"
echo ""

message="Instant pool rewards"

if [ -n "${ticker}" ]; then
  message="${message} from ${ticker}"
fi

if [ -n "${epoch}" ]; then
  message="${message} (Epoch #${epoch})"
fi

if [ -n "${perada}" ]; then
  echo "Tokens per ADA is: ${perada} tokens"
  echo ""

  groups=$(jq -c \
  --arg minLovelace $minlovelace \
  --arg perADA $perada \
  --arg reason "$message" \
  'sort_by((.delegatedLovelace|tonumber),.poolLoyaltyEpochs) |
  reverse |
  map(select(.delegatedLovelace|tonumber-1 >= ($minLovelace|tonumber)) |
  {
    address: .stakeAddress,
    amount: ((.delegatedLovelace|tonumber / 1000000 * ($perADA|tonumber))|floor|tonumber),
    reason: $reason
  }) |
  map(select(.amount > 0)) |
  sort_by(.amount) |
  reverse |
  _nwise(.;3) |
  {rewards: .}' stakers2.json)
elif [ -n "${flatrate}" ]; then
  echo "Flat rate of ${flatrate} tokens!"
  echo ""

  groups=$(jq -c \
    --arg minLovelace $minlovelace \
    --arg flatRate $flatrate \
    --arg reason "$message" \
    'sort_by((.delegatedLovelace|tonumber),.poolLoyaltyEpochs) |
    reverse |
    map(select(.delegatedLovelace|tonumber-1 >= ($minLovelace|tonumber)) |
    {
      address: .stakeAddress,
      amount: $flatRate|tonumber,
      reason: $reason
    }) |
    _nwise(.;3) |
    {rewards: .}' stakers2.json)
else
  groups=$(jq -c \
  --arg minLovelace $minlovelace \
  --arg reason "$message" \
  'sort_by((.delegatedLovelace|tonumber),.poolLoyaltyEpochs) |
  reverse |
  map(
    select(.delegatedLovelace|tonumber-1 >= ($minLovelace|tonumber)) |
    {
      address: .stakeAddress,
      amount: 1,
      reason: $reason
    }
  ) |
  _nwise(.;3) |
  {rewards: .}' stakers2.json)
fi

total_requests_needed=$(jq -s '. | length' <<< $groups)

echo ""
echo -e "Preparing to send ${SUCCESS}${total_requests_needed}${NC} API requests..."
echo ""

jq -c --slurp '.[]' <<< $groups | while read i; do
  echo ""
  echo -e "${WARN}*** SEND A CURL REQUEST HERE! ***${NC}"
  echo ""
  jq . <<< $i
done
