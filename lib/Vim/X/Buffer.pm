package Vim::X::Buffer;
BEGIN {
  $Vim::X::Buffer::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: A buffer in Vim
$Vim::X::Buffer::VERSION = '0.3.0';
use Moo;

has "index" => (
    is => 'ro',
    required => 1,
);

has "_buffer" => (
    is => 'ro',
    required => 1,
);


sub lines_content {
    my( $self, @lines ) = @_;
    @lines = map { $self->_buffer->Get($_) } @lines;
    return wantarray ? @lines : join "\n", @lines;
}


sub append {
    my( $self, $index, @lines ) = @_;
    $self->_buffer->Append( $index, map { split "\n" } @lines );
}


sub delete {
    my ( $self, @lines ) = @_;
    my %seen;
    @lines = sort { $a <=> $b } grep { !$seen{$_}++ } map { 0+$_ } @lines;

    for my $r ( reverse @lines ) {
        $self->_buffer->Delete( $r );
    }
}


sub line {
    my ( $self, $nbr ) = @_;

    return Vim::X::Line->new( buffer => $self, index => $nbr );
}


sub set_line {
    my( $self, $i, @content ) = @_;
    $self->_buffer->Set($i => shift @content);
    $self->append( $i => @content ) if @content;
}


sub lines {
    my $self = shift;
    my @lines = @_;
    unless(@lines) {
        @lines = 1..$self->size;
    }

    @lines = map { Vim::X::Line->new( buffer => $self, index => $_ ) } @lines;
    return @lines;
}


sub size {
    my $self = shift;
    $self->_buffer->Count;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Vim::X::Buffer - A buffer in Vim

=head1 VERSION

version 0.3.0

=head1 FUNCTIONS

=head2 lines_content( @indexes )

Returns the content of the lines given by I<@indexes>. 

If invoked in scalar context, the lines will be joined together with carriage
returns.

=head2 append($index, @lines)

Appends the I<@lines> after the given I<$index>.

If the lines contain carriage returns, they will be properly
splitted.

=head2 delete( @indexes )

Deletes the provided lines.

The lines are automatically filtered for duplicates and deleted in
reverse order, so you can safely do

    vim_buffer->delete( 1..5, 5..6 );

and things will Just Work(tm).

=head2 line($index)

Returns the line as a L<Vim::X::Line> object.

=head2 set_line( $index, $content )

Sets the content of the line.

=head2 lines( @indexes )

Returns the lines given as L<Vim::X::Line> objects. If no indexes are
provided, returns all the lines of the buffer.

=head2 size()

Returns the number of lines in the buffer.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
