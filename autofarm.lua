gg.setRanges(gg.REGION_ANONYMOUS | gg.REGION_C_ALLOC)
gg.clearResults()

--[[
  SCRIPT DE RIO RISE V2 SAFE
  Desenvolvido por: GIAN HENRIQUE
  Desenvolvido por: Plinio
  Versão: V0.5 SAFE MOD + SUBTERRÂNEO + DELAY PERSONALIZADO
]]

-- Configurações globais
local enderecoBase = nil
local offsets = {Y = 0x60, X = 0x64, Z = 0x68}
local posicoesSalvas = {}
local posicoesFarm = {}
local scriptAtivo = true
local caminhando = false
local velocidadeCaminhar = 50
local velocidadeCarregar = 50
local delayAutoFarm = 5
local movimentoTipo = "padrao" -- Opções: "padrao", "subterraneo", "aereo", "invisivel"
local versao = "V0.5 SAFE MOD + AUTOMÁTICO"
local maxPosicoesSalvas = 50 -- Aumentado de 10 para 50

-- Configurações subterrâneo
local alturaSubterraneo = -10.0 -- Altura padrão abaixo do chão
local tempoSubida = 1000 -- Tempo em milissegundos para subir/descer
local tempoCheckpoint = 2000 -- Tempo em milissegundos no checkpoint

-- Nome dos arquivos
local ARQUIVO_POSICOES = "gh_samp_posicoes_v3.dat"
local ARQUIVO_FARM = "gh_samp_farm_v3.dat"

-- Locais estratégicos
local RIO_RISE_SPOTS = {
    ["🏡 Fazenda"] = {x = 80.74, y = -49.74, z = 3.12},
    ["⛏️ Mina"] = {x = -1560.35, y = -97.57, z = 63.46},
    ["🔫 LOB Inicial"] = {x = -2655.95, y = -956.31, z = 32.81},
    ["🍔 Lanchonete"] = {x = -2603.21, y = -968.39, z = 32.85},
    ["👕 Loja de Roupa"] = {x = -2613.60, y = -1015.26, z = 32.85},
    ["🏪 Loja 24/7"] = {x = -2622.08, y = -1056.59, z = 32.85},
    ["🏦 Banco"] = {x = -2551.22, y = -1205.51, z = 33.34},
    ["🚗 Auto Escola"] = {x = -2562.07, y = -1281.41, z = 33.55},
    ["🏛️ Prefeitura"] = {x = -1848.71, y = 620.66, z = 3.95},
    ["🏥 HP"] = {x = -1918.17, y = 871.51, z = 2.57},
    ["👮 DP CV"] = {x = -1411.63, y = 652.67, z = 1.64},
    ["🔨 Leilão"] = {x = -1460.09, y = 707.97, z = 3.04}
}

-- Função para configurar movimento subterrâneo
function configurarSubterraneo()
    local configs = gg.prompt({
        "Altura abaixo do chão (negativo):",
        "Tempo para subir/descer (ms):",
        "Tempo no checkpoint (ms):"
    }, {tostring(alturaSubterraneo), tostring(tempoSubida), tostring(tempoCheckpoint)}, {"number", "number", "number"})
    
    if configs then
        alturaSubterraneo = tonumber(configs[1]) or alturaSubterraneo
        tempoSubida = tonumber(configs[2]) or tempoSubida
        tempoCheckpoint = tonumber(configs[3]) or tempoCheckpoint
        gg.toast(string.format("⚙️ Config subterrâneo: Altura %.1f, Tempos %d/%dms", alturaSubterraneo, tempoSubida, tempoCheckpoint))
    end
end

-- Função para movimento subterrâneo
function moverSubterraneo(x, y, z)
    local posAtual = obterCoordenadas()
    
    -- Descer para altura subterrânea
    local passosDescida = 10
    for i = 1, passosDescida do
        local progresso = i / passosDescida
        local novoZ = posAtual.z + (alturaSubterraneo - posAtual.z) * progresso
        definirCoordenadas(posAtual.x, posAtual.y, novoZ)
        gg.sleep(tempoSubida / passosDescida)
    end
    
    -- Mover para posição X/Y subterrânea
    local distanciaXY = math.sqrt((x - posAtual.x)^2 + (y - posAtual.y)^2)
    local passosMovimento = math.max(5, math.floor(distanciaXY / 10))
    
    for i = 1, passosMovimento do
        local progresso = i / passosMovimento
        local novoX = posAtual.x + (x - posAtual.x) * progresso
        local novoY = posAtual.y + (y - posAtual.y) * progresso
        definirCoordenadas(novoX, novoY, alturaSubterraneo)
        gg.sleep(50)
    end
    
    -- Subir para pegar checkpoint
    local passosSubida = 10
    for i = 1, passosSubida do
        local progresso = i / passosSubida
        local novoZ = alturaSubterraneo + (z - alturaSubterraneo) * progresso
        definirCoordenadas(x, y, novoZ)
        gg.sleep(tempoSubida / passosSubida)
    end
    
    -- Manter no checkpoint por um tempo
    definirCoordenadas(x, y, z)
    gg.sleep(tempoCheckpoint)
    
    -- Descer novamente
    for i = 1, passosDescida do
        local progresso = i / passosDescida
        local novoZ = z + (alturaSubterraneo - z) * progresso
        definirCoordenadas(x, y, novoZ)
        gg.sleep(tempoSubida / passosDescida)
    end
end

-- Função para salvar arquivo
function salvarArquivo(nomeArquivo, conteudo)
    local arquivo = io.open(nomeArquivo, "w")
    if arquivo then
        arquivo:write(conteudo)
        arquivo:close()
        return true
    end
    return false
end

-- Função para carregar arquivo
function carregarArquivo(nomeArquivo)
    local arquivo = io.open(nomeArquivo, "r")
    if arquivo then
        local conteudo = arquivo:read("*a")
        arquivo:close()
        return conteudo
    end
    return nil
end

-- Função para mostrar cabeçalho
function mostrarCabecalho()
    gg.clearResults()
    gg.toast("🔹 GIAN SAMP - RIO RISE "..versao.." 🔹", false)
    print("▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄")
    print("█ GIAN SAMP - RIO RISE "..versao.." █")
    print("▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀")
end

-- Função para salvar posição atual
function salvarPosicaoAtual(nomePadrao)
    local pos = obterCoordenadas()
    local nome = gg.prompt({"Digite um nome para esta posição:"}, {nomePadrao}, {"text"})
    
    if nome and nome[1] then
        if #posicoesSalvas >= maxPosicoesSalvas then
            table.remove(posicoesSalvas, 1)
        end
        
        table.insert(posicoesSalvas, {
            nome = nome[1],
            x = pos.x,
            y = pos.y,
            z = pos.z,
            delay = 5 -- Delay padrão de 5 segundos
        })
        
        salvarPosicoesNoArmazenamento()
        gg.toast("✅ Posição salva: "..nome[1].." ("..#posicoesSalvas.."/"..maxPosicoesSalvas..")")
    end
end

-- Função para editar delay de uma posição
function editarDelayPosicao()
    if #posicoesSalvas == 0 then
        gg.toast("🚫 Nenhuma posição salva disponível!")
        return
    end

    local opcoes = {}
    for i, pos in ipairs(posicoesSalvas) do
        table.insert(opcoes, pos.nome .. " (Delay: " .. (pos.delay or 500) .. "ms)")
    end

    local escolha = gg.choice(opcoes, nil, "⏱️ Escolha a posição para editar delay:")
    if not escolha then return end

    local entrada = gg.prompt({
        "Digite o valor do delay:",
        "Escolha a unidade (ms, s, min):"
    }, {
        tostring(posicoesSalvas[escolha].delay or 500),
        "ms"
    }, {
        "number", "text"
    })

    if entrada then
        local valor = tonumber(entrada[1]) or 500
        local unidade = entrada[2]:lower()

        local multiplicador = 1
        if unidade == "s" or unidade == "seg" or unidade == "segundo" or unidade == "segundos" then
            multiplicador = 1000
        elseif unidade == "min" or unidade == "minuto" or unidade == "minutos" then
            multiplicador = 60000
        end

        local delayFinal = math.max(50, valor * multiplicador)
        posicoesSalvas[escolha].delay = delayFinal
        salvarPosicoesNoArmazenamento()
        gg.toast("⏱️ Delay atualizado para " .. delayFinal .. "ms!")
    end
end


-- Funções de salvamento/carregamento
function salvarPosicoesNoArmazenamento()
    local dados = {}
    for i, pos in ipairs(posicoesSalvas) do
        table.insert(dados, string.format("%s|%.2f|%.2f|%.2f|%d", pos.nome, pos.x, pos.y, pos.z, pos.delay or 5))
    end
    if salvarArquivo(ARQUIVO_POSICOES, table.concat(dados, "\n")) then
        gg.toast("✅ Posições salvas com sucesso!")
    else
        gg.toast("Erro ao salvar posições!")
    end
end

function carregarPosicoesDoArmazenamento()
    local dados = carregarArquivo(ARQUIVO_POSICOES)
    if dados then
        posicoesSalvas = {}
        for linha in dados:gmatch("[^\n]+") do
            local partes = {}
            for parte in linha:gmatch("([^|]+)") do
                table.insert(partes, parte)
            end
            
            if #partes >= 4 then
                local posicao = {
                    nome = partes[1],
                    x = tonumber(partes[2]),
                    y = tonumber(partes[3]),
                    z = tonumber(partes[4]),
                    delay = tonumber(partes[5]) or 5 -- Default para 5s se não existir
                }
                table.insert(posicoesSalvas, posicao)
            end
        end
        gg.toast(string.format("📂 %d posições carregadas!", #posicoesSalvas))
    else
        gg.toast("Nenhuma posição salva encontrada!")
    end
end

-- Função para salvar posições de farm
function salvarPosicoesFarm()
    if #posicoesSalvas < 2 then
        gg.toast("🚫 Salve pelo menos 2 posições antes de configurar o auto farm!")
        return
    end

    local opcoes = {}
    for i, pos in ipairs(posicoesSalvas) do
        table.insert(opcoes, pos.nome .. " (X:" .. math.floor(pos.x) .. " Y:" .. math.floor(pos.y) .. ")")
    end

    local escolhas = gg.multiChoice(opcoes, nil, "✅ Selecione as posições para o Auto Farm (sem limite):")
    if not escolhas then return end

    posicoesFarm = {} -- limpa as anteriores

    for i = 1, #posicoesSalvas do
        if escolhas[i] then
            table.insert(posicoesFarm, posicoesSalvas[i])
        end
    end

    local dados = ""
    for i, pos in ipairs(posicoesFarm) do
        dados = dados .. string.format("%s|%.2f|%.2f|%.2f|%d\n", pos.nome, pos.x, pos.y, pos.z, pos.delay or 500)
    end

    if salvarArquivo(ARQUIVO_FARM, dados) then
        gg.toast("✅ Posições de farm salvas com sucesso!")
    else
        gg.toast("❌ Erro ao salvar posições de farm!")
    end
end

-- Função para carregar posições de farm
function carregarPosicoesFarm()
    local dados = carregarArquivo(ARQUIVO_FARM)
    if dados then
        posicoesFarm = {}
        for linha in dados:gmatch("[^\n]+") do
            local partes = {}
            for parte in linha:gmatch("([^|]+)") do
                table.insert(partes, parte)
            end
            
            if #partes >= 4 then
                local posicao = {
                    nome = partes[1],
                    x = tonumber(partes[2]),
                    y = tonumber(partes[3]),
                    z = tonumber(partes[4]),
                    delay = tonumber(partes[5]) or 5
                }
                table.insert(posicoesFarm, posicao)
            end
        end
        gg.toast(string.format("📂 %d posições de farm carregadas!", #posicoesFarm))
    else
        gg.toast("Nenhuma posição de farm salva encontrada!")
    end
end

-- Função para obter coordenadas
function obterCoordenadas()
    if not enderecoBase then inicializar() end
    
    local valores = gg.getValues({
        {address = enderecoBase + offsets.Y, flags = gg.TYPE_FLOAT},
        {address = enderecoBase + offsets.X, flags = gg.TYPE_FLOAT},
        {address = enderecoBase + offsets.Z, flags = gg.TYPE_FLOAT}
    })

    return {
        y = valores[1].value,
        x = valores[2].value,
        z = valores[3].value
    }
end

-- Função para definir coordenadas
function definirCoordenadas(x, y, z)
    if not enderecoBase then inicializar() end
    
    gg.setValues({
        {address = enderecoBase + offsets.X, flags = gg.TYPE_FLOAT, value = x},
        {address = enderecoBase + offsets.Y, flags = gg.TYPE_FLOAT, value = y},
        {address = enderecoBase + offsets.Z, flags = gg.TYPE_FLOAT, value = z}
    })
end

-- Função para caminhar com segurança
function caminharAtePosicao(x, y, z, tipoMovimento)
    local posAtual = obterCoordenadas()
    
    -- Salvamento silencioso (SEM TOAST)
    if #posicoesSalvas >= maxPosicoesSalvas then
        table.remove(posicoesSalvas, 1)
    end
    table.insert(posicoesSalvas, {
        nome = "Backup "..os.date("%H:%M:%S"),
        x = posAtual.x,
        y = posAtual.y,
        z = posAtual.z,
        delay = 5
    })
    
    if caminhando then
        gg.toast("⚠️ Já está caminhando para uma posição!")
        return
    end
    
    caminhando = true
    
    if tipoMovimento == "subterraneo" then
        moverSubterraneo(x, y, z)
    else
    definirCoordenadas(x, y, z)
    gg.toast("⚡ Teleporte rápido para destino!")
end
    
    caminhando = false
end

-- Função para caminhar para posição salva
function caminharParaPosicaoSalva()
    if #posicoesSalvas == 0 then
        gg.toast("🚫 Nenhuma posição salva disponível!")
        return
    end
    
    local opcoes = {}
    for i, pos in ipairs(posicoesSalvas) do
        table.insert(opcoes, pos.nome .. " (X:" .. math.floor(pos.x) .. " Y:" .. math.floor(pos.y) .. ")")
    end
    
    local escolha = gg.choice(opcoes, nil, "🧼 Escolha a posição para caminhar:")
    if not escolha then
        return
    end
    
    local posicao = posicoesSalvas[escolha]
    caminharAtePosicao(posicao.x, posicao.y, posicao.z, movimentoTipo)
end

-- Função para ajustar velocidade de carregamento
function ajustarVelocidadeCarregar()
    local novaVelocidade = gg.prompt({"Digite a velocidade de carregamento (1-100):"}, {tostring(velocidadeCarregar)}, {"number"})
    if novaVelocidade and tonumber(novaVelocidade[1]) then
        velocidadeCarregar = math.max(1, math.min(100, tonumber(novaVelocidade[1])))
        gg.toast("⚡ Velocidade de carregamento ajustada: " .. velocidadeCarregar .. "!")
    end
end

-- Função para ajustar delay do auto farm
function ajustarDelayAutoFarm()
    local novoDelay = gg.prompt({"Digite o delay entre as posições (segundos):"}, {tostring(delayAutoFarm)}, {"number"})
    if novoDelay and tonumber(novoDelay[1]) then
        delayAutoFarm = math.max(1, tonumber(novoDelay[1]))
        gg.toast("⏳ Delay do auto farm ajustado: " .. delayAutoFarm .. " segundos!")
    end
end

-- Função para configurar velocidade de teleporte
function configurarVelocidadeTeleporte()
    local novaVelocidade = gg.prompt({
        "Velocidade do teleporte (1-100):\n(1 = mais lento/suave, 100 = mais rápido)"},
        {tostring(velocidadeCarregar)},
        {"number"})
    
    if novaVelocidade and tonumber(novaVelocidade[1]) then
        velocidadeCarregar = math.max(1, math.min(100, tonumber(novaVelocidade[1])))
        gg.toast("⚡ Velocidade do teleporte: "..velocidadeCarregar)
    end
end

-- Função para o auto farm
function autoFarm()
    if #posicoesFarm == 0 then
        gg.toast("🚫 Nenhuma posição de farm configurada!")
        return
    end

    local executando = true
local ciclos = 0
local reverso = false

gg.alert("🔁 Auto Farm iniciado!\n\nToque no botão flutuante do GG para PARAR.")

while executando do
    -- Define a ordem das posições (normal ou reversa)
    local lista = reverso and {} or posicoesFarm

    if reverso and modoReversoAtivado then
        -- Copia posicoesFarm de trás pra frente
        for i = #posicoesFarm, 1, -1 do
            table.insert(lista, posicoesFarm[i])
        end
    end

    for _, posicao in ipairs(lista) do
        if not executando then break end

        local posAtual = obterCoordenadas()
        if #posicoesSalvas >= maxPosicoesSalvas then
            table.remove(posicoesSalvas, 1)
        end
        table.insert(posicoesSalvas, {
            nome = "Farm "..os.date("%H:%M:%S"),
            x = posAtual.x,
            y = posAtual.y,
            z = posAtual.z,
            delay = 500
        })

        caminharAtePosicao(posicao.x, posicao.y, posicao.z, movimentoTipo)

        local delayAtual = posicao.delay or (delayAutoFarm * 1000)
local tempoPassado = 0
local paradoPor = 0
local intervalo = 250 -- checagem a cada 250ms
local posAnterior = obterCoordenadas()

gg.toast("🎮 AUTO FARM BY: GIAN SAMP.  POSIÇÃO:" .. posicao.nome)

local tentativasTravadas = 0
local maxTravadas = 2
local delayEntreTentativas = 1500 -- 1.5s extra de espera se travar

while tempoPassado < delayAtual do
    gg.sleep(intervalo)
    tempoPassado = tempoPassado + intervalo

    local posAtual = obterCoordenadas()
    local dx = math.abs(posAtual.x - posAnterior.x)
    local dy = math.abs(posAtual.y - posAnterior.y)
    local dz = math.abs(posAtual.z - posAnterior.z)

    if dx < 0.05 and dy < 0.05 and dz < 0.05 then
        paradoPor = paradoPor + intervalo
        if paradoPor >= 1800 then
            tentativasTravadas = tentativasTravadas + 1
            gg.toast("⚠️ Parado "..tentativasTravadas.."x. Esperando antes de tentar pular...")

            if tentativasTravadas >= maxTravadas then
                gg.sleep(delayEntreTentativas)
                gg.toast("⚠️ Travado várias vezes! Indo para próxima posição...")
                goto proximaPosicao
            end

            paradoPor = 0
        end
    else
        paradoPor = 0
        tentativasTravadas = 0
    end

    posAnterior = posAtual
end

        if gg.isVisible(true) then
            gg.setVisible(false)
            local confirm = gg.alert("❓ Deseja PARAR o Auto Farm?", "Sim", "Não")
            if confirm == 1 then
                executando = false
                break
            end
        end
   ::proximaPosicao::
    end

    if executando then
        ciclos = ciclos + 1
        gg.toast("✅ Ciclo " .. ciclos .. " completo!")
        -- Alterna modo reverso se ativado
        if modoReversoAtivado then
            reverso = not reverso
        end
    end
end

    gg.toast("🛑 Auto Farm finalizado! Total de ciclos: " .. ciclos)
end

-- Função para teleporte suave
function teleportSeguroV2(x, y, z)
    local posAtual = obterCoordenadas()
    
    if #posicoesSalvas >= maxPosicoesSalvas then
        table.remove(posicoesSalvas, 1)
    end
    table.insert(posicoesSalvas, {
        nome = "Backup TP "..os.date("%H:%M:%S"),
        x = posAtual.x,
        y = posAtual.y,
        z = posAtual.z,
        delay = 5
    })

    definirCoordenadas(x, y, z)
    gg.sleep(100) -- Você pode remover essa linha se quiser INSTANTÂNEO
end

-- Função para ajustar tipo de movimento
function ajustarTipoMovimento()
    local opcoes = {
        "padrão",
        "subterrâneo",
        "aéreo",
        "invisível",
        "voltar para padrão"
    }
    
    local escolha = gg.choice(opcoes, nil, "🧩 Escolha o tipo de movimento:")
    if escolha then
        if escolha == 5 then
            movimentoTipo = "padrao"
        else
            movimentoTipo = opcoes[escolha]
        end
        gg.toast("✅ Tipo de movimento ajustado para: "..movimentoTipo.."!")
    end
end

-- Função para deletar várias posições
function deletarPosicoes()
    if #posicoesSalvas == 0 then
        gg.toast("🚫 Nenhuma posição salva para deletar!")
        return
    end
    
    local opcoes = {}
    for i, pos in ipairs(posicoesSalvas) do
        table.insert(opcoes, pos.nome .. " (X:" .. math.floor(pos.x) .. " Y:" .. math.floor(pos.y) .. ")")
    end
    
    local escolhas = gg.multiChoice(opcoes, nil, "Selecione as posições para deletar:")
    
    if escolhas then
        for i = #escolhas, 1, -1 do
            if escolhas[i] then
                table.remove(posicoesSalvas, i)
            end
        end
        salvarPosicoesNoArmazenamento()
        gg.toast("🗑️ Posições deletadas com sucesso!")
    end
end

-- Função para parar caminhada
function pararCaminhada()
    caminhando = false
    gg.toast("🛑 Caminhada interrompida!")
end

-- Função para inicializar
function inicializar()
    if not enderecoBase then
        gg.setVisible(false)
        gg.clearResults()
        
        local function buscarEndereco()
            gg.searchNumber("999.765625", gg.TYPE_FLOAT)
            local results = gg.getResults(1)
            if #results > 0 then return results[1].address end
            
            gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS)
            gg.searchNumber("999.765625", gg.TYPE_FLOAT)
            results = gg.getResults(1)
            return #results > 0 and results[1].address or nil
        end
        
        enderecoBase = buscarEndereco()
        
        if enderecoBase then
            gg.toast("✅ Base encontrada com sucesso!")
            carregarPosicoesDoArmazenamento()
            carregarPosicoesFarm()
        else
            gg.alert("❌ Falha ao encontrar endereço base!\n\nTente reiniciar o jogo.")
            os.exit()
        end
    end
end

-- Menu principal
function menuPrincipal()
    while scriptAtivo do
        if not gg.isVisible() then
            gg.sleep(100)
        else
            gg.setVisible(false)

            local opcoes = {
                "📍 Teleportar para Local",
                "🚶 Caminhar para Coordenadas",
                "🧼 Caminhar para Posição Salva",
                "⚡ Ajustar Velocidade de Carregamento",
                "⏳ Ajustar Delay do Auto Farm",
                "⚙️ Ajustar Tipo de Movimento",
                "⚙️ Configurar Subterrâneo",
                "💾 Salvar Posição",
                "📁 Carregar Posição Salva",
                "⚙️ Configurar Auto Farm",
                "AGR Auto Farm",
                "🗑️ Deletar Posição Salva",
                "🛑 Parar Caminhada",
                "⏱️ Editar Delay de Posição",
                "⚡ Configurar Velocidade TP",
                "🔃 Ativar/Desativar Modo Reverso",
                "❌ Sair"
            }
            
            local escolha = gg.choice(opcoes, nil, "GIAN SAMP - RIO RISE\nBy: GIAN HENRIQUE\nVersão: "..versao)
            
            if not escolha then 
                gg.toast("🕶️ Script minimizado")
            else
                if opcoes[escolha] == "📍 Teleportar para Local" then
                    local locais = {}
                    for nome in pairs(RIO_RISE_SPOTS) do
                        table.insert(locais, nome)
                    end
                    table.sort(locais)
                    
                    local localEscolhido = gg.choice(locais, nil, "Escolha o local:")
                    if localEscolhido then
                        local destino = RIO_RISE_SPOTS[locais[localEscolhido]]
                        teleportSeguroV2(destino.x, destino.y, destino.z)
                    end
                    
                elseif opcoes[escolha] == "🚶 Caminhar para Coordenadas" then
                    local coords = gg.prompt({
                        "Digite X:",
                        "Digite Y:",
                        "Digite Z:"
                    }, {"0.0", "0.0", "0.0"}, {"number", "number", "number"})
                    
                    if coords then
                        local destino = {
                            x = tonumber(coords[1]),
                            y = tonumber(coords[2]),
                            z = tonumber(coords[3])
                        }
                        caminharAtePosicao(destino.x, destino.y, destino.z, movimentoTipo)
                    end
                    
                elseif opcoes[escolha] == "🧼 Caminhar para Posição Salva" then
                    caminharParaPosicaoSalva()
                    
                elseif opcoes[escolha] == "⚡ Ajustar Velocidade de Carregamento" then
                    ajustarVelocidadeCarregar()
                    
                elseif opcoes[escolha] == "⏳ Ajustar Delay do Auto Farm" then
                    ajustarDelayAutoFarm()
                    
                elseif opcoes[escolha] == "⚙️ Ajustar Tipo de Movimento" then
                    ajustarTipoMovimento()
                    
                elseif opcoes[escolha] == "⚙️ Configurar Subterrâneo" then
                    configurarSubterraneo()
                    
                elseif opcoes[escolha] == "💾 Salvar Posição" then
                    salvarPosicaoAtual("Posição Atual")
                    
                elseif opcoes[escolha] == "📁 Carregar Posição Salva" then
                    carregarPosicoesDoArmazenamento()
                    
                elseif opcoes[escolha] == "⚙️ Configurar Auto Farm" then
                    salvarPosicoesFarm()
                    
                elseif opcoes[escolha] == "AGR Auto Farm" then
                    autoFarm()
                    
                elseif opcoes[escolha] == "🗑️ Deletar Posição Salva" then
                    deletarPosicoes()
                    
                elseif opcoes[escolha] == "🛑 Parar Caminhada" then
                    pararCaminhada()
                    
                elseif opcoes[escolha] == "⏱️ Editar Delay de Posição" then
                    editarDelayPosicao()
                    
                elseif opcoes[escolha] == "⚡ Configurar Velocidade TP" then
                    configurarVelocidadeTeleporte()
                    
                elseif opcoes[escolha] == "🔃 Ativar/Desativar Modo Reverso" then
               modoReversoAtivado = not modoReversoAtivado
               if modoReversoAtivado then
                    gg.toast("🔁 Modo Reverso ATIVADO!")
                  else
                    gg.toast("⛔ Modo Reverso DESATIVADO!")           
               end
                elseif opcoes[escolha] == "❌ Sair" then
                    scriptAtivo = false
                    gg.toast("👋 Script finalizado!")
                    return
                end
            end
        end
    end
end
-- Iniciar script
gg.toast("🚀 GIAN SAMP - RIO RISE\nDesenvolvido por GIAN HENRIQUE\nVersão: "..versao)
inicializar()
menuPrincipal()
