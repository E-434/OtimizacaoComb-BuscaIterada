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
    Random.seed!(seed)
end

main()