package VimTest;

use strict;
use warnings;

use File::Which;

INIT {
    my $test = __PACKAGE__->new;

    my ( $class ) = $test->test_classes;

    return unless $class;

    if ( $main::curbuf ) {
        $test->runtests;
    }
    else {
        system 'vim', qw/ -V -u NONE -i NONE -N -e -s /,
            '-c' => 'perl push @INC, "lib"', 
            '-c' => 'perl push @INC, "t/lib"', 
            '-c', "perl use $class;",
            '-c', 'qall!';
    }

}

use Test::Class::Moose;

around test_classes => sub {
    my( $inner, $self ) = @_;
    return grep { !/(?:VimTest|main)/ } $inner->($self);
};

sub test_startup {
    my $self = shift;

    my ( $vim ) = which('vim') or $self->test_skip( 'vim not found' );

    $self->test_skip( 'vim not compiled with perl') 
        unless `$vim --version` =~ /\+perl/;
}


1;
