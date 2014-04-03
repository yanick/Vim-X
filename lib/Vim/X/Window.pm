package Vim::X::Window;
# ABSTRACT: A window in Vim

use strict;
use warnings;

use Vim::X;
use Vim::X::Buffer;
use Carp;

use Moo;

has _window => (
    is => 'ro',
    required => 1,
);

=func buffer() 

Returns the buffer associated with the window as a .L<Vim::X::Buffer> object 

=cut

sub buffer {
    my $self = shift;
    return Vim::X::Buffer->new( _buffer => $self->_window->Buffer, index =>
        0 );
}

=func cursor() 

Returns the cursor position in the window. 
In list context, returns the I<(line,colum)> coordinates. In scalar
context, the line as a L<Vim::X::Line> object.

=cut

sub cursor {
    my $win = shift;
    my @cursor = $win->_window->Cursor;
    return wantarray ? @cursor
        : Vim::X::Line->new( buffer => $win->buffer, index => $cursor[0] );
}

1;


