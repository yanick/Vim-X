package TestsFor::Vim::X::_synopsis;

use strict;
use warnings;

use Vim::X;

use Test::Class::Moose;

sub test_setup {
    vim_command('new');
}

sub test_teardown {
    vim_command('close!');
}

our $last_msg;
sub MostUsedVariable :Vim {
    my %var;

    for my $line ( vim_lines ) {
        $var{$1}++ while $line =~ /[$@%](\S+)/g;
    }

    my ( $most_used ) = reverse sort { $var{$a} <=> $var{$b} } keys %var;

    vim_msg $last_msg = "variable name $most_used used $var{$most_used} times";
}

sub test_synopsis :Tests {
    vim_cursor->append( "\$foo\n\$bar \$foo\n\$foo" );

    is join( '', vim_lines ) => '';

    vim_command( 'call MostUsedVariable()' );

    is $last_msg => '';
}

1;
