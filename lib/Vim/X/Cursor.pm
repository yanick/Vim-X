package Vim::X::Cursor;
# ABSTRACT: A window cursor in Vim

use strict;
use warnings;

use Vim::X;
use Carp;

use Moo;

=func window()

Returns the  L<Vim::X::Window> of the cursor.

=cut

has window => (
    is => 'ro',
    required => 1,
);

has line => ( is => 'ro', required => 1 );
has col  => ( is => 'ro', required => 1 );

sub append {
    my( $self, $stuff ) = @_;

    my $line = $self->line;
    my $content = $line->content;
    substr( $content, $self->col + 1, 0 ) = $stuff;
    $line->content($content);
}

1;




