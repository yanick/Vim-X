package Vim::X::Range;
# ABSTRACT: A range of lines in a Vim buffer

use Moo;

use overload 
    '@{}' => sub {
        my $self = shift;
        return $self->lines;
    },
    '""' => sub {
        my $self = shift;
        return join "\n", $self->lines;
    };

=attr from

The first line of the range.

=cut

=attr to

The last line of the range. If not given, defaults to the same
line as 'from'.

=cut

has [ qw/ from to / ] => (
    is => 'rw',
    required => 1,
);



has "_buffer" => (
    is => 'ro',
    required => 1,
);

sub lines {
    my $self = shift;
    return $self->_buffer->lines( $self->from..$self->to );
}

=func replace( @new_lines ) 

Replaces the lines in the range with the provided new lines.
If the new number of lines differs from the old one, the
C<to> value of the object will be updated in consequence.

Returns itself.

=cut

sub replace {
    my $self = shift;

    # strinfigy if needed
    my @new =  map { split "\n", "$_" } @_;


    $self->_buffer->delete( ($self->from+1)..$self->to );

    $self->to( $self->from + @new -1 );

    $self->_buffer->line($self->from)->content( @new );

    return $self;
}


1;

=head1 DESCRIPTION

Represents a range of lines in a buffer. Note that, just like
for L<Vim::X::Line>, the object stores the indexes of the range,
so if the buffer after the object creation, it'll likely not 
operate on the expected lines. Caveat emptor and all that.

=cut

1;
