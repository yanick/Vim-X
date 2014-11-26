package Vim::X::Range;
BEGIN {
  $Vim::X::Range::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: A range of lines in a Vim buffer
$Vim::X::Range::VERSION = '1.0.1';
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


sub replace {
    my $self = shift;

    # strinfigy if needed
    my @new =  map { split "\n", "$_" } @_;


    $self->_buffer->delete( ($self->from+1)..$self->to );

    $self->to( $self->from + @new -1 );

    $self->_buffer->line($self->from)->content( @new );

    return $self;
}


sub from_rewind {
    my( $self, $condition ) = @_;
    my( $from ) = $self->lines;
    $from->rewind($condition) or return;
    $self->from( 0 + $from );
    return $self->from;
}

sub from_ff {
    my( $self, $condition ) = @_;
    my( $from ) = $self->lines;
    $from->ff($condition) or return;
    return if $from + 0 > $self->to;
    $self->from( 0 + $from );
    return $self->from;
}

sub to_rewind {
    my( $self, $condition ) = @_;
    my $to = ( $self->lines )[-1];
    $to->rewind($condition) or return;
    return if $to + 0 < $self->from;
    $self->to( 0 + $to );
    return $self->to;
}

sub to_ff {
    my( $self, $condition ) = @_;
    my $to = ( $self->lines )[-1];
    $to->ff($condition) or return;
    $self->to( 0 + $to );
    return $self->to;
}

1;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Vim::X::Range - A range of lines in a Vim buffer

=head1 VERSION

version 1.0.1

=head1 DESCRIPTION

Represents a range of lines in a buffer. Note that, just like
for L<Vim::X::Line>, the object stores the indexes of the range,
so if the buffer after the object creation, it'll likely not 
operate on the expected lines. Caveat emptor and all that.

=head1 ATTRIBUTES

=head2 from

The first line of the range.

=head2 to

The last line of the range. If not given, defaults to the same
line as 'from'.

=head1 FUNCTIONS

=head2 replace( @new_lines ) 

Replaces the lines in the range with the provided new lines.
If the new number of lines differs from the old one, the
C<to> value of the object will be updated in consequence.

Returns itself.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
