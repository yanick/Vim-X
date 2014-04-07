package Vim::X::Line;
# ABSTRACT: A line in a Vim buffer

use Moo;

=description

=head2 BIG HUGE WARNING

When created, the line objects store the buffer and index of the line they
correspond to, so they are more like cursors than representations of the actual lines. 
If lines are added or deleted in the buffer, the object 
B<will not be updated> in consequence. For example, this won't do what you think:

    vim_append( '1 meh', '2 meh', '3 meh' );

    for my $line ( vim_lines ) {
        $line->delete if "$line" =~ /meh/;
    }

    vim_msg join ' ', vim_lines;   # prints '2 meh'

That's because the original line #2 become line #1 after the first
delete. For things to work correctly, you can process the lines in
reverse order:

    vim_append( '1 meh', '2 meh', '3 meh' );

    for my $line ( reverse vim_lines ) {
        $line->delete if "$line" =~ /meh/;
    }

    vim_msg join ' ', vim_lines;   # prints nothing!


=head1 OVERLOADING

The line object, when used as a string, will yield its content. And if used 
in a numerical context, it'll returns its line number.

As an additional piece of sugar is the overloading of '<<=', which sets the content of the
line.

    $line <<= "$line" =~ s/foo/bar/rg;

    # equivalent to

    $line->content(  $line->content =~ s/foo/bar/rg );

=cut 

use overload
    '""' => sub { $_[0]->content },
    'eq' => sub { $_[0]->content eq $_[1] },
    '<<=' => sub { $_[0]->content( $_[1] ) },
    '0+' => sub { return $_[0]->index },
    '+' => sub { return $_[0]->index + $_[1] },
    '<=>' => sub { 
            return  $_[0]->index <=>  (ref $_[1] ? $_[1]->index : $_[1])
        },
    ;


=attribute buffer

The L<Vim::X::Buffer> the line belongs to. Read-only.

=cut

has buffer => (
    is => 'ro',
    required => 1,
);

=attribute index($i)

Sets or gets the line number of the object.

=cut

has 'index' => (
    is => 'rw',
    required => 1,
);

=method new( buffer => $buffer, index => $i )

Creates a new L<Vim::X::Buffer> object. Both I<buffer> and I<index> 
arguments are required.

=method clone

Makes a copy of the object.

=cut

sub clone {
    my $self = shift;
    return Vim::X::Line->new( buffer => $self->buffer, index => $self->index );
}

=method content( $new_content )

Sets the content of the line to ne I<$new_content> or, if I<$new_content> is not given, returns
the current content.

=cut

sub content { 
    my $self = shift;
    $self->buffer->set_line( $self->index, map { split "\n" } @_ ) if @_;
    return $self->buffer->lines_content( $self->index );
} 

=method append( @lines )

Append the I<@lines> after the current line. 

Carriage returns in lines will cause them to be splitted.

=cut

sub append {
    my( $self, @lines ) = @_;
    $self->buffer->append( $self->index, @lines );
}

=method dec()

Makes the object point to the previous line. Returns the object or
C<undef>
if at the beginning of the buffer and can't backtrack anymore.

=cut


sub dec {
    my $self = shift;

    return if $self->index == 1;

    $self->index( $self->index - 1 );
    return $self;
}

=method inc()

Makes the object point to the next line. Returns the object or,
C<undef>
if at the end of the buffer and can't advance anymore.

=cut

sub inc {
    my $self = shift;

    return if $self->index == $self->buffer->size;

    $self->index( $self->index + 1 );
    return $self;
}

sub _search {
    my( $self, $direction, $condition ) = @_;

    my $target = $self->clone;

    my $it = $direction > 0 ? sub { $target->inc } : sub { $target->dec };

    my $cond = $condition;
    $cond = sub { $_[0]->content =~ $condition }  if ref $condition eq 'Regexp';

    $it->() or return until $cond->($target);

    $self->index( $target->index );
    return $self;
}

=method rewind( $condition )

Move back in the buffer until I<$condition> is met.

The condition can be a regular expression, or a coderef that will 
return C<true> on success. If the condition is not met, the method returns C<false>
and the line index of the object is not modified.

=cut

sub rewind {
    my( $self, $condition ) = @_;

    return $self->_search(-1,$condition);
}

=method ff( $condition )

Move forward in the buffer until I<$condition> is met.

The condition can be a regular expression, or a coderef that will 
return C<true> on success. If the condition is not met, the method returns C<false>
and the line index of the object is not modified.

=cut


sub ff {
    my( $self, $condition ) = @_;

    return $self->_search(1,$condition);
}

sub map {
    my( $self, $code ) = @_;

    $_ = "$self";
    my @values = $code->();
    $self &= $values[0];
    
}

1;
