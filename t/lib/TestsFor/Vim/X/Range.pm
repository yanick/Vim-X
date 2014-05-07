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

1;
