const std = @import("std");

const array = @import("array.zig");
const uf = @import("union_find.zig");

/// A weighted edge connecting two nodes in a graph
const Edge = struct {
    weight: usize,
    node_a: u8,
    node_b: u8,
};

/// Implementation of Kruskal's minimum spanning tree algorithm
pub fn kruskal(allocator: std.mem.Allocator, edges: []Edge, union_find: *uf.UnionFind) std.mem.Allocator.Error!*array.DynamicArray(Edge) {
    const minimum_spanning_tree_edges = try allocator.create(array.DynamicArray(Edge));
    minimum_spanning_tree_edges.* = try array.DynamicArray(Edge).new(allocator, 0);

    for (edges) |edge| {
        const node_a_rep = if (union_find.*.find(edge.node_a)) |val| val else |_| {
            // The two nodes of every edge should be in the union-find, so an `ElementNotFound`
            // error should never happen. Hence, unreachable.
            unreachable;
        };
        const node_b_rep = if (union_find.*.find(edge.node_b)) |val| val else |_| {
            // Same reasoning as for `node_a_rep` to justify the use of unreachable.
            unreachable;
        };

        if (node_a_rep == node_b_rep) {
            // Both nodes are in the same set, so they have already been "covered" by the
            // inclusion of some other edge, so do not include this edge in the spanning tree
            // and move onto the next edge
            continue;
        }

        // If execution has reached here then the two nodes are in different sets, so the edge
        // joining them can be added, and the two nodes should be unified
        if (union_find.*.unify(edge.node_a, edge.node_b)) |val| val else |_| {
            // If execution has reached this point (ie, gotten past trying to find both nodes
            // in the union-find), then both nodes must exist in the union-find, and thus
            // unifying them shouldn't return an error. Hence, unreachable.
            unreachable;
        }
        try minimum_spanning_tree_edges.*.append(allocator, edge);

        // Check if the number of sets in the union-find has reduced to one. This would imply
        // that all nodes in the graph have been "covered" by the edges that have been added to
        // the spanning tree, which would in turn mean that a minimum spanning treee has been
        // found.
        if (union_find.*.set_count == 1) break;
    }

    return minimum_spanning_tree_edges;
}

test "Kruskal's minimum spanning tree algorithm test" {
    const allocator = std.testing.allocator;
    var union_find = try uf.UnionFind.new(allocator);

    // Replicating graph in https://youtu.be/RBSGKlAvoiM?t=9362
    //
    // 10 nodes in the graph, 18 edges connecting pairs of edges in total
    //
    // Node letters are mapped to `u8` values (to be able to store them in the union-find) as
    // follows:
    // - A -> 0
    // - B -> 1
    // - C -> 2
    // - D -> 3
    // - E -> 4
    // - F -> 5
    // - G -> 6
    // - H -> 7
    // - I -> 8
    // - J -> 9
    const no_of_edges = 18;
    const nodes = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };

    // Edge information will be hardcoded, and sorted in ascending order already, to avoid
    // needing to do sorting
    const weights = [no_of_edges]usize{ 0, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 5, 5, 6, 7, 11 };
    const node_pairs = [no_of_edges]struct { u8, u8 }{
        .{ 8, 9 },
        .{ 0, 4 },
        .{ 2, 8 },
        .{ 4, 5 },
        .{ 6, 7 },
        .{ 1, 3 },
        .{ 2, 9 },
        .{ 3, 4 },
        .{ 3, 7 },
        .{ 0, 3 },
        .{ 1, 2 },
        .{ 2, 7 },
        .{ 6, 8 },
        .{ 0, 1 },
        .{ 3, 5 },
        .{ 7, 8 },
        .{ 5, 6 },
        .{ 3, 6 },
    };

    // Generate an array of edges
    var edges = std.mem.zeroes([no_of_edges]Edge);
    for (0..no_of_edges) |i| {
        edges[i] = Edge{
            .weight = weights[i],
            .node_a = node_pairs[i][0],
            .node_b = node_pairs[i][1],
        };
    }

    // Insert nodes into the union-find
    for (nodes) |node| {
        try union_find.insert(node);
    }

    // Run the algorithm on the edges to find a minimum spanning tree, and get back a slice of
    // edges that form the minimum spanning tree that was found
    const minimum_spanning_tree_edges = try kruskal(allocator, edges[0..], &union_find);

    // Setup the expected edges in the minimum spanning tree
    const no_of_expected_edges = 9;
    var expected_edges = std.mem.zeroes([no_of_expected_edges]Edge);
    expected_edges[0] = edges[0];
    expected_edges[1] = edges[1];
    expected_edges[2] = edges[2];
    expected_edges[3] = edges[3];
    expected_edges[4] = edges[4];
    expected_edges[5] = edges[5];
    expected_edges[6] = edges[7];
    expected_edges[7] = edges[8];
    expected_edges[8] = edges[10];

    // Check that the slice of edges in the minimum spanning tree is the expected length
    try std.testing.expectEqual(no_of_expected_edges, minimum_spanning_tree_edges.len);

    // Check that the edges in the minimum spanning tree are as expected
    //
    // Get slice underneath dynamic array for conveniently comparing the edges
    const minimum_spanning_tree_edges_slice = if (minimum_spanning_tree_edges.*.get_slice(0, minimum_spanning_tree_edges.len)) |val| val else |_| {
        // Using the length of the dynamic array should be valid slicing to get a slice to the
        // full data underneath the dynamic array, so an `OutOfBounds` error should never be
        // returned. Hence, unreachable.
        unreachable;
    };
    for (minimum_spanning_tree_edges_slice, expected_edges) |edge, expected_edge| {
        try std.testing.expectEqual(expected_edge.weight, edge.weight);
        try std.testing.expectEqual(expected_edge.node_a, edge.node_a);
        try std.testing.expectEqual(expected_edge.node_b, edge.node_b);
    }

    // Deallocate dynamic array containing edges in minimum spanning tree
    try minimum_spanning_tree_edges.*.free(allocator);
    allocator.destroy(minimum_spanning_tree_edges);

    // Free union-find
    try union_find.free();
}
