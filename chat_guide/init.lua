-- constants
local WELCOME_MESSAGE = "Welcome, %s! Type /chat_help <topic>, /chat_tip for a random tip, /chat_find to find a resource or /chat_menu for help.Type /note to write a note and /note_list to see them"
local UNKNOWN_TOPIC_MESSAGE = "Unknown topic. Try: 'resources', 'building', 'enemies', 'food', 'exploring', 'crafting', 'mining', 'weather', 'biomes', 'minerals', 'iron', 'gold', 'diamonds', 'nether'."
local UNKNOWN_RESOURCE_MESSAGE = "Unknown resource. Try: apple tree, stone, coal, iron, gold, diamond, quartz, glowstone."

-- responses
local help_responses = {
    resources = "Gather apples from apple trees, find stone in caves, and mine coal underground. Equip a pickaxe!",
    building = "Use different blocks to build a structure. Use your hotbar for building.",
    enemies = "Beware of zombies and skeletons. Craft a sword and armor for protection!",
    food = "Hunt cows and pigs for meat, or forage for fruits in different biomes.",
    exploring = "Explore caves and mountains for resources. Bring torches to light your way!",
    crafting = "Use a crafting table for complex items. Check the Luanti wiki for guides.",
    mining = "Dig deep to find diamonds and rare minerals. Upgrade your pickaxe for better results!",
    weather = "Change the weather with /weather [sunny/rainy]. Keep an eye on storms!",
    biomes = "Explore various biomes for unique resources. Don’t miss the deserts and forests!",
    minerals = "Find iron, gold, and diamonds underground. Use a stone pickaxe for iron ore!",
    iron = "Iron ore is found in stone layers. Smelt it in a furnace for iron ingots.",
    gold = "Gold ore is deeper underground. It's less durable than iron but great for decoration.",
    diamonds = "Diamonds are rare and deep in the ground. Use an iron pickaxe to mine them!",
}

-- random tips
local random_tips = {
    "Always carry extra tools when exploring!",
    "Cooking food improves its nutritional value!",
    "Build a base to stay safe at night!",
    "Visit villages for valuable resources!",
    "Experiment with crafting for unique items!",
    "Watch the weather; storms can be dangerous!",
    "Use torches to light your surroundings!",
    "Collect resources regularly to stay prepared!",
    "Stay aware of your surroundings to avoid ambushes!",
    "Learn the map layout for shortcuts!",
    "Trade with villagers for unique items!"
}

-- helper functions
local function send_unknown_message(player_name, message)
    minetest.chat_send_player(player_name, message)
end

local function get_random_tip()
    return random_tips[math.random(#random_tips)]
end

local function get_help_response(topic)
    return help_responses[topic] or UNKNOWN_TOPIC_MESSAGE
end

local function show_menu(player)
    local formspec = "size[8,8]"

    -- buttons
    local topics = { "resources", "building", "enemies", "food", "exploring", "crafting" }
    for i, topic in ipairs(topics) do
        formspec = formspec .. string.format("button[0.5,%s;7,0.5;%s;%s]", (i - 1) * 1.0 + 1, topic, topic)
    end

    minetest.show_formspec(player:get_player_name(), "chat_guide:chat_menu", formspec)
end

minetest.register_chatcommand("chat_help", {
    params = "<topic>",
    description = "Ask the Chat Guide for help.",
    func = function(name, param)
        if not param or param == "" then
            send_unknown_message(name, "Please specify a valid topic.")
            return true
        end

        local response = get_help_response(param)
        minetest.chat_send_player(name, response)
        return true
    end
})

minetest.register_chatcommand("chat_tip", {
    description = "Get a random tip from the Chat Guide.",
    func = function(name)
        minetest.chat_send_player(name, get_random_tip())
        return true
    end
})

minetest.register_chatcommand("chat_menu", { 
    description = "Open the Chat Guide help menu.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            show_menu(player)
        else
            minetest.chat_send_player(name, "You must be a valid player to access the Chat Guide menu.")
        end
        return true
    end
})

-- topics in window
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "chat_guide:chat_menu" then
        local player_name = player:get_player_name()
        
        local topics = { "resources", "building", "enemies", "food", "exploring", "crafting", "biomes", "minerals", "iron", "gold", "diamonds" }

        for _, topic in ipairs(topics) do
            if fields[topic] then

                minetest.chat_send_player(player_name, get_help_response(topic))
                return true
            end
        end
    end
end)


-- welcome message
minetest.register_on_joinplayer(function(player)
    local welcome_message = WELCOME_MESSAGE:format(player:get_player_name())
    minetest.chat_send_player(player:get_player_name(), welcome_message)
end)

local function check_player_position(player)
    local pos = player:get_pos()
end

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        check_player_position(player)
    end
end)

local function calculate_distance(pos1, pos2)
    return math.sqrt((pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2 + (pos2.z - pos1.z)^2)
end

-- get node name
local function get_node_for_resource(resource_name)
    if not resource_name or type(resource_name) ~= "string" or resource_name == "" then
        return nil
    end

    resource_name = resource_name:lower()

    for node_name, _ in pairs(minetest.registered_nodes) do
        if string.find(node_name:lower(), resource_name) then
            return node_name
        end
    end

    return nil
end

-- chat_find
minetest.register_chatcommand("chat_find", { 
    params = "<resource>",
    description = "Find the nearest resource in the world.",
    func = function(name, resource)
        local player = minetest.get_player_by_name(name)
        if not player then return false end

        if not resource or resource == "" then
            minetest.chat_send_player(name, "Please specify a valid resource to search for.")
            return true
        end

        local actual_node_name = get_node_for_resource(resource)

        if not actual_node_name then
            minetest.chat_send_player(name, string.format("The resource '%s' is not recognized or is not available in the world.", resource))
            return true
        end

        local player_pos = player:get_pos()
        local closest_distance = math.huge
        local closest_pos = nil

        local radius = 20
        for x = math.floor(player_pos.x - radius), math.floor(player_pos.x + radius) do
            for y = math.floor(player_pos.y - radius), math.floor(player_pos.y + radius) do
                for z = math.floor(player_pos.z - radius), math.floor(player_pos.z + radius) do
                    local node_name = minetest.get_node({x = x, y = y, z = z}).name
                    if node_name == actual_node_name then
                        local distance = calculate_distance(player_pos, {x = x, y = y, z = z})
                        if distance < closest_distance then
                            closest_distance = distance
                            closest_pos = {x = x, y = y, z = z}
                        end
                    end
                end
            end
        end

        -- player answer
        if closest_pos then
            minetest.chat_send_player(name, string.format("The resource '%s' is %.2f blocks away at coordinates: (%.0f, %.0f, %.0f).",
                                                            resource, closest_distance, closest_pos.x, closest_pos.y, closest_pos.z))
        else
            minetest.chat_send_player(name, string.format("The resource '%s' is not found nearby.", resource))
        end

        return true
    end
})

local player_notes = {}

-- see the saved note
local function display_notes(player)
    local player_name = player:get_player_name()

    player_notes[player_name] = player_notes[player_name] or {}

    local notes = player_notes[player_name]
    local formspec = "size[6,8]label[0.5,0.5;Your Notes:]"
    
    -- Aggiungi le note al formspec
    for i, note in ipairs(notes) do
        formspec = formspec .. string.format("label[0.5,%s;%s]", 1 + i * 1.2, note)
        formspec = formspec .. string.format("button[5,%s;1,0.8;delete_note_%d;Delete]", 1 + i * 1.2, i)
    end

    local height = math.max(8, 1 + #notes * 1.2)
    formspec = string.gsub(formspec, "size[6,8]", "size[6," .. height .. "]")

    minetest.show_formspec(player_name, "chat_guide:notes_display", formspec)
end

local function open_note_writer(player)
    local formspec = "size[6,3]field[0.5,0.5;5,1;note;Write your note here:;]button[2,2;2,1;save;Save]button[4,2;2,1;cancel;Cancel]"
    minetest.show_formspec(player:get_player_name(), "chat_guide:note_writer", formspec)
end

-- save note
local function save_note(player, note_content)
    local player_name = player:get_player_name()

    player_notes[player_name] = player_notes[player_name] or {}

    table.insert(player_notes[player_name], note_content)
    minetest.chat_send_player(player_name, "Your note has been saved.")
    display_notes(player)  -- Mostra le note aggiornate
end

-- delete note
local function delete_note(player, note_index)
    local player_name = player:get_player_name()

    if player_notes[player_name] and player_notes[player_name][note_index] then
        table.remove(player_notes[player_name], note_index)
        minetest.chat_send_player(player_name, "Note deleted.")
        display_notes(player)
    else
        minetest.chat_send_player(player_name, "No such note to delete.")
    end
end

local function is_empty_string(str)
    return not str or str:match("^%s*$")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local player_name = player:get_player_name()

    if formname == "chat_guide:note_writer" then
        if fields.save then
            if fields.note and not is_empty_string(fields.note) then
                save_note(player, fields.note)
                open_note_writer(player)
            else
                minetest.chat_send_player(player_name, "Please write something in the note field.")
            end
        elseif fields.cancel then
            minetest.chat_send_player(player_name, "Note writing canceled.")
        end
    end

    if formname == "chat_guide:notes_display" then
        for i = 1, #player_notes[player_name] do
            if fields["delete_note_"..i] then
                delete_note(player, i)
                return
            end
        end
    end
end)

-- note command
minetest.register_chatcommand("note", {
    description = "Opens a window to write a note",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            open_note_writer(player)
        end
    end
})

-- note_list command
minetest.register_chatcommand("note_list", {
    description = "Displays all your saved notes",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            display_notes(player)
        end
    end
})

-- HUD next update

-- warning enemies
local last_warning_time = {}

local function is_hostile_entity(entity)
    if not entity or not entity:is_player() then
        local name = entity:get_entity_name()
        local hostile_entities = {"zombie", "skeleton","stalker","overloaded stalker", "spider","slime","silverfish","husk", "pillager","illusioner","vindicator","vex","evoker","stray", "rover","endermite","shulker","zombie piglin","piglin","hoglin","blaze","guardian"}
        for _, hostile in ipairs(hostile_entities) do
            if string.find(name:lower(), hostile) then
                return true
            end
        end
    end
    return false
end

local function check_for_hostiles(player)
    local player_pos = player:get_pos()
    local detection_radius = 10
    local entities_in_range = minetest.get_objects_inside_radius(player_pos, detection_radius)
    
    local current_time = minetest.get_gametime()
    local warning_interval = 10
    
    for _, entity in ipairs(entities_in_range) do
        if is_hostile_entity(entity) then
            local player_name = player:get_player_name()
            if not last_warning_time[player_name] or (current_time - last_warning_time[player_name] >= warning_interval) then
                minetest.chat_send_player(player_name, "Warning: A hostile entity is nearby!")
                last_warning_time[player_name] = current_time
            end
            return
        end
    end
end

minetest.register_globalstep(function(dtime)
    local check_interval = 5
    if minetest.get_gametime() % check_interval < dtime then
        for _, player in ipairs(minetest.get_connected_players()) do
            check_for_hostiles(player)
        end
    end
end)
