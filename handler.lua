local Prefix = ...

local Client = loadstring(game:HttpGet("https://raw.github.com/0zBug/DiscordClient/main/client.lua"))()

local Descriptions = {}
local Commands = {}

local function AddCommand(Name, Description, Callback)
    Commands[Name] = Callback

    table.insert(Descriptions, {
        Name = Name,
        Description = Description
    })
end

Client:Connect("Message", function(Message)
    if not Message.author.bot then
        if Message.content:sub(1, #Prefix) == Prefix then
            local Args = string.split(Message.content, " ")
            local Command = string.lower(string.sub(Args[1], #Prefix + 1))

            if Commands[Command] then
                table.remove(Args, 1)

                local Success, Error = pcall(function()
                    Commands[Command](Message, Args)
                end)
                
                if not Success then
                    warn(Error)
                end
            end
        end
    end
end)

return Client, AddCommand
