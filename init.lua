-- constants
local WELCOME_MESSAGE = "Welcome, %s! Type /chat_help <topic>, /chat_tip for a random tip, /chat_find to find a resource or /chat_menu for help. Type /note to write a note and /note_list to see them"
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

-- tips
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

-- note storage
local storage = minetest.get_mod_storage()

local function save_player_notes(name, notes)
    local json = minetest.write_json(notes or {})
    storage:set_string("notes:" .. name, json)
end

local function load_player_notes(name)
    local data = storage:get_string("notes:" .. name)
    if data and data ~= "" then
        return minetest.parse_json(data) or {}
    end
    return {}
end

-- functions
local function get_random_tip()
    return random_tips[math.random(#random_tips)]
end

local function get_help_response(topic)
    return help_responses[topic] or UNKNOWN_TOPIC_MESSAGE
end

local function send_unknown_message(name, msg)
    minetest.chat_send_player(name, msg)
end

local function show_menu(player)
    local formspec = "size[8,8]"
    local topics = { "resources", "building", "enemies", "food", "exploring", "crafting" }
    for i, topic in ipairs(topics) do
        formspec = formspec .. string.format("button[0.5,%s;7,0.5;%s;%s]", (i - 1) * 1.0 + 1, topic, topic)
    end
    minetest.show_formspec(player:get_player_name(), "chat_guide:chat_menu", formspec)
end

-- note UI
local function display_notes(player)
    local name = player:get_player_name()
    local notes = load_player_notes(name)

    local formspec = "size[6,8]label[0.5,0.5;Your Notes:]"
    for i, note in ipairs(notes) do
        formspec = formspec ..
            string.format("label[0.5,%s;%s]", 1 + i * 1.2, minetest.formspec_escape(note)) ..
            string.format("button[5,%s;1,0.8;delete_note_%d;Delete]", 1 + i * 1.2, i)
    end

    local height = math.max(8, 1 + #notes * 1.2)
    formspec = string.gsub(formspec, "size%[6,8%]", "size[6," .. height .. "]")
    minetest.show_formspec(name, "chat_guide:notes_display", formspec)
end

local function open_note_writer(player)
    local formspec =
        "size[6,3]" ..
        "field[0.5,0.5;5,1;note;Write your note here:;]" ..
        "button[1,2;2,1;save;Save]" ..
        "button[3.5,2;2,1;cancel;Cancel]"
    minetest.show_formspec(player:get_player_name(), "chat_guide:note_writer", formspec)
end

local function save_note(player, note)
    local name = player:get_player_name()
    local notes = load_player_notes(name)
    table.insert(notes, note)
    save_player_notes(name, notes)
    minetest.chat_send_player(name, "Saved note.")
    display_notes(player)
end

local function delete_note(player, index)
    local name = player:get_player_name()
    local notes = load_player_notes(name)
    if notes[index] then
        table.remove(notes, index)
        save_player_notes(name, notes)
        minetest.chat_send_player(name, "Deleted note.")
        display_notes(player)
    else
        minetest.chat_send_player(name, "No notes to delete.")
    end
end

-- commands
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
    description = "Get a random tip.",
    func = function(name)
        minetest.chat_send_player(name, get_random_tip())
        return true
    end
})

minetest.register_chatcommand("chat_menu", {
    description = "Open the help menu.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            show_menu(player)
        end
        return true
    end
})

minetest.register_chatcommand("note", {
    description = "Write a new note.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            open_note_writer(player)
        end
    end
})

minetest.register_chatcommand("note_list", {
    description = "View your saved notes.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            display_notes(player)
        end
    end
})

-- form handlers
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()

    if formname == "chat_guide:note_writer" then
        if fields.save then
            if fields.note and fields.note:match("%S") then
                save_note(player, fields.note)
            else
                minetest.chat_send_player(name, "Write something before saving.")
            end
        elseif fields.cancel then
            minetest.chat_send_player(name, "Cancelled note.")
        end
    elseif formname == "chat_guide:notes_display" then
        local notes = load_player_notes(name)
        for i = 1, #notes do
            if fields["delete_note_" .. i] then
                delete_note(player, i)
                return true
            end
        end
    elseif formname == "chat_guide:chat_menu" then
        for topic, _ in pairs(help_responses) do
            if fields[topic] then
                minetest.chat_send_player(name, get_help_response(topic))
                return true
            end
        end
    end
end)

--chat_near
minetest.register_chatcommand("chat_near", {
    description = "Shows all the common recources nearby.",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end

        local player_pos = vector.round(player:get_pos())
        local radius = 10
        local found = {}
        for x = -radius, radius do
            for y = -radius, radius do
                for z = -radius, radius do
                    local pos = vector.add(player_pos, {x = x, y = y, z = z})
                    local node = minetest.get_node(pos).name
                    if node and node ~= "air" then
                        if not found[node] then found[node] = 0 end
                        found[node] = found[node] + 1
                    end
                end
            end
        end

        local sorted = {}
        for k, v in pairs(found) do table.insert(sorted, {name = k, count = v}) end
        table.sort(sorted, function(a, b) return a.count > b.count end)

        local msg = "Recources nearby:\n"
        for i = 1, math.min(5, #sorted) do
            msg = msg .. string.format("- %s: %d blocks\n", sorted[i].name, sorted[i].count)
        end
        minetest.chat_send_player(name, msg)
    end
})


-- welcome message
minetest.register_on_joinplayer(function(player)
    local msg = WELCOME_MESSAGE:format(player:get_player_name())
    minetest.chat_send_player(player:get_player_name(), msg)
end)

-- find resource
local function calculate_distance(pos1, pos2)
    return vector.distance(pos1, pos2)
end

local function get_node_for_resource(resource)
    if not resource or type(resource) ~= "string" or resource == "" then
        return nil
    end
    resource = resource:lower()
    for node, _ in pairs(minetest.registered_nodes) do
        if string.find(node:lower(), resource) then
            return node
        end
    end
    return nil
end

--chat find
minetest.register_chatcommand("chat_find", {
    params = "<resource>",
    description = "Find nearest resource.",
    func = function(name, resource)
        local player = minetest.get_player_by_name(name)
        if not player then return false end
        if not resource or resource == "" then
            return minetest.chat_send_player(name, "Please specify a valid resource.")
        end
        local target_node = get_node_for_resource(resource)
        if not target_node then
            return minetest.chat_send_player(name, string.format("'%s' not found or unknown.", resource))
        end

        local origin = vector.round(player:get_pos())
        local closest, dist = nil, math.huge
        local radius = 20

        for dx = -radius, radius do
            for dy = -radius, radius do
                for dz = -radius, radius do
                    local pos = vector.add(origin, {x = dx, y = dy, z = dz})
                    if minetest.get_node(pos).name == target_node then
                        local d = vector.distance(origin, pos)
                        if d < dist then
                            closest, dist = pos, d
                        end
                    end
                end
            end
        end

        if closest then
            minetest.chat_send_player(name,
                string.format("Found '%s' %.2f blocks away at (%.0f, %.0f, %.0f).",
                resource, dist, closest.x, closest.y, closest.z))
        else
            minetest.chat_send_player(name, string.format("'%s' not found nearby.", resource))
        end
        return true
    end
})

-- enemy detection
local last_warning_time = {}
local function is_hostile_entity(entity)
    if entity and not entity:is_player() then
        local name = entity:get_entity_name() or ""
        local hostiles = {
            "zombie", "skeleton", "spider", "slime", "silverfish", "husk", "pillager",
            "illusioner", "vindicator", "vex", "evoker", "stray", "rover", "endermite",
            "shulker", "piglin", "hoglin", "blaze", "guardian", "stalker", "overloaded stalker"
        }
        for _, hostile in ipairs(hostiles) do
            if name:lower():find(hostile) then
                return true
            end
        end
    end
    return false
end

local function check_for_hostiles(player)
    local pos = player:get_pos()
    local name = player:get_player_name()
    local time = minetest.get_gametime()
    if last_warning_time[name] and time - last_warning_time[name] < 10 then return end

    for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 10)) do
        if is_hostile_entity(obj) then
            minetest.chat_send_player(name, "Warning: Hostile entity nearby!")
            last_warning_time[name] = time
            break
        end
    end
end

minetest.register_globalstep(function(dtime)
    if minetest.get_gametime() % 5 < dtime then
        for _, player in ipairs(minetest.get_connected_players()) do
            check_for_hostiles(player)
        end
    end
end)
