use strict;
use warnings;

use lib 't/lib';

use Test::More;

use VimTest;
use Vim::X;

plan tests => 1;

our $last_msg;
sub MostUsedVariable :Vim {
    my %var;

    for my $line ( vim_lines ) {
        $var{$1}++ while $line =~ /[\$@%](\S+)/g;
    }

    my ( $most_used ) = reverse sort { $var{$a} <=> $var{$b} } keys %var;

    vim_msg $last_msg = "variable name $most_used used $var{$most_used} times";
}


subtest synopsis => in_window {
    vim_line->append( "\$foo\n\$bar \$foo\n\$foo" );

    is join( '', vim_lines ) => "\$foo\$bar \$foo\$foo";

    vim_command( 'call MostUsedVariable()' );

    is $last_msg => 'variable name foo used 3 times';
};

