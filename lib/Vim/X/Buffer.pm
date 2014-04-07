package Vim::X::Buffer;
# ABSTRACT: A buffer in Vim

use Moo;

has "index" => (
    is => 'ro',
    required => 1,
);

has "_buffer" => (
    is => 'ro',
    required => 1,
);

=func lines_content( @indexes )

Returns the content of the lines given by I<@indexes>. 

If invoked in scalar context, the lines will be joined together with carriage
returns.

=cut

sub lines_content {
    my( $self, @lines ) = @_;
    @lines = map { $self->_buffer->Get($_) } @lines;
    return wantarray ? @lines : join "\n", @lines;
}

=func append($index, @lines)

Appends the I<@lines> after the given I<$index>.

If the lines contain carriage returns, they will be properly
splitted.

=cut

sub append {
    my( $self, $index, @lines ) = @_;
    $self->_buffer->Append( $index, map { split "\n" } @lines );
}

=func delete( @indexes )

Deletes the provided lines.

The lines are automatically filtered for duplicates and deleted in
reverse order, so you can safely do

    vim_buffer->delete( 1..5, 5..6 );

and things will Just Work(tm).

=cut

sub delete {
    my ( $self, @lines ) = @_;
    my %seen;
    @lines = sort { $a <=> $b } grep { !$seen{$_}++ } map { 0+$_ } @lines;

    for my $r ( reverse @lines ) {
        $self->_buffer->Delete( $r );
    }
}

=func line($index)

Returns the line as a L<Vim::X::Line> object.

=cut

sub line {
    my ( $self, $nbr ) = @_;

    return Vim::X::Line->new( buffer => $self, index => $nbr );
}

=func set_line( $index, $content )

Sets the content of the line.

=cut

sub set_line {
    my( $self, $i, @content ) = @_;
    $self->_buffer->Set($i => shift @content);
    $self->append( $i => @content ) if @content;
}

=func lines( @indexes )

Returns the lines given as L<Vim::X::Line> objects. If no indexes are
provided, returns all the lines of the buffer.

=cut

sub lines {
    my $self = shift;
    my @lines = @_;
    unless(@lines) {
        @lines = 1..$self->size;
    }

    @lines = map { Vim::X::Line->new( buffer => $self, index => $_ ) } @lines;
    return @lines;
}

=func size()

Returns the number of lines in the buffer.

=cut

sub size {
    my $self = shift;
    $self->_buffer->Count;
}

1;


