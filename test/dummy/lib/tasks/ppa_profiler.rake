# frozen_string_literal: true

namespace :ppa_profiler do
  desc 'Test KNN Search on a random set of points in KD Tree'
  task kd_knn_correctness: :environment do
    dist2 = proc { |p1, p2| (p1[0] - p2[0])**2 + (p1[1] - p2[1])**2 }
    rand_pts = 1000.times.map do
      [rand(-10.0..10.0), rand(-10.0..10.0)]
    end
    kd = SpatialStats::Utils::KDTree.new(rand_pts)

    1000.times do
      pt = [rand(-10.0..10.0), rand(-10.0..10.0)]
      nn = kd.knn(pt, 3)
      sorted = rand_pts.sort_by { |v| dist2.call(pt, v) }

      nn.each_with_index do |v, i|
        next unless [v[:node].point[0], v[:node].point[1]] != [sorted[i][0], sorted[i][1]]

        p 'Error'
      end
    end
  end

  desc 'benchmark KNN'
  task benchmark_knn: :environment do
    dist2 = proc { |p1, p2| (p1[0] - p2[0])**2 + (p1[1] - p2[1])**2 }
    rand_pts = 10_000.times.map do
      [rand(-10.0..10.0), rand(-10.0..10.0)]
    end

    kd = SpatialStats::Utils::KDTree.new(rand_pts)

    k = 3
    n = 10_000
    Benchmark.bm do |x|
      x.report('sort_by') do
        n.times do
          pt = [rand(-10.0..10.0), rand(-10.0..10.0)]
          sorted = rand_pts.sort_by { |v| dist2.call(pt, v) }
          sorted.slice(0..k - 1)
        end
      end

      x.report('kd') do
        n.times do
          pt = [rand(-10.0..10.0), rand(-10.0..10.0)]
          kd.knn(pt, k)
        end
      end
    end
  end
end
