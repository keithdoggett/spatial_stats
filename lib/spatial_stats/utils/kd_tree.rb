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

      def nearest_point(point)
        nearest_tuple = nearest(point, root)
        nearest_tuple[:dmin] = Math.sqrt(nearest_tuple[:dmin])
        nearest_tuple
      end

      private

      def nearest(point, node, curr_best = nil)
        curr_best = { point: nil, idx: nil, dmin: Float::INFINITY } if curr_best.nil?
        return curr_best if node.nil?

        # Check if current node is better than what we have
        dist = dist2(point, node.point)
        curr_best = { point: node.point, idx: node.idx, dmin: dist } if dist < curr_best[:dmin]

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
