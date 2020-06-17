# frozen_string_literal: true

module SpatialStats
  module Utils
    ##
    # KD-Tree implementation for PPA
    #
    class KDTree
      Node = Struct.new(:point, :idx, :left, :right, :axis, :split)

      def initialize(points)
        @points = points

        # add index to points so we can track it when they are in the tree.
        tmp_pts = points.each_with_index.map { |v, i| v << i }
        @root = construct(tmp_pts)
      end
      attr_reader :points, :root

      ##
      # Finds the nearest point in the tree to a given point
      #
      # @param [Array] point x,y
      #
      # @returns [Hash] {node: KDTree::Node, dmin: Float}
      def nearest_point(point)
        nearest_tuple = nearest(point, root)
        nearest_tuple[:dmin] = Math.sqrt(nearest_tuple[:dmin])

        # create a new node that removes all but point and idx
        new_node = Node.new
        new_node.point = nearest_tuple[:node].point
        new_node.idx = nearest_tuple[:node].idx
        nearest_tuple[:node] = new_node

        nearest_tuple
      end

      ##
      # Finds the k-nearest neighbors in the tree to a given point
      #
      # If k > points.size, k = points.size
      #
      # @param [Array] point x,y
      # @param [Integer] k
      #
      # @returns [Array] [{node: KDTree::Node, dmin: Float}]
      def knn(point, k)
        k = points.size if k > points.size
        neighbors = Array.new(k)
        neighbors = _knn(point, root, neighbors)

        # convert neighbors to actual distance
        # not dist2
        neighbors.map do |neighbor|
          neighbor[:dmin] = Math.sqrt(neighbor[:dmin])

          new_node = Node.new
          new_node.point = neighbor[:node].point
          new_node.idx = neighbor[:node].idx
          neighbor[:node] = new_node

          neighbor
        end
      end

      private

      def _knn(point, node, curr_neighbors)
        return curr_neighbors if node.nil?

        k = curr_neighbors.size

        # if there are still nil slots left in curr_neighbors, add this
        # else, see if it is shorter than the last neighbor
        # since curr_neighbors wil be sorted by dist once it is filled
        dist = dist2(point, node.point)
        if !curr_neighbors.index(nil).nil?
          idx = curr_neighbors.index(nil)
          curr_neighbors[idx] = { node: node, dmin: dist }

          # sort if curr_neighbors is now full
          curr_neighbors.sort_by! { |v| v[:dmin] } if idx == k - 1
        elsif dist < curr_neighbors[k - 1][:dmin]
          curr_neighbors[k - 1] = { node: node, dmin: dist }
          curr_neighbors.sort_by! { |v| v[:dmin] }
        end

        # keep working down the tree
        axis = node.axis
        first_child = nil
        other_child = nil
        if point[axis] < node.split
          first_child = node.left
          other_child = node.right
        else
          first_child = node.right
          other_child = node.left
        end

        curr_neighbors = _knn(point, first_child, curr_neighbors)

        # check if we need to evaluate other side by either
        # still having nil values in array or the hypersphere
        # from largest dmin intersects hyperplane of node
        has_nil = !curr_neighbors.index(nil).nil?
        if has_nil || (point[axis] - node.split)**2 <= curr_neighbors[k - 1][:dmin]
          curr_neighbors = _knn(point, other_child, curr_neighbors)
        end
        curr_neighbors
      end

      ##
      # Method to find the nearest neighbor of a point
      #
      # First, recurses down the tree, following the axis and splits of
      # each node. At each level it checks if its current best should be
      # replaced with the existing node.
      #
      # After reaching the leaf node, it works back up and checks
      # at each level if its hypersphere intersects the hyperplane
      # defined at that node. If it does, it traverses down that node.
      #
      # Finishes once it reaches the root node and does not need to check
      # the other side.
      def nearest(point, node, curr_best = nil)
        curr_best = { node: nil, dmin: Float::INFINITY } if curr_best.nil?
        return curr_best if node.nil?

        # Check if current node is better than what we have
        dist = dist2(point, node.point)
        curr_best = { node: node, dmin: dist } if dist < curr_best[:dmin]

        # recurse down tree
        axis = node.axis
        first_child = nil
        other_child = nil
        if point[axis] < node.split
          first_child = node.left
          other_child = node.right
        else
          first_child = node.right
          other_child = node.left
        end

        curr_best = nearest(point, first_child, curr_best)

        # check if we need to evaluate other child based on
        # hyperplane intersecting with hypersphere
        curr_best = nearest(point, other_child, curr_best) if (point[axis] - node.split)**2 <= curr_best[:dmin]
        curr_best
      end

      ##
      # Process to construct tree
      #
      # If points are empty return nil
      # If only one point in list, make a leaf node
      # Else, determine axis of hyperplane based on the depth
      # so it alternates with each level.
      # Then sort remaining points by that axis
      # Make the middle value (rounded down if even) and make that the
      # point in the node.
      # Split remaining points into left and right lists.
      # Construct trees from those lists and make them the right and left
      # children of the current node.
      def construct(pts, depth = 0)
        return nil if pts.empty?

        axis = depth % 2
        return Node.new(pts[0].slice(0..1), pts[0][2], nil, nil, axis, pts[0][axis]) if pts.size == 1

        sorted = pts.sort_by { |v| v[axis] }

        n = sorted.size
        median = n / 2
        middle = sorted[n / 2]
        left_list = sorted[0..median - 1]
        right_list = sorted[median + 1..n]

        node = Node.new
        node.point = middle.slice(0..1)
        node.idx = middle[2]
        node.axis = axis
        node.split = middle[axis]
        node.left = construct(left_list, depth + 1)
        node.right = construct(right_list, depth + 1)
        node
      end

      def dist2(p1, p2)
        (p1[0] - p2[0])**2 + (p1[1] - p2[1])**2
      end
    end
  end
end
