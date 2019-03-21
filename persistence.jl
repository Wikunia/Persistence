using JSON

global cache
"""
    create_cache(;longest=240)

Create the cache for faster calculation. This fills the variable `cache` with a vector[1..8] (representing digits 2..9)
of a dictionary holding d^x for d: 2..9 and x up to longest. 
"""
function create_cache(;longest=240)
    global cache 
    cache = Vector{Dict{Int,BigInt}}()

    for d = 2:9
        cd = Dict{Int,BigInt}()
        for i = 0:longest
            cd[i] = d^convert(BigInt,i)
        end
        push!(cache, cd)
    end
end

"""
    per(x; steps=0)

Recursive way of calculating the persistence. 
Return the number of steps 
"""
function per(x; steps=0)
    while x >= 10
        return per(prod(convert.(BigInt,digits(x))); steps=steps+1)
    end
    return steps
end

"""
    per_while(x)

while way of calculating the persistence by using the cache. Fastest for large numbers.
Return the number of steps 
"""
function per_while(x)
    steps = 0
    n = zeros(Int, 8) # from 2 to 9
    while x >= 10
        list = digits(x)
        for l in list
            if l == 0
                return steps+1
            end
            if l > 1
                n[l-1] += 1
            end
        end
        x = prod_arr(n)
        n[1:8] .= 0
        steps += 1
    end
    return steps
end

"""
    per_while_arr(x)

while way of calculating the persistence by using the cache. Fastest for large numbers.
Return the steps. i.e x=3279 -> [378,168,48,32,6]
"""
function per_while_arr(x)
    steps = 0
    arr = Vector{Int}()
    n = zeros(Int, 8) # from 2 to 9
    while x >= 10
        list = digits(x)
        for l in list
            if l == 0
                push!(arr,0)
                return arr
            end
            if l > 1
                n[l-1] += 1
            end
        end
        x = prod_arr(n)
        push!(arr,x)
        n[1:8] .= 0
        steps += 1
    end
    return arr
end

"""
    prod_arr(a::Vector{Int})

Use the array representation of a number to calculate the product of its digits. 
It uses the global cache
Return the product i.e x=2379 => array respresentation [1,1,0,0,0,1,0,1] -> 378
"""
function prod_arr(a::Vector{Int})
    global cache
    n = ones(BigInt, 8)
    for i=2:9
        n[i-1] = cache[i-1][a[i-1]]
    end
    return prod(n)
end

"""
    per_while_simple(x)

While way of calculating the persistence without using the cache. Works with big numbers.
Return the number of steps 
"""
function per_while_simple(x)
    steps = 0
    while x >= 10
        x = prod(convert.(BigInt,digits(x)))
        steps += 1
    end
    return steps
end

"""
    per_while_simple(x)

While way of calculating the persistence without using the cache. Doesn't work with big numbers but faster with small numbers.
Return the number of steps 
"""
function per_while_simple_small(x)
    steps = 0
    while x >= 10
        x = prod(digits(x)) 
        steps += 1
    end
    return steps
end

"""
    per_while_print(x)

Print the steps using per_while works without cache and big numbers
"""
function per_while_print(x)
    steps = 0
    println(x)
    while x >= 10
        x = prod(convert.(BigInt,digits(x)))
        println(x)
        steps += 1
    end
    return steps
end

"""
    arr2x(a::Vector{Int})

Return the number which is represented by the array representation
"""
function arr2x(a::Vector{Int})
    str = ""
    for i in 2:9
        str *= repeat(string(i), a[i-1])
    end
    return parse(BigInt, str)
end

mutable struct Node
    name        :: String
    id          :: Int
    group       :: Int

    Node(name,id,group) = new(name,id,group)
end

mutable struct Link
    source      :: Int
    target      :: Int
    value       :: Int

    Link(source,target,value) = new(source,target,value)
end

mutable struct Graph
    nodes       :: Vector{Node}
    links       :: Vector{Link}

    Graph() = new()
end

"""
    arr2json(a)

Return a graph of a vector of per_while_arr calls
"""
function arr2json(a)
    G = Graph()
    G.nodes = Vector{Node}()
    G.links = Vector{Link}()
    c = 0
    for x in a 
        name = string(c)*": "*join(x,",")
        if length(x) == 0
            name = string(c)
        end
        push!(G.nodes, Node(name,c,length(x)))
        if length(x) >= 1
            push!(G.links, Link(c,x[1],0))
        end
        c += 1
    end
    return G
end

"""
    create_bf_list(;stop=100)

Writes a graph representation of all (bruteforce = bf) numbers from 0 to stop to graph.json
"""
function create_bf_list(;stop=100)
    result_arr = fill(Vector{Int}(),stop+1)
    for i = 0:stop
        result_arr[i+1] = per_while_arr(i) 
    end
    write("graph.json", JSON.json(arr2json(result_arr)))
end

"""
    create_list(;longest=15, shortest=0, fct=per_while)

Check all reasonable numbers between a length of shortest and longest using the function fct to calculate the persistence of a number.
Print if a number with higher persistence was found or a smaller number with the same persistence.
"""
function create_list(;longest=15, shortest=0, fct=per_while)
    create_cache(;longest=longest)
    best_x = 0
    best_s = 0
    n = zeros(Int, 8) # from 2 to 9
    n[8] = shortest
    c = parse(BigInt, "0")
    tt = 0.0
    start_time = time()
    while true
        for d in 8:-1:3
            if n[d] < longest-(sum(n)-n[d])
                n[d] += 1
                break
            end 
            n[d:8] .= 0
        end
        if all(i -> i == 0, n[3:8])
            if n[2] == 0
                n[2] = 1
            elseif n[1] == 0
                n[1] = 1
                n[2] = 0
            else
                println("Checked all")
                break
            end
        end
        if sum(n) <= shortest
            continue
        end
        if n[1]+n[3] < 2
            x = arr2x(n)
            t = time_ns()
            s = fct(x)
            tt += time_ns()-t
            if s > best_s || (s == best_s && x < best_x)
                best_s = s
                best_x = x
                println("Found better: ", x , " needs ", s , " steps and has a length of: ", length(string(x)))
            end
            c += 1
            if c % 10000 == 0
                println("Checked ", convert(Int,(c/10000)) , " * 10,000 numbers")
            end
        end
        
    end
    println("Checked ", c , " numbers")
    println("Time needed for per_while: ", tt/10^9)
    println("Time needed in total: ", time()-start_time)
end