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
        @head = construct(tmp_pts)
      end
      attr_reader :points, :head

      private

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

        return Node.new(pts[0].slice(0..1), pts[0][2]) if pts.size == 1

        axis = depth % 2
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
    end
  end
end
