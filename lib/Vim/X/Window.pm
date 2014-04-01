package Vim::X::Window;

use strict;
use warnings;

use Vim::X;
use Vim::X::Buffer;
use Carp;

sub new {
    my( $class, $win ) = @_;
    croak "window index is required" unless $win;
    my $self = [ $win ];
    return bless $self, $class;
}

sub buffer {
    my $self = shift;
    return Vim::X::Buffer->new( $self->[0]->Buffer );
}

sub cursor {
    my $win = shift;
    return wantarray ? $win->[0]->Cursor 
        : Vim::X::Line->new( buffer => $win->buffer, index => ($win->[0]->Cursor)[0] );
}

1;
