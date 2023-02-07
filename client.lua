local Client = {}

local Callbacks = {}
local Socket, Connected

local request = request or syn.request
local websocket = syn and syn.websocket or WebSocket
local HttpService = game:GetService("HttpService")

local function Endpoint(Method, Path, Data)
    local Request = Method == "GET" and {
        Method = Method,
        Url = "https://discord.com/api/v8" .. Path,
        Headers = {
            ["Authorization"] = Client.token
        }
    } or {
        Method = Method,
        Url = "https://discord.com/api/v8" .. Path,
        Body = Data and HttpService:JSONEncode(Data) or nil,
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = Client.token
        }
    }

    return HttpService:JSONDecode(request(Request).Body)
end

local Classes
Classes = {
    ["User"] = function(User)
        if tonumber(User) then
            return Endpoint("GET", "/users/" .. User)
        end
    
        return User
    end,
    ["Channel"] = function(Channel)
        if tonumber(Channel) then
            return Classes.Channel(Endpoint("GET", "/channels/" .. Channel))
        end

        function Channel:Send(Message, Options)
            local Data = Options or {}
            Data.content = Message
            
            return Classes.Message(Endpoint("POST", "/channels/" .. Channel.id .. "/messages", Data))
        end
    
        return Channel
    end,
    ["Message"] = function(Message, Channel)
        if Message.r then
            local message = Endpoint("GET", "/channels/" .. Message.channel .. "/messages/" .. Message.message)
            return Classes.Message(message, Channel)
        end

        Message.channel = Channel or Message.channel_id and Classes.Channel(Message.channel_id)
        Message.author = Classes.User(Message.author)

        function Message:Delete()
            return Endpoint("DELETE", "/channels/" .. Message.channel_id .. "/messages/" .. Message.id)
        end

        function Message:Edit(Text, Options)
            local Data = Options or {}
            Data.content = Text
            
            return Classes.Message(Endpoint("PATCH", "/channels/" .. Message.channel_id .. "/messages/" .. Message.id, Data))
        end

        return Message
    end,
    ["Interaction"] = function(Interaction, Channel)
        Interaction.message = Interaction.message and Classes.Message(Interaction.message)
        Interaction.channel = Channel or Classes.Channel(Interaction.channel_id)

        return Interaction
    end
}

local Listeners = {
    ["MESSAGE_CREATE"] = {
        Name = "Message",
        Callback = function(Data, Callback)
            Callback(Classes.Message(Data))
        end
    },
    ["INTERACTION_CREATE"] = {
        Name = "Interaction",
        Callback = function(Data, Callback)
            Endpoint("POST", string.format("/interactions/%s/%s/callback", Data.id, Data.token), {
                type = 4
            })

            Callback(Classes.Interaction(Data))
        end
    }
}

function Client:Start(Token)
    self.token = Token

    Socket = websocket.connect("wss://gateway.discord.gg/?v=10&encoding=json")
    Socket:Send(string.format('{"d":{"token":"%s","properties":{"$device":"chrome","$browser":"chrome","$os":"linux"}},"op":2}', self.token))

    task.spawn(function()
        while task.wait(30) do
            Socket:Send('{"d":"null","op":1}')
        end
    end)

    Socket.OnMessage:Connect(function(Message)
        local Payload = HttpService:JSONDecode(Message)
        
        if Payload.op == 0 then
            local Listener = Listeners[Payload.t]
            if Listener then
                Listener.Callback(Payload.d, function(...)
                    if Callbacks[Listener.Name] then
                        local args = {...}

                        for _, Callback in pairs(Callbacks[Listener.Name]) do
                            Callback(unpack(args))
                        end
                    end
                end)
            end
        end
    end)

    Socket.OnClose:Connect(function()
        Connected = false
    end)
end

function Client:Close()
    Socket:Close()
end

function Client:Connect(Event, Callback)
    if not Callbacks[Event] then
        Callbacks[Event] = {}
    end

    table.insert(Callbacks[Event], Callback)
end

return Client
