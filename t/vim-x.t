use strict;
use warnings;

use lib 't/lib';

use Test::More;

use Path::Tiny;

use VimTest;
use Vim::X;

plan tests => 6;

isa_ok vim_window() => 'Vim::X::Window', "get the right object";

subtest test_vim_cursor => in_window {
    my $x = vim_cursor();

    isa_ok $x => 'Vim::X::Cursor';

    isa_ok $x->line => 'Vim::X::Line';

    is $x->line->index => 1;
    is $x->col => 0;

};

subtest vim_append => sub  {
    vim_append( 'a'..'c' );

    is join( '!', vim_lines() ) => '!a!b!c', "append";

    vim_command( 'normal 3G' );
    vim_append( 'z' );
    is join( '!', vim_lines() ) => '!a!b!z!c', "append after line 2";

    vim_append( "foo\nbar" );
    is join( '!', vim_lines() ) => '!a!b!foo!bar!z!c', "split on CRs";

};

subtest vim_buffer => in_window  {
    isa_ok vim_buffer() => 'Vim::X::Buffer';
};

subtest vim_lines => in_window  {
    vim_append( 'a'..'d' );
    is join( '', vim_lines ) => 'abcd', 'all lines';
    is join( '', vim_lines( 3,4 ) ) => 'bc', 'subset';
};

subtest vim_line => in_window  {
    vim_append( 'a'..'d' );
    is vim_line() => '', 'cursor, so first line';
    is vim_line(3) => 'b', 'line 3';
};

subtest vim_current_file => in_window {
    is vim_current_file() => undef, 'buffer is not saved yet';

    vim_command( "write! t/buffer" );

    like vim_current_file() => qr't/buffer$', 'file exists';
    is vim_current_file(1) => 't/buffer', 'localized';
};

