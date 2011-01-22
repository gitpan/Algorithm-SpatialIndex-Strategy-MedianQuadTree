package Algorithm::SpatialIndex::Strategy::MedianQuadTree;
use 5.008008;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

use Algorithm::SpatialIndex::Strategy::QuadTree qw(:all);
use parent 'Algorithm::SpatialIndex::Strategy::QuadTree';

use Statistics::CaseResampling qw(median);

sub _node_split_coords {
  my ($self, $node, $bucket, $coords) = @_;
  my $items = $bucket->items;
  if (@$items == 0) {
    # degrade to a quad tree
    return $self->SUPER::_node_split_coords($node, $bucket, $coords);
  }

  my $xmedian = median([map $_->[XI()], @$items]);
  my $ymedian = median([map $_->[YI()], @$items]);

  return($xmedian, $ymedian);
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Strategy::MedianQuadTree - QuadTree splitting on bucket medians

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'MedianQuadTree',
  );

=head1 DESCRIPTION

A modified quad tree implementation that I'll call Median Quad Tree (MQT) in this document.
(Not sure if this data structure has a different name elsewhere.) See C<ALGORITHM>
below.

For a description of the public interface, see L<Algorithm::SpatialIndex>. This
spatial index strategy uses the default C<Algorithm::SpatialIndex::Strategy::QuadTree>
as a base class and gets away with containing very little code because of that.
This also means that most of the interface and behaviour is inherited.

=head1 ALGORITHM

For a basic discussion of quad trees, take a look at the documentation of the
L<Algorithm::QuadTree> module or look it up on Wikipedia. The following describes
how the MQT differs from a normal quad tree and some implementation details.

Any x/y coordinate pair can be used to divide a rectangular area into four sub-rectangles.
When splitting up a node of an ordinary quad tree, the center of the quad tree is
chosen to split the node into four sub-nodes. This can be done either when the tree is
created (before it is populated) with a static depth of the tree, or dynamically whenever
the number of items associated with a node becomes too large.

For the MQT, the point which splits a given node into four is chosen to be the median
of all contained item coordinates in each dimension.

This has several consequences:

=over 2

=item *

Due to the dynamic nature of the coordinate choice when splitting a node in four,
the MQT cannot be of a fixed depth and preallocated. It needs to grow dynamically as it is
filled.

=item *

When the data in the tree is a reasonably general sample of the underlying distribution
of data, then this algorithm will create a tree of evenly filled buckets, but not
necessarily a well balanced tree. To obtain a reasonable sample of the underlying data
distribution, it is prudent to insert items in random order.

=item *

Due to this behaviour, the tree will create very small nodes/bins where the most data is
concentrated and bins of gradually increasing size as one moves away from the highest
concentrations. A normal quad tree will have a similar behaviour, but due to the
fixed size of the bins, will "converge" much more slowly.

=item *

If the data is inserted in order of the item coordinates, an ordinary quad tree is
a more efficient.
The MQT will make bad choices as the median of a contiguous subset of the ordered
data will not reflect the overall distribution and the property of having fairly
evenly filled buckets vanishes.

=item *

It is likely that polling a spatial index using an MQT is faster than an ordinary quad
tree if the distribution of data is very different from uniformity. If in doubt,
benchmark.

=item *

If the data is uniform but inserted in random order, the MQT will at best be
equal in performance to a quad tree.

=item *

Filling a dynamically growing MQT has slightly more overhead than filling a dynamically
growing quad tree due to the median calculation, but it is neither algorithmically
slower nor necessarily slower in practice. Algorithmically, splitting a
quad tree node will be O(n) in the bucket size. Splitting an MQT node will be
O(n*log(n)) if a naive median calculation is used or also O(n) with a linear-time
median calculation (like this implementation).

If the MQT is filled in random
order and the data is not uniformly distributed, it will, on average, have more
evenly filled buckets and thus less nodes than a quad tree, thus reducing the
amount of tree walking required while filling and later polling the index.

=back

=head1 SEE ALSO

L<Algorithm::SpatialIndex>

L<Algorithm::SpatialIndex::Strategy::QuadTree>

L<Algorithm::SpatialIndex::Strategy>

L<Algorithm::QuadTree>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
