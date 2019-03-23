using JSON
using Plots
using PyPlot

global cache
global smallest_possible
global concat_pow
"""
    create_cache(;longest=240)

Create the cache for faster calculation. This fills the variable `cache` with a vector[1..8] (representing digits 2..9)
of a dictionary holding d^x for d: 2..9 and x up to longest. 
"""
function create_cache(;longest=240)
    global cache, next_possible, concat_pow
    cache = Vector{Dict{Int,BigInt}}()

    for d = 2:9
        cd = Dict{Int,BigInt}()
        for i = 0:longest
            cd[i] = d^convert(BigInt,i)
        end
        push!(cache, cd)
    end

    ### check for up to 10^power whether the digits are reasonable
    # i.e 22 is not reasonable as 4 is smaller same with 
    power = 7
    next_possible = zeros(Int, 10^power)
    smallest_possible_for_x = 10^power*ones(Int, 9^power) 
    l = length(smallest_possible_for_x)
    last_i = 1
    for i=1:10^power
        m = prod(digits(i))
        # if it ends in 0 => not reasonable only for step 2 
        if 0 < m <= l && m % 10 != 0
            if i < smallest_possible_for_x[m]
                smallest_possible_for_x[m] = i
                next_possible[last_i+1:i] .= i
                last_i = i
            end
        end
    end
    smallest_possible_for_x[1:9] = collect(1:9);
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

function create_histogram(;stop=10000)
    gr()
    create_cache(;longest=4)
    bins = collect(0:12) # 0-11
    arr = zeros(Int,stop+1)
    for i = 0:stop
        arr[i+1] = per_while(i) 
    end
    histogram(arr, label="Histogram", bins=bins, xticks=0:12)
end

"""
    create_list(;longest=15, shortest=0, fct=per_while)

Check all reasonable numbers between a length of shortest and longest using the function fct to calculate the persistence of a number.
Print if a number with higher persistence was found or a smaller number with the same persistence.
"""
function create_list(;longest=15, shortest=0, fct=per_while)
    global next_possible
    pyplot()
    create_cache(;longest=longest)
    best_x = 0
    best_s = 0
    n = zeros(Int, 8) # from 2 to 9
    c = parse(BigInt, "0")
    tt = 0.0
    start_time = time()
    # variable which gets checked
    x = BigInt(1)
    current_length = 1
    tail = 1
    histo = zeros(Int,13)
    while true
        x += 1
        sx = string(x)
        # keeping track of the current length of the number
        if x >= 10^convert(BigInt,current_length)
            current_length += 1
            println("current_length: ", current_length)
        end
        if sx[end] == '0'
            # if the number is 10...0 then the next reasonable one is 22...2
            if sx[1] == '1'
                x = parse(BigInt,"2"^current_length)
            else
                # check how many 0 we have in the end like 2223000 after 2222999
                # then the next reasonable is 22233333
                tail = 1
                while sx[end-tail] == '0'
                    tail += 1
                end
                front = sx[1:end-tail]
                back = front[end]
                x = parse(BigInt,front*back^tail)
            end
        end
        sx = string(x)
        if length(sx) > longest
            println("Checked all")
            break
        end
        first_digits = parse(Int,sx[1:min(length(sx),7)])
        if next_possible[first_digits] != first_digits
            # jumping to the next reasonable number
            first_digits = next_possible[first_digits]
            x = parse(BigInt, string(first_digits)*string(first_digits)[end:end]^(current_length-length(string(first_digits))))
        end
        t = time_ns()
        s = fct(x)
        tt += time_ns()-t
        histo[s+1] += 1
        if s > best_s
            best_s = s
            best_x = x
            println("Found better: ", x , " needs ", s , " steps and has a length of: ", length(string(x)))
        end
        c += 1
        if c % 10000 == 0
            println("Checked ", convert(Int,(c/10000)) , " * 10,000 numbers")
        end
    end
    println("Checked ", c , " numbers")
    println("Time needed for per_while: ", tt/10^9)
    println("Time needed in total: ", time()-start_time)
    Plots.plot(0:12, histo, linetype=:bar, xticks=0:12, yaxis=:log,
              title="Numbers with a persistence of 0-12 up $longest digits\nof filtered \"ascending\" numbers i.e no 42 and no 24 only 8 as 2*4=8",
              legend=false, size=(900,600), titlefont=font(14))
end

create_list(;longest=40)
# create_histogram()