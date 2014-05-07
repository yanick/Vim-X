package TestsFor::Vim::X::Range;

use strict;
use warnings;

use Vim::X;

use Test::Class::Moose extends => 'VimTest';

sub test_setup {
    vim_command('new');
    vim_line(1)->content( join "\n", 'a'..'d' );
}

sub test_teardown {
    vim_command('close!');
}

sub test_base :Tests {
    my $range = vim_range( 2, 4 );

    is "$range" => "b\nc\nd", "right range";
    $range->replace( 'w', 'x', 'y', 'z' );

    is "$range" => "w\nx\ny\nz", "replace";
}

sub test_on_object :Tests {
    my $range = vim_range( vim_line(2), vim_line(4) );

    is "$range" => "b\nc\nd", "right range";
}

sub ff_and_rewind :Tests {
    my $range = vim_range( 3 );

    is $range->from_rewind( qr/b/ ) => 2, "from_rewind";
    is $range->from_ff( sub { $_->index == 3 } ) => 3, "from_ff";
    is $range->to_ff( qr/d/ ) => 4, 'to_ff';
    is $range->to_rewind( qr/a/ ) => undef, 'rewind beyond the from line';
    is $range->to_rewind( qr/c/ ) => 3, 'rewind to';
}

1;
