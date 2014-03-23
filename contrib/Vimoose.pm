package Vimoose;

use strict;
use warnings;

use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    as_is     => [ 'vim' ],
);

unless ( $::curbuf ) {
    package VIM;
    no strict;
    sub AUTOLOAD {
        warn "calling $AUTOLOAD";
    }
}

sub vim {
    my( $name, $sub, %args ) = @_;

    no strict 'refs';
    *{"::$name"} = $sub;
    VIM::DoCommand(<<END);
command $name perl $name()
END
    

};


1;
