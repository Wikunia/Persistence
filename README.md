# Visualization

This repository visualizes the multiplicative persistence.
Inspired by this Numberphile video: [YouYube Numberphile](https://www.youtube.com/watch?v=Wim9WJeDTHQ&feature=youtu.be&fbclid=IwAR07tiGLYsmdzmFKYFJBKzdVQnYowwfR5VM9eFrJaZhTPEYalMFJvRLIog8) 

The [visualization](https://wikunia.github.io/Persistence/) shows the persistence graph for the numbers up to 100.
Color indicates the number of steps and the connection shows the next step. You can hover over a node to see the number and the path it takes.

![visual](image.png)

The code used for creating the graph can be found in: `persistence.jl` and can be called with `create_bf_list()` which creates the `graph.json`.

Some more visualizations:
This shows a histogram of the persistence of all "ascending" numbers with up to 20 digits. "ascending" means that 23 is okay but 32. For multiplicative persistence they are the same anyway.

![histo ascending](histo.png)

The following histogram was created by reducing the search space. i.e 22 is not reasonable as 4 is smaller and they are equivalent as 2*2 = 4.

![histo ascending filtered](histo_filtered.png)