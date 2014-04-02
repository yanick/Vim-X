package TestsFor::Vim::X::Line;

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

sub test_overloading :Tests {
    vim_append( 'a'..'d' );
    my $line = vim_line(3);

    is join( '', vim_lines ), 'abcd', "document";

    is $line->content => 'b', 'content';
    is "$line" => 'b', 'stringification';
    is 0+$line => 3, 'numification';
}

sub test_attributes :Tests {
    vim_append('a'..'d');
    my $line = vim_line(3);

    is $line->index => 3, 'index';
    is $line->content => 'b', 'content';
    isa_ok $line->buffer => 'Vim::X::Buffer', 'buffer';
}

sub test_clone :Tests {
    vim_append('a'..'d');
    my $line = vim_line(3);

    my $clone = $line->clone;
    is $line->index => 3, 'index';
    is $line->content => 'b', 'content';
    isa_ok $line->buffer => 'Vim::X::Buffer', 'buffer';
}

sub test_content :Tests {
    vim_append('a'..'d');
    my $line = vim_line(3);

    $line->content('x');
    is "$line" => 'x', 'new content';
    is join( '', vim_lines ), 'axcd';

}

sub test_append :Tests {
    vim_append('a'..'d');
    my $line = vim_line(3);

    $line->append('x', 'y');
    is "$line" => 'b', 'still same content';
    is join( '', vim_lines ), 'abxycd';

}

sub test_search :Tests {
    vim_append('a'..'d');
    my $line = vim_line(3);

    $line->dec;
    is "$line" => 'a';
    ok $line->dec, "going to line 1";
    ok !$line->dec, "can't go further";

    ok $line->inc, 'up to line 2';
    is "$line" => 'a', 'line #2';

    ok $line->ff( qr/d/ );
    is 0+$line, 5;
    ok !$line->inc;

    ok $line->rewind( sub { $_[0]->index == 2 } );
    is 0+$line, 2;

    ok !$line->ff(sub { 0 } );
}


__PACKAGE__->new->runtests;

1;
