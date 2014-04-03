package TestsFor::Vim::X;

use strict;
use warnings;

use Vim::X;

use VimTest;

sub test_setup {
    vim_command('new');
}

sub test_teardown {
    vim_command('close!');
}

sub test_vim_window :Tests {
    my $window = vim_window;

    isa_ok $window => 'Vim::X::Window', "get the right object";
}

sub test_vim_cursor :Tests {
    my $x = vim_cursor();

    isa_ok $x => 'Vim::X::Line', 'scalar invocation gives a line';

    is_deeply [ vim_cursor ] => [1,0], 'list context gives coordinates';
}

sub test_vim_append :Tests {
    
    vim_append( 'a'..'c' );

    is join( '!', vim_lines() ) => '!a!b!c', "append";

    vim_command( 'normal 3G' );
    vim_append( 'z' );
    is join( '!', vim_lines() ) => '!a!b!z!c', "append after line 2";

    vim_append( "foo\nbar" );
    is join( '!', vim_lines() ) => '!a!b!foo!bar!z!c', "split on CRs";

};

sub test_vim_buffer :Tests {
    isa_ok vim_buffer() => 'Vim::X::Buffer';
}

sub test_vim_lines :Tests {
    vim_append( 'a'..'d' );
    is join( '', vim_lines ) => 'abcd', 'all lines';
    is join( '', vim_lines( 3,4 ) ) => 'bc', 'subset';
}

sub test_vim_line :Tests {
    vim_append( 'a'..'d' );
    is vim_line() => '', 'cursor, so first line';
    is vim_line(3) => 'b', 'line 3';
}

1;
