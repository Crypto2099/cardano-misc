#!/bin/bash

###################################################################
#Script Name  : ddzInstantRewards.sh
#Description  : Send DripDropz Instant Rewards to Delegators
#Args         : See --help for usage instructions
#Author       : Adam Dean & Latheesan K
#Email        : support@dripdropz.io
###################################################################

source './.ddz.env'

#Define some colors for the command line
BOLD="\e[1m"
WARN='\033[1;31m'
REKT='\033[1;31m'
SUCCESS='\033[0;32m'
#INFO='\033[1;34m'
HELP='\033[1;36m'
LINK='\e[4;1;34m'
NC='\033[0m'

# Show usage help (credit to Martin Lang [ATADA] <https://github.com/gitmachtl/scripts/tree/master/cardano/mainnet>
showUsage() {
  echo -e "
########################################################################################################################
#                                                                                                                      #
# Script Name: ${BOLD}$(basename "$0")${NC}                                                                                        #
#                                                                                                                      #
# Description: Issue rewards to your pool delegators automatically utilizing the DripDropz Instant Rewards API!        #
#                                                                                                                      #
# Note that you must have an account on DripDropz, have created a Token Bucket and API Key on the Instant Rewards page #
# <${LINK}https://dripdropz.io/account/instant-reward/api-keys${NC}> and must have sufficient API Credits Balance to               #
# account for all of your eligible delegators.                                                                         #
#                                                                                                                      #
# Note that this script will attempt to send rewards in the most ideal method possible, up to 100 addresses per API    #
# request to minimize server load and maximize your API Credits.                                                       #
#                                                                                                                      #
# ${REKT}**IMPORTANT** THIS SCRIPT SHOULD ONLY BE RUN FROM A RELAY AND NEVER DIRECTLY FROM YOUR BLOCK PRODUCER IN ORDER${NC}       #
# ${REKT}TO AVOID EXPOSING YOUR BLOCK PRODUCER'S PRIVATE IP ADDRESS!${NC}                                                          #
#                                                                                                                      #
########################################################################################################################

Usage:
${BOLD}$(basename "$0")${NC} \\
  {[
    ${BOLD}--flatrate ${HELP}<amount>${NC} |
    ${BOLD}--perada ${HELP}<amount>${NC}
  ]} \\
  {[
    ${BOLD}--sourcefile ${HELP}<path>${NC} |
    ${BOLD}--source ${HELP}<json_string>${NC} |
    ${BOLD}--poolid ${HELP}<hex|bech32>${NC} [${BOLD}--savesnapshot ${HELP}<path>${NC}]
  ]} \\
  [${BOLD}--appid ${HELP}<appId>${NC}] \\
  [${BOLD}--accesstoken ${HELP}<accessToken>${NC}] \\
  [${BOLD}--network ${HELP}<network_id>${NC}] \\
  [${BOLD}--dryrun ${HELP}<boolean>${NC}] \\
  [${BOLD}--minlovelace ${HELP}<amount>${NC}] \\
  [${BOLD}--minloyalty ${HELP}<amount>${NC}] \\
  [${BOLD}--loyaltymod ${HELP}<amount>${NC} \\
  [${BOLD}--maxreward ${HELP}<amount>${NC} \\
  [${BOLD}--minreward ${HELP}<amount>${NC} \\
  [${BOLD}--ticker ${HELP}<pool_ticker>${NC}]

Usage Example (Flat Rate): ${BOLD}$(basename "$0") --flatrate 10 --poolid pool1n84mel6x3e8sp0jjgmepme0zmv8gkw8chs98sqwxtruvkhhcsg8${NC}

Usage Example (Per ADA): ${BOLD}$(basename "$0") --perada 5 --poolid pool1n84mel6x3e8sp0jjgmepme0zmv8gkw8chs98sqwxtruvkhhcsg8${NC}

Usage Example (Per ADA with Modifier and Max Rewards):
${BOLD}$(basename "$0") \\
  ${BOLD}--perada 5 \\              ${NC}# Give 5 tokens per ADA delegated
  ${BOLD}--minlovelace 100000000 \\ ${NC}# 100A minimum delegation required
  ${BOLD}--loyaltymod 1.001 \\      ${NC}# Increase by 0.1% per epoch delegated
  ${BOLD}--maxreward 5000 \\        ${NC}# Users may receive at most 5000 tokens
  ${BOLD}--poolid pool1n84mel6x3e8sp0jjgmepme0zmv8gkw8chs98sqwxtruvkhhcsg8${NC}

Required Parameters:

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

  One of...

    ${REKT}**Note**${NC} When using the ${BOLD}--poolid${NC} parameter a request will be made to DripDropz servers to
    request snapshot information. This will consume ${BOLD}1${NC} API Credit from your account each time it is called.
    We recommend that you use the ${BOLD}--savesnapshot${NC} argument to cache these results to a local file in the
    event that you would like to review the source or run this script again later.

  ${BOLD}--poolid ${HELP}<pool_hex_id>${NC}: The hex ID of the stake pool you'd like to query the snapshot for. This
    will perform an API call to DripDropz servers to fetch the snapshot. This will consume 1 API credit from your
    account. Please use in conjunction with the ${BOLD}--savesnapshot${NC} parameter to minimize credit usage.

  ${BOLD}--savesnapshot ${HELP}<path>${NC}: The file path where you would like to save the snapshot data. Only used in
    conjunction with the ${BOLD}--poolid${NC} parameter.

    [Default: ./snapshots/<pool_id>/<epoch_no>.snapshot.json]

  ${BOLD}--sourcefile ${HELP}<file_path>${NC}: Load snapshot state from a locally saved JSON file stored at the specified
    path.

  ${BOLD}--source ${HELP}<json_string>${NC}: You can pass a valid JSON string using this argument.

Optional Parameters:

  ${BOLD}--appid ${HELP}<appId>${NC}: The App ID for your API Key that you wish to use. May optionally be specified in
    .ddz.env file as DDZ_APP_ID.

  ${BOLD}--accesstoken ${HELP}<accessToken>${NC}: The secret Access Token for the API Key that you wish to use. May
    optionally be specified in .ddz.env file as DDZ_ACCESS_TOKEN.

  ${BOLD}--network ${HELP}<network_id>${NC}: 1 = Mainnet; 0 = Preprod (Preview currently not supported).

    [Default: 1, Mainnet]

  ${BOLD}--dryrun ${HELP}<boolean>${NC}: 1 = True, write results to terminal and file, do not submit rewards via API.
    0 = False, send rewards via API.

    [Default: 1, Dry Run]

  ${BOLD}--minlovelace ${HELP}<amount>${NC}: Optionally specify a minimum number of Lovelace that must be delegated in
    order to qualify for rewards. Delegators must stake at least 1 MORE than this amount of Lovelace
    in order to qualify.

    [Default: 0, user must delegate 1 Lovelace or more]

  ${BOLD}--minloyalty ${HELP}<amount>${NC}: Optionally specify the minimum number of Epochs a wallet must have been
    delegated to your stake pool in order to receive rewards.

    [Default: 0, first-epoch delegators are also eligible for rewards]

  ${BOLD}--loyaltymod ${HELP}<amount>${NC}: Optionally specify a multiplier based on the number of epochs the wallet
    has been delegated. This must be a floating point number greater than 1 such as: 1.1 === 10% bonus
    per epoch. Note that fractional amounts are always rounded down to the lowest whole integer value.

    Calculation: ${BOLD}(<loyalty_modifier>^<epoch_loyalty>)*<base_rewards> = <rewards_with_bonus>${NC}

    Example: Modifier: 1.1, Epoch Loyalty: 72, Base Rewards: 10, Rewards with Bonus: 9 555
    Example: Modifier: 1.01, Epoch Loyalty: 72, Base Rewards: 10, Rewards with Bonus: 20

    [Default: 1.0, no epoch loyalty bonus]

  ${BOLD}--maxreward ${HELP}<amount>${NC}: Optionally specify a maximum amount of rewards that any address may receive,
    if the wallet would receive more than this amount due to loyalty modifiers or per \$ADA rewards,
    the total amount issued will be capped at this number. Must be specified as an integer.

    [Default: null, no maximum]

  ${BOLD}--minreward ${HELP}<amount>${NC}: Optionally specify a minimum amount of rewards that any eligible address will
    receive. If the wallet in question would receive less than this amount the total amount issue will
    be increased to this number. Must be specified as an integer.

    [Default: null, no minimum]

  ${BOLD}--ticker ${HELP}<pool_ticker>${NC}: The pool ticker issuing the rewards. Will be shown to users in the message
    on DripDropz.

  ${BOLD}--sourcefile ${HELP}<file_path>${NC}: A path to a JSON file generated via CNCLI that contains delegator
    information. Must match the format of ${HELP}./stakers.sample.json${NC}.

    [Default: stakers.sample.json]

  ${BOLD}--source ${HELP}<json_string>${NC}: You can use this argument to pass a JSON string that has already been
    recovered from an API request or by manually running a 'jq' query locally.
"
}

getSlot() {
  currentTime=$(date +%s)
  if [ "$1" == 1 ]; then
    #mainnet
    zeroTime=1596059091
    zeroSlot=4492800
    slotLength=1
  else
    #preprod
    zeroTime=1655769600
    zeroSlot=86400
    slotLength=1
  fi

  timePassed=$((currentTime - zeroTime))
  slotsPassed=$((timePassed / slotLength))
  currentSlot=$((slotsPassed + zeroSlot))

  echo $currentSlot
}

getEpoch() {
  if [ "$1" == 1 ]; then
    startEpochOffset=197
  else
    startEpochOffset=4
  fi

  currentSlot=$(getSlot "$1")
  relativeEpoch=$((currentSlot / 432000))
  currentEpoch=$((relativeEpoch + startEpochOffset))

  echo $currentEpoch
}

while [ $# -gt 0 ]; do

  if [[ $1 == *"--"* ]]; then
    v="${1/--/}"
    if [[ $v == "help" ]]; then
      showUsage
      exit
    fi
    declare "$v"="$2"
  fi

  shift
done

# Set defaults if not set
BATCH_LIMIT="${DDZ_BATCH_LIMIT:-100}"
appid="${appid:-${DDZ_APP_ID}}"
accesstoken="${accesstoken:-${DDZ_ACCESS_TOKEN}}"
minlovelace="${minlovelace:-0}"
minloyalty="${minloyalty:-0}"
loyaltymod="${loyaltymod:-1}"
minreward="${minreward:-0}"
maxreward="${maxreward:-0}"
NETWORKID="${networkid:-${DDZ_NETWORK_ID}}"
networkid="${NETWORKID:-1}"
if [[ "$networkid" == 1 ]]; then
  networkname="Mainnet"
  DDZ_API_BASE_URI="https://dripdropz.io/api/integration/v1/instant-reward"
else
  networkname="Preprod"
  DDZ_API_BASE_URI="https://dripdropz-dev.com/api/integration/v1/instant-reward"
fi
dryrun="${dryrun:-1}"
epoch=$(getEpoch "$networkid")

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

if [ -n "${sourcefile}" ]; then
  file_ext=${sourcefile##*.}
  if [[ ! -f "${sourcefile}" && "${file_ext^^}" == "JSON" ]]; then # it's not a JSON file!
    echo -e "${REKT}The provided ${HELP}sourcefile${REKT} is not a valid JSON file!"
    exit 1
  fi
  source=$(jq -c . "$sourcefile")
fi

if [ -n "${poolid}" ]; then
  OUTPUT_FILE_PATH="${savesnapshot:-./snapshots/${poolid}/${epoch}.snapshot.json}"

  if [ -f "${OUTPUT_FILE_PATH}" ]; then
    echo ""
    echo "An existing snapshot file was found at ${OUTPUT_FILE_PATH}, using that!"
    #    echo "jq -c . $OUTPUT_FILE_PATH"
    source=$(jq -c . "${OUTPUT_FILE_PATH}")
  else
    base_uri=$(echo "${DDZ_API_BASE_URI}" | tr -d '\r')
    url="${base_uri}/pool-delegations/${poolid}/${epoch}"
    curl_response=$(curl -s --http1.1 --header "X-App-Id: ${appid}" --header "X-Access-Token: ${accesstoken}" --location "${url}")

    error=$(jq -r '.error' <<<"$curl_response")
    if [ "${error}" != "null" ]; then
      echo -e "${REKT}${error}${NC}"
      echo ""
      exit 1
    fi

    epochno=$(jq -r '.data.epoch' <<<"$curl_response")

    if [ "${epoch}" != "${epochno}" ]; then
      echo -e "${REKT}Calculated epoch number (${epoch}) does not match the snapshot epoch (${epochno})${NC}"
      echo ""
      exit 1
    fi

    source=$(jq -c '.data.delegateSummaries' <<<"$curl_response")
    count=$(jq -r '. | length' <<<"$source")

    OUTPUT_DIR="$(dirname "${OUTPUT_FILE_PATH}")"
    mkdir -p "$OUTPUT_DIR"

    echo ""
    echo "Fetched ${count} delegators for epoch #${epochno}!"
    echo "Saving output to $OUTPUT_FILE_PATH"
    echo "$source" >"$OUTPUT_FILE_PATH"
  fi

fi

if [[ -z "${source}" ]]; then
  echo "Source is not defined! Using default!"
  source=$(jq -c . "./stakers.sample.json")
fi

valid_json=$(jq -e . >/dev/null 2>&1 <<<"$source")

if [ "$valid_json" ]; then
  echo -e "${REKT}The provided source is not a valid JSON!${NC}"
  exit 1
fi

echo ""
echo -e "${BOLD}App ID:${NC} ${appid}"
echo -e "${BOLD}Access Token:${NC} ${accesstoken}"
echo -e "${BOLD}Network:${NC} ${networkname}"
echo -e "${BOLD}Epoch:${NC} ${epoch}"
echo -e "${BOLD}Minimum Lovelace is:${NC} ${minlovelace}"
echo -e "${BOLD}Minimum Loyalty is:${NC} ${minloyalty}"
echo -e "${BOLD}Per Epoch Loyalty Modifier:${NC} ${loyaltymod}"
echo -e "${BOLD}Max Rewards are:${NC} ${maxreward}"
echo -e "${BOLD}Min Rewards are:${NC} ${minreward}"

message="Instant pool rewards"

if [ -n "${ticker}" ]; then
  message="${message} from ${ticker}"
fi

if [ -n "${epoch}" ]; then

  message="${message} (Epoch #${epoch})"

fi

if [ -n "${perada}" ]; then

  echo -e "${BOLD}Tokens per ADA is:${NC} ${perada} tokens"

  amt_arg='(.delegatedLovelace|tonumber / 1000000 * ($perADA|tonumber))'
  flatrate=0

elif [ -n "${flatrate}" ]; then

  echo -e "${BOLD}Flat rate of:${NC} ${flatrate} tokens!"

  amt_arg='($flatRate|tonumber)'
  perada=0

else

  amt_arg='1'
  flatrate=0
  perada=0

fi

echo ""

jq_arg='
  def minVal(min): if (min|tonumber) == 0 then . else if (.|tonumber) < (min|tonumber) then min else . end end;
  def maxVal(max): if (max|tonumber) == 0 then . else if (.|tonumber) > (max|tonumber) then max else . end end;
  def doBonus(n): . * n;
  sort_by((.delegatedLovelace|tonumber),.poolLoyaltyEpochs|tonumber) |
  reverse |
  map(
   select(.delegatedLovelace|tonumber - 1 >= ($minLovelace|tonumber)) |
   select(.poolLoyaltyEpochs|tonumber >= ($minLoyalty|tonumber)) |
   .poolLoyaltyEpochs as $loyaltyEpochs |
   pow($loyaltyMod|tonumber;$loyaltyEpochs|tonumber) as $loyaltyBonus |
   {
     address: .stakeAddress,
     amount: '"${amt_arg}"'|doBonus($loyaltyBonus)|minVal($minReward|tonumber)|maxVal($maxReward|tonumber)|floor|tonumber,
     reason: $reason
   }
  ) |
  map(select(.amount|tonumber > 0)) |
  _nwise(.;($batchLimit|tonumber)) |
  {rewards: .}'

groups=$(jq -c \
  --arg minLovelace "$minlovelace" \
  --arg minLoyalty "$minloyalty" \
  --arg reason "$message" \
  --arg perADA $perada \
  --arg flatRate $flatrate \
  --arg loyaltyMod "$loyaltymod" \
  --arg minReward "$minreward" \
  --arg maxReward "$maxreward" \
  --arg batchLimit "$BATCH_LIMIT" \
  "${jq_arg}" <<<"$source")

total_requests_needed=$(jq -s '. | length' <<<"$groups")

echo ""
echo -e "Preparing to send ${SUCCESS}${total_requests_needed}${NC} API requests..."
echo ""

echo "$groups" >./test.output.json

total_rewards=$(jq -s -r '[.[].rewards[].amount]|add' <<<"$groups")
total_addresses=$(jq -s -r '[.[].rewards[]]|length' <<<"$groups")

if [[ "${dryrun}" == 1 ]]; then
  poolid="${poolid:-delegates}"
  RESULTS_OUTPUT_PATH="./rewards/${poolid}/${epoch}.dryrun.json"
  OUTPUT_DIR="$(dirname "${RESULTS_OUTPUT_PATH}")"
  mkdir -p "$OUTPUT_DIR"
  echo -e "${SUCCESS}PERFORMING REWARDS 'DRY RUN' TO ANALYZE BEFORE SUBMITTING VIA API!${NC}"
  echo -e "Results can be found at ${RESULTS_OUTPUT_PATH}"
  jq -s '.' <<<"$groups" >"$RESULTS_OUTPUT_PATH"

else
  jq -c -s '.[]' <<<"$groups" | while read -r i; do
    batch_rewards_count=$(jq -r '.rewards|length' <<< "$i")
    batch_rewards_total=$(jq -r '[.rewards[].amount]|add' <<< "$i")
    echo -e "${BOLD}Sending API rewards for ${batch_rewards_count} addresses with a total of ${batch_rewards_total} tokens!${NC}"
    base_uri=$(echo "${DDZ_API_BASE_URI}" | tr -d '\r')
    url="${base_uri}/create"
    curl_response=$(curl -s --http1.1 \
      --header "X-App-Id: ${appid}" \
      --header "X-Access-Token: ${accesstoken}" \
      --header 'Content-Type: application/json' \
      --data "$i" \
      --location "${url}")
    message=$(jq -r '.data' <<< "$curl_response")
    if [[ "$message" == "Success" ]]; then
      echo -e "${SUCCESS}${message}${NC}"
    else
      echo -e "${REKT}${message}${NC}"
    fi
  done
fi

echo ""
echo -e "Total Tokens Awarded: ${BOLD}${total_rewards}${NC}"
echo -e "Total Addresses Rewarded: ${BOLD}${total_addresses}${NC}"
