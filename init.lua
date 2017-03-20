sv=nil

tmr.create():alarm(5000, tmr.ALARM_SINGLE, function()

print("*************************************************************")
print("Iniciando ESP em modo Access POint")
print("\tConecte na rede SetupGadget e acesse o IP do Gateway")
wifi.setmode(wifi.SOFTAP)
--wifi.ap.setip({ip="192.168.0.2", netmask="255.255.255.0", gateway="192.168.0.1"})
--wifi.ap.config({ssid="ESP8266-Setup", auth=wifi.OPEN})
enduser_setup.manual(false)

enduser_setup.start(
  function()
    --enduser_setup.stop()
    print("Conectado na rede wifi com o ip: ".. wifi.sta.getip())

    wifi.setmode(wifi.NULLMODE)
    wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, gotip1)
    tmr.create():alarm(10000, tmr.ALARM_SINGLE, function()
        wifi.setmode(wifi.STATION)
        wifi.sta.connect()
    end)
  end,
  function(err, str)
    print("enduser_setup: Erro #" .. err .. ": " .. str)
  end,
  print -- Lua print para callback de debug (nao usado)
)

end)

function gotip1(T)
    print("STA - Recebeu IP".."\n\tIP da Estacao: "..T.IP.."\n\tMascara de rede: "..T.netmask.."\n\tIP Gateway: "..T.gateway)
    
    print("Criando o server")
    sv=net.createServer(net.TCP, 60)

    startServer(1)

end

function startServer(tentativa)
    print("\tTentativa "..tentativa)
    if tentativa <= 5 then
        if pcall(function() sv:listen(80, listen1) end) then
            print("\tSucesso. Pode acessar a pagina.")
        else
            print("\tFalhou. Aguarde 5 segundos.")
            tmr.create():alarm(5000, tmr.ALARM_SINGLE, function()
                 startServer(tentativa + 1)
            end)
        end
    else
        print("\tDesisto. Fim do programa.")
    end
end

function listen1(c)
    c:on("receive", function(sck, req)

    local ht = {}
    table.insert(ht, "<html>")
    table.insert(ht, "<head>")
    table.insert(ht, "<title>Server ESP8266</title>")
    table.insert(ht, "</head>")
    table.insert(ht, "<body>")

    table.insert(ht, "<h1>Server ESP8266</h1>")
    table.insert(ht, "<p>Aqui vai os comandos do server</p>")
    
    table.insert(ht, "</body>")
    table.insert(ht, "</html>")
    local sht = 0
    for key, value in pairs(ht) do
        sht = sht + string.len(value) + 1
    end

    table.insert(ht, 1, "HTTP/1.0 200 OK")
    table.insert(ht, 2, "Server: ESP8266")
    table.insert(ht, 3, "Content-Type: text/html; charset=UTF-8")
    table.insert(ht, 4, "Content-Length: " .. sht .. "\n")

    local function sender (sck)
        if #ht>0 then 
            sck:send(table.remove(ht,1) .. "\n")
        else 
            sck:close()
        end
    end
    sck:on("sent", sender)
    sender(sck)
    end)
end

