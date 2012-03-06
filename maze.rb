#!/usr/bin/env ruby
require 'rubygems'
require 'algorithms'

# Purpose: solve a maze provided in a file
# Algorithm: Uses the A* algorithm. Consider a maze as a graph where each tile in the maze is a vertex that
#            has 4 sides(edges). If there is a wall on a side the cost is infinite, if it is open the distance is
#            1. We add the heuristical cost of the shortest possible distance to finish. We color the graph until
#            we reach the finish vertex or we have no more nodes to consider(unsolvable)
#

class MazeSolver

  def initialize(filename)
    self.load_maze(filename)
    @solved = false
  end

  def load_maze(filename)
    @vertices = []
    @start = nil
    @finish = nil
    @columns = 0
    @rows = 0

    begin
      file = File.new(filename, "r")
      char_index = 0

      while (line = file.gets)
        @columns = line.size-1
        @rows += 1
        line.each_char do |c|
          if c == 's'
            raise "more than one start specified on line #{@rows}" unless @start.nil?
            @start = char_index #vertices are indexed in a flat range
          elsif c == 'f'
            raise "more than one finish specified on line #{@rows}" unless @finish.nil?
            @finish = char_index
          elsif (c != '#') and (c != ' ') and (c != "\n")
            raise "unallowed character #{c} on line #{@rows}"
          end

          @vertices << c
          char_index += 1
        end
      end

      raise "no start location" if @start.nil?
      raise "no finish location" if @finish.nil?

      file.close
    rescue Exception => e
      puts "Error: #{e.message}"
    end
  end

  # How it works: 1) consider_set is the set of all nodes we should consider in calculating the shortest path. it is
  #                  sorted based on priority(root=lowest) = distance we've traveled so far + heuristical cost to
  #                  destination (in this case the manhattan distance)
  #               2) in each step, we pop the lowest priority vertex(shortest total cost to finish)
  #               3) we visit the vertex (mark it's parent as the node we were on before to trace a path)
  #               4) we expand the vertex by adding all its accessible and yet-to-be-visited neighboring vertices
  #               5) we repeat until we get to finish
  #               6) we retrace/backtrace the path via the parents we wrote in our initial matrix white traversing
  #               7) we make sure the traversal is a connected traversal/coloring and remove any vertices we had visited
  #                  as suboptimal/locally optimal/dead-end traversals
  #               8) resulting matrix has the solution path which is the shortest path
  #
  #               when we print we print '+' instead of the parent connections in the matrix. This implementation does
  #               not use extra spaces or keep multiple heaps because it does not need to mitigate cycles

  def solve
    #walk through vertices, using modified A* algorithm to find the most direct route to finish node
    consider_set = Containers::PriorityQueue.new {|v1, v2| (v1 <=> v2) == -1}  #MinHeap. Lowest priority/total-cost at root
    distance = 0
    parent = -1
    priority = (distance + cost(@start, @finish))
    consider_set.push(@start, priority)

    while (not @solved) and (current = consider_set.pop)
      visit(current, parent)

      if (current == @finish)
        @solved = true
        break
      end

      #get all neighboring nodes we can go to sorted based on their heuristical distance from finish
      accessible_neighbors(current).each do |neighbor|
        unless visited?(neighbor)
          #add every accessible neighbor with its priority = distance so far to the node + cost/straight line to finish
          priority = (distance + cost(neighbor, @finish))
          consider_set.push(neighbor, priority)
        end
      end
      parent = current
    end
    trace_shortest_path
  end

  #we overwrite them in the algorithm for simplicity, restore them at the end
  def trace_shortest_path
    return if @vertices[@finish] == 'f' #unsolved
    parent = @vertices[@finish]
    current = @finish
    while (parent != -1)
      neighbors = accessible_neighbors(current).select{|neighbor| @vertices[neighbor].is_a? Integer}
      while (not (neighbors.include? parent))
        prev_parent = parent
        parent = @vertices[parent]
        @vertices[prev_parent] = " "
      end
      current = parent
      parent = @vertices[parent]
    end

    @vertices[@start] = 's'
    @vertices[@finish] = 'f'
  end

  def visit(vertex, parent)
    @vertices[vertex] = parent
  end

  def visited?(vertex)
    @vertices[vertex].is_a? Integer
  end

  def accessible_neighbors(vertex)
    #four possible neighbors
    [vertex-@columns-1, vertex+1, vertex+@columns+1, vertex-1].delete_if { |v| invalid_vertex(v)}
  end

  def invalid_vertex(vertex)
    (@vertices[vertex] == "#") or (vertex < 0) or (vertex > (@rows*@columns)) or (@vertices[vertex] == "\n")
  end

  def cost(from, to)
    #the shortest navigable path is the edges of a right triangle since no diagonal traversal=(to.x-from.x)+(to.y-from.y)
    ((to % @columns) - (from % @columns)).abs + ((to / @columns) - (from / @columns)).abs
  end

  def print_solution
    if @solved
      puts @vertices.map{|vertex| (vertex.is_a? Integer) ? "+" : vertex}.to_s
    else
      puts "Unsolvable puzzle" unless @solved
    end
  end
end

filename = ARGV[0]
exit if filename.nil?

maze = MazeSolver.new(filename)
maze.solve
maze.print_solution



