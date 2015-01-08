use strict;
use warnings;

use lib 't/lib';

use Test::More;

use VimTest;
use Vim::X;

plan tests => 3;

sub test_setup {
    vim_line(1)->content( join "\n", 'a'..'d' );
}

subtest test_base => in_window  {
    my $range = vim_range( 2, 4 );

    is "$range" => "b\nc\nd", "right range";
    $range->replace( 'w', 'x', 'y', 'z' );

    is "$range" => "w\nx\ny\nz", "replace";
};

subtest test_on_object => in_window  {
    my $range = vim_range( vim_line(2), vim_line(4) );

    is "$range" => "b\nc\nd", "right range";
};

subtest ff_and_rewind => in_window  {
    my $range = vim_range( 3 );

    is $range->from_rewind( qr/b/ ) => 2, "from_rewind";
    is $range->from_ff( sub { $_->index == 3 } ) => 3, "from_ff";
    is $range->to_ff( qr/d/ ) => 4, 'to_ff';
    is $range->to_rewind( qr/a/ ) => undef, 'rewind beyond the from line';
    is $range->to_rewind( qr/c/ ) => 3, 'rewind to';
};

