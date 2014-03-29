package ResolveConflictTest;

use Vim::X;

use Test::Class::Moose;

sub ReverseRange :Vim(range) {
    vim_range( reverse map { "$_" } vim_range )
}

sub range_function :Tests {
    vim_append( 'a'..'e' );
    vim_command( '3,5call ReverseRange()' );

    is join( '', vim_lines(1..6) ) => 'abced', "reversed";
};

__PACKAGE__->new->runtests;

1;
