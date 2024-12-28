#!/bin/bash

echo "App bindings processing started."

get_space_ids() {
  # Query the spaces and extract both ManagedSpaceID and uuid
  # Clean up the UUIDs by removing semicolons
  defaults read com.apple.spaces | \
    grep -E 'ManagedSpaceID|uuid' | \
    awk -F' = ' '{gsub("\"", "", $2); gsub(";", "", $2); print $2}' | \
    paste - -  # Pairs ManagedSpaceID with uuid
}

# Get and store space IDs
space_ids=$(get_space_ids)

# Debug: Show raw space IDs
# echo "Raw Space IDs:"
# echo "$space_ids"

# Deduplicate the space_ids
deduped_space_ids=$(echo "$space_ids" | sort | uniq)

# Debug: Show deduplicated space IDs
# echo -e "\nDeduplicated Space IDs:"
# echo "$deduped_space_ids"

# Store the space mappings into a space_map associative array
declare -A space_map
declare -A seen_spaces  # To track and deduplicate spaces by ManagedSpaceID

# Initialize counter for space numbers
current_space=1

# Populating space_map from deduplicated space IDs
while IFS=$'\t' read -r space_id uuid; do
  # Check if this space ID is already seen
  if [ -z "${seen_spaces[$space_id]}" ]; then
    seen_spaces["$space_id"]=1
    space_map["$current_space"]="$uuid"  # Map space number to UUID
    # echo "Mapping Space $current_space -> UUID $uuid (Space ID: $space_id)"
    ((current_space++))
  fi
done <<< "$deduped_space_ids"

# Debug: Verify the space_map is correctly populated
# echo -e "\nSpaces and their UUIDs (Deduplicated):"
# for space_num in "${!space_map[@]}"; do
#   echo "Space $space_num -> UUID ${space_map[$space_num]}"
# done

update_app_bindings() {
  local app_id="$1"
  local uuid="$2"
  # Check if the app-bindings key exists

  defaults write com.apple.spaces "app-bindings" -dict-add "$app_id" "$uuid"
}

declare -A app_bindings
app_bindings=(
	["com.apple.safari"]="1"
	["com.brave.Browser"]="1"
	["com.mitchellh.ghostty"]="2"
	["com.apple.Terminal"]="2"
	["dev.kdrag0n.MacVirt"]="2"
	["com.apple.notes"]="3"
	["com.apple.reminders"]="3"
	["net.whatsapp.whatsapp"]="4"
	["com.apple.MobileSMS"]="4"
	["com.apple.mail"]="5"
	["com.apple.ical"]="5"
	["com.adobe.Photoshop"]="6"
	["com.adobe.illustrator"]="6"
	["com.apple.ScreenSharing"]="6"
	["com.apple.Music"]="7"
)

defaults delete com.apple.spaces "app-bindings" 2>/dev/null || true

# Process each app binding
for app_id in "${!app_bindings[@]}"; do
	# echo -e "\nProcessing $app_id"
	space_number="${app_bindings[$app_id]}"
	# echo "Desired Space Number: $space_number"

  # Ensure space_number is valid before accessing space_map
  if [[ -z "$space_number" ]]; then
	  echo "Error: No space number found for app $app_id"
	  continue
  fi

  # Get the corresponding UUID for the space_number
  space_uuid="${space_map[$space_number]:-}"
  # echo "Retrieved UUID for Space $space_number: $space_uuid"

  # Update app binding if space_uuid exists
	echo "Mapping $app_id to UUID $space_uuid (Space $space_number)"
	# Uncomment the following line to actually update the bindings
	update_app_bindings "$app_id" "$space_uuid"
done

echo "App bindings processing completed."

killall Dock

echo "Dock restarted."
