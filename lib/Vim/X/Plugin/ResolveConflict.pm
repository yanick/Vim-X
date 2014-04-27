package Vim::X::Plugin::ResolveConflict;
BEGIN {
  $Vim::X::Plugin::ResolveConflict::AUTHORITY = 'cpan:YANICK';
}
$Vim::X::Plugin::ResolveConflict::VERSION = '0.3.0';
use strict;
use warnings;

use Vim::X;

sub ResolveConflict :Vim(args) {
        my $side = shift;

        my $here = vim_cursor;
        my $mine  = $here->clone->rewind(qr/^<{7}/);
        my $midway = $mine->clone->ff( qr/^={7}/ );
        my $theirs = $midway->clone->ff( qr/^>{7}/ );

        $here = $side eq 'here'   ? $here
              : $side eq 'mine'   ? $mine
              : $side eq 'theirs' ? $theirs
              : $side eq 'both'   ? $midway
              : die "side '$side' is invalid"
              ;

        vim_delete( 
                # delete the marker
            $mine, $midway, $theirs, 
                # and whichever side we're not on
            ( $midway..$theirs ) x ($here < $midway), 
            ( $mine..$midway )   x ($here > $midway),
        );

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Vim::X::Plugin::ResolveConflict

=head1 VERSION

version 0.3.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
