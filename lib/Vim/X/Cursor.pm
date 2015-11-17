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

has line => ( is => 'rw', required => 1 );
has col  => ( is => 'rw', required => 1 );

before line => sub {
    return unless @_ == 2;
    my( $cursor, $line ) = @_;
    $cursor->window->_window->Cursor( $line, $cursor->col );
};

before col => sub {
    return unless @_ == 2;
    my( $cursor, $col ) = @_;
    $cursor->window->_window->Cursor( $cursor->line, $col );
};

sub append {
    my( $self, $stuff ) = @_;

    my $line = $self->line;
    my $content = $line->content;
    substr( $content, $self->col + 1, 0 ) = $stuff;
    $line->content($content);
}

1;




