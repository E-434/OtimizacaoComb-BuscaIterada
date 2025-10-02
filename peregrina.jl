"Peregrinação por Busca Iterada"

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
    #Considera 2 casas depois da vírgual (multiplica por 100 e arredonda pra baixo)
    return floor(Int, dist*100)
end

#Calcula distância total do caminho (necessário para solução inicial)
function distancia_total(instancia :: Instancia, caminho :: Vector{Int})
    #Inicializa distância total
    dist_total=0
    #Percorre caminho até penúltimo elemento
    for i in 1:(instancia.templos-1)
        #Calcula distância do templo atual para o próximo templo
        src=caminho[i]
        dst=caminho[i+1]
        dist_total+=distancia_cartesiana(instancia.coord[src], instancia.coord[dst])
    end
    #Retorna distância total
    return dist_total
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
        push!(caminho,escolhido)
        #Remove templo adicionado ao caminho dos templos livres
        filter!(resto -> resto != escolhido, templos_livres)
    end
    return caminho
end

#Função para busca iterada
function busca_iterada(instancia :: Instancia, max_iteracoes)
#Inicialização dos valores
iteracoes=0
melhor_caminho=Int[]
menor_distancia=typemax(Int)
#Gera caminho inicial
caminho = solucao_inicial(instancia)
#Calcula distância inicial
distancia = distancia_total(instancia,caminho)
#Imprime solução inicial (teste)
println("Caminho: ",join(caminho, " "), "\nDistancia: ", distancia)
end

#Main
function main()
    #Verifica se usuário inseriu 3 parâmetros obrigatórios
    if length(ARGS)<3
        println("Estrutura pedida: julia peregrina.jl <arquivo_entrada> <numero_iteracoes> <seed>")
        return 
    end
    #Salva parâmetros do usuário
    path = ARGS[1]
    max_iteracoes = parse(Int, ARGS[2])
    seed = parse(Int, ARGS[3])
    #Usa seed para garantir mesma randomização
    Random.seed!(seed)
    #Lê instância
    instancia=leitor(path)
    #Busca iterada(sem tempo)
    busca_iterada(instancia,100)
end

main()