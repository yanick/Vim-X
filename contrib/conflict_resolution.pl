
use Number::Range;

my $here = vim_line;
my( $mine, $midway, $theirs );
my $mine = $here->rewind( qr/^<{7}/ ) or die "not in a conflict\n";
my $midway = $mine->ff( qr/^={7}/ )   or die "not in a conflict\n";
my $theirs = $midway->ff( qr/^>{7}/ )  or die "not in a conflict\n";

$theirs = ( 
    $midway = ( 
        $mine = (
            $here = vim_line
        )->rewind( qr/^<{7}/ ) 
    )->ff( qr/^={7}/ ) 
)->ff( qr/^>{7}/ );

vim_delete( 
        # delete the marker
    $mine, $midway, $their, 
        # and whichever side we're not on
    ( $midway..$theirs ) x ($here < $midway), 
    ( $mine..$midway )   x ($here > $midway),
);

sub vim_delete {
    my $range = Number::Range->new( @_ );
    for my $r ( reverse split ',', $range->range ) {
        $x->Delete( split '\.\.', $r );
    }

}
