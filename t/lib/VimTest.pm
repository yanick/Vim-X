package VimTest;

use strict;
use warnings;

BEGIN {
    warn $0;
    return if $::curbuf;  # we are in vim-space

    eval <<'END' unless `vim --version` =~ /\+perl/;
    use Test::More;
    plan skip_all => "vim not found, or not compiled with perl support";
    exit;
END

    if ($^O ne 'MSWin32') {
        exec 'vim', qw/ -V -u NONE -i NONE -N -e -s /,
            '-c' => 'perl unshift @INC, "lib"',
            '-c' => 'perl unshift @INC, "t/lib"',
            '-c', "perl do '$0'",
            '-c', "qall!";
    }
    else {
        exec 'vim', qw/ -V -u NONE -i NONE -N -e -s /,
            '-c' => q{"perl unshift @INC, 'lib'"},
            '-c' => q{"perl unshift @INC, 't/lib'"},
            '-c', qq{"perl do '$0'"},
            '-c', "qall!";
    }
}

use parent 'Exporter';
use Vim::X;

our @EXPORT = ( 'in_window' );

sub in_window (&) {
    my $code = shift;
    sub {
        vim_command('new');
        eval { ::test_setup() };
        $code->();
        vim_command('close!');
    }
}


1;
