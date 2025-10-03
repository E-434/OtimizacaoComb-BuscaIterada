"Peregrinação por Busca Iterada"

"Instruções para execução em Linux:
Em qualquer ambiente de terminal, chame o programa seguindo o padrão abaixo:
julia <caminho_este_programa> <caminho_arquivo_entrada> <numero_iteracoes> <seed> <numero_perturbacoes>"


using Random

function leitor(filepath :: String)
    open(filepath, "r") do f
        #Ler número de templos
        templos = parse(Int, readline(f))
        #Ler coordenadas
        coord = Vector{Vector{Int}}()
        for _ in 1:templos
            x, y = split(readline(f))
            push!(coord, [parse(Int, x), parse(Int, y)])
        end
        #Ler número de restrições
        restricoes = parse(Int, readline(f))
        #Inicializar lista de pré-requisitos
        pre_req = [Int[] for _ in 1:templos]
        #Ler cada restrição
        for _ in 1:restricoes
            a, b = split(readline(f))
            a = parse(Int, a)
            b = parse(Int, b)
            push!(pre_req[b], a)   #b depende de a
        end
        return Instancia(templos, restricoes, coord, pre_req)
    end
end

#Instância de Peregrinação
struct Instancia
    templos :: Int # Número do templo
    restricoes :: Int #Número de restrições
    # Vetor das coordenadas de cada templo (dados por uma par ordenado (x,y))
    coord :: Vector{Vector{Int}}
    # Para cada templo, um vetor com todos os seus pré-requisitos
    pre_req :: Vector{Vector{Int}}
end

#Cálculo distância cartesiana
function distancia_cartesiana(dest :: Vector{Int}, src :: Vector{Int})
    #Distância = Hipotenusa eentre os dois pontos
    dist = sqrt((src[1]-dest[1])^2+(src[2]-dest[2])^2)
    #Considera 2 casas depois da vírgula (multiplica por 100 e arredonda pra baixo)
    return floor(Int, dist*100)
end

#Calcula distância total do caminho (necessário para solução inicial)
function distancia_total(instancia :: Instancia, caminho :: Vector{Int})
    if length(caminho) <= 1
        return 0
    end
    #Inicializa distância total
    dist_total=0
    #Percorre caminho até penúltimo elemento
    for i in 1:length(caminho)-1
        #Calcula distância do templo atual para o próximo templo
        src=caminho[i]
        dst=caminho[i+1]
        dist_total+=distancia_cartesiana(instancia.coord[src], instancia.coord[dst])
    end
    #Retorna distância total
    return dist_total
end


function atualizar_distancia(solucao_inicial :: Vector{Int}, instancia::Instancia, i::Int, j::Int, distancia_antiga::Int)
    # Copia distância antiga
    distancia_nova = distancia_antiga
    # Para cada templo trocado, considerar a distância com o anterior e o próximo (se existirem)
    #se j é i+1
    # Para i
    if i > 1
        distancia_nova -= distancia_cartesiana(instancia.coord[solucao_inicial[i-1]], instancia.coord[solucao_inicial[j]])
        distancia_nova += distancia_cartesiana(instancia.coord[solucao_inicial[i-1]], instancia.coord[solucao_inicial[i]])
    end
    if i < length(solucao_inicial)
        distancia_nova -= distancia_cartesiana(instancia.coord[solucao_inicial[j]], instancia.coord[solucao_inicial[i+1]])
        distancia_nova += distancia_cartesiana(instancia.coord[solucao_inicial[i]], instancia.coord[solucao_inicial[i+1]])
    end
    # Para j
    if j > 1
        distancia_nova -= distancia_cartesiana(instancia.coord[solucao_inicial[j-1]], instancia.coord[solucao_inicial[i]])
        distancia_nova += distancia_cartesiana(instancia.coord[solucao_inicial[j-1]], instancia.coord[solucao_inicial[j]])
    end
    if j < length(solucao_inicial)
        distancia_nova -= distancia_cartesiana(instancia.coord[solucao_inicial[i]], instancia.coord[solucao_inicial[j+1]])
        distancia_nova += distancia_cartesiana(instancia.coord[solucao_inicial[j]], instancia.coord[solucao_inicial[j+1]])
    end
    # Atualiza a distância do caminho
    return distancia_nova
end

#Gera solução inicial aleatória
function solucao_inicial(instancia :: Instancia)
    #Cria vetor com os índices dos templos
    templos_livres = collect(1:instancia.templos)
    #Inicializa caminho vazio
    caminho = Int[]
    #Enquanto não tiver percorrido todos templos
    while !isempty(templos_livres)
        #Cria vetor possiveis que só armazena templos lives cujo todos pré-requisitos já estão no caminho
        possiveis = [templo for templo in templos_livres if all(pre_req -> pre_req in caminho, instancia.pre_req[templo])]
        #Escolhe algum templo possível aleatório e adiciona ao caminho
        escolhido = rand(possiveis)
        push!(caminho, escolhido)
        #Remove templo adicionado ao caminho dos templos livres
        filter!(resto -> resto != escolhido, templos_livres)
    end
    return caminho
end

#Busca local por swap de vértices
function busca_local(solucao_inicial :: Vector{Int}, distancia_inicial :: Int, instancia::Instancia)
    tamanho = length(solucao_inicial)
    solucao = copy(solucao_inicial)
    distancia = distancia_inicial
    # vetor que guarda a posição atual de cada templo
    pos = zeros(Int, tamanho)
    for idx in 1:tamanho
        pos[solucao[idx]] = idx
    end
    melhorou = true
    while melhorou
        melhorou = false
        for i in 1:tamanho-1
            vi = solucao[i]
            for j in i+1:tamanho
                vj = solucao[j]
                # Checa se vj depende de vi (se sim, todos vj não poderam trocar com vi)
                if vi in instancia.pre_req[vj]
                    break
                end
                # Checa se algum pré-requisito de vj está entre i e j
                tem_pre_req_no_meio = any(pr -> pos[pr] > i && pos[pr] < j, instancia.pre_req[vj])
                if tem_pre_req_no_meio
                    continue
                end
                # Realiza swap temporário
                solucao[i], solucao[j] = solucao[j], solucao[i]
                # Atualiza posições
                pos[vi], pos[vj] = pos[vj], pos[vi]
                # Calcula nova distância incremental
                nova_distancia = atualizar_distancia(solucao, instancia, i, j, distancia)

                if nova_distancia < distancia
                    distancia = nova_distancia
                    melhorou = true
                    break
                else
                    # Reverte swap
                    solucao[i], solucao[j] = solucao[j], solucao[i]
                    pos[vi], pos[vj] = pos[vj], pos[vi]
                end
            end
            if melhorou
                break           
            end
        end
    end
    return solucao, distancia
end

function perturbation(solucao_inicial::Vector{Int}, distancia_inicial::Int, instancia::Instancia, k::Int = 2)
    tamanho = length(solucao_inicial)
    solucao = copy(solucao_inicial)

    if k > tamanho
        error("K maior que o número de templos!")
    end

    #Seleciona aletoriamente k nodos para as recombinações
    nodosMover = randperm(tamanho)[1:k]
    elementos = solucao[nodosMover]
    #Ordena-os de forma a deleter os de maior índice primeiro
    sort!(nodosMover; rev=true)
    #Prepara as realocações deletando os nodos
    for idx in nodosMover
        deleteat!(solucao, idx)
    end

    for elemento in elementos
        #Para cada elemento iremos buscar possíveis pontos de recombinação (que respeitem os pré-requisitos)
        solucoes_possiveis = Int[]
        for pos_nova in 1:(length(solucao)+1)
            #Copia para as verificações de válidade deste elemento
            temp_sol = copy(solucao)
            insert!(temp_sol, pos_nova, elemento)

            #Busca pelo índice do elemento atual na solução
            elem_idx = findfirst(==(elemento), temp_sol)
            valid = true
            #Com ele válida se cada um de seus pré-requisitos está atrás do mesmo nesta recombinação
            for pre_req in instancia.pre_req[elemento] 
                pre_req_idx = findfirst(==(pre_req), temp_sol)
                if pre_req_idx === nothing || pre_req_idx > elem_idx
                    valid = false
                end
            end

            #Agora verifica se para todos os outros nodos que tem ele como pré-requisito não quebraram
            if valid
                for (outro_idx, outro) in enumerate(temp_sol)
                    #Se o elemento atual é um dos pré-requisitos de outro nodo e está depois dele, não é válido
                    if elemento in instancia.pre_req[outro] && elem_idx > outro_idx
                        valid = false
                        break
                    end
                end
            end

            #Se passou nos dois casos anteriores, é uma recombinação factível
            if valid
                push!(solucoes_possiveis, pos_nova)
            end
        end

        if isempty(solucoes_possiveis)
            #Se não encontrou nenhuma recombinação válida, cancela a perturbação
            return solucao_inicial, distancia_inicial
        else
            #Sorteia uma das posicções a realocar válidas deste elemento, inserindo-o lá
            pos_sorteada = rand(solucoes_possiveis)
            insert!(solucao, pos_sorteada, elemento)
        end
    end

    #Aplicadas as recombinações para todo k, calcula a nova distância
    nova_distancia = distancia_total(instancia, solucao)
    return solucao, nova_distancia
end



#Função para busca iterada
function busca_iterada(instancia::Instancia, max_iteracoes::Int, K::Int)
    # tempo inicial
    t0 = time()
    # variáveis para armazenar a primeira iteração após 5s e 300s
    iteracao_5 = nothing
    iteracao_300 = nothing
    #Inicialização dos valores
    iteracoes=0
    caminho=Int[]
    distancia=0
    #Gera caminho inicial
    melhor_caminho = solucao_inicial(instancia)
    #Calcula distância inicial
    menor_distancia = distancia_total(instancia, melhor_caminho)
    caminho=melhor_caminho
    distancia=menor_distancia
    # Imprime solução inicial 
    println("$(round(0.0,digits=2)) segundos, distancia: $menor_distancia, $(join(melhor_caminho, "->"))\n")
    #Iteração
    while iteracoes<max_iteracoes
        #Realiza busca local
        caminho, distancia = busca_local(caminho, distancia, instancia)
        #Atualiza solução se achar melhor e imprime
        if distancia < menor_distancia
            melhor_caminho=caminho; menor_distancia=distancia
            #Cálculo tempo
            elapsed = time() - t0
            println("$(round(elapsed,digits=2)) segundos, distancia: $menor_distancia, $(join(melhor_caminho, "->"))\n")
        end
        caminho, distancia = perturbation( caminho, distancia, instancia, K)      
        iteracoes+=1
        # verifica e registra a primeira iteração atingida após 5s e 300s
        elapsed = time() - t0
        if iteracao_5 === nothing && elapsed >= 5.0
            # iteracoes corresponde à iteração que acabou de completar (ou a próxima)
            iteracao_5 = iteracoes
            println("#5 segundos iteracao=$iteracao_5 elapsed=$(round(elapsed,digits=2))\n")
        end
        if iteracao_300 === nothing && elapsed >= 300.0
            iteracao_300 = iteracoes
            println("300 segundos iteracao=$iteracao_300 elapsed=$(round(elapsed,digits=2))\n")
        end
    end
    println("Tempo de execucao da busca iterada: ", round(time()-t0, digits=2))
end

#Main
function main()
    #Verifica se usuário inseriu 3 parâmetros obrigatórios
    if length(ARGS)<4
        println("Estrutura pedida: julia peregrina.jl <arquivo_entrada> <numero_iteracoes> <seed> <numero_perturbacoes>")
        return 
    end

    path = ARGS[1]
    max_iteracoes = parse(Int, ARGS[2])
    seed = parse(Int, ARGS[3])
    K = parse(Int, ARGS[4])
    if K === nothing
        K = 2 #padrão
    end

    #Usa seed para garantir mesma randomização
    Random.seed!(seed)

    #Lê instância
    instancia=leitor(path)

    #Busca iterada(sem tempo)
    busca_iterada(instancia, max_iteracoes, K)
end

main()