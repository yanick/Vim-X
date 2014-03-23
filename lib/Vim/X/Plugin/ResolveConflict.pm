package Vim::X::Plugin::ResolveConflict;

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
