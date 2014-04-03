package VimTest;

use strict;
use warnings;

use base 'Test::Class::Moose';

INIT {
    Test::Class::Moose->new->runtests if $::curbuf;

    exec 'vim', qw/ -V -u NONE -i NONE -N -e -s /,
        '-c' => 'perl push @INC, "lib"', 
        '-c' => 'perl push @INC, "t/lib"', 
        '-c', "perl do '$0' or die \$@",
        '-c', "qall!";
}

1;
