package ResolveConflictTest;

use Vim::X;

use Test::Class::Moose;

sub test_vim_append :Tests {
    vim_append( 'a'..'c' );

    is join( '!', vim_lines() ) => '!a!b!c', "append";

    vim_command( 'normal 3G' );
    vim_append( 'z' );
    is join( '!', vim_lines() ) => '!a!b!z!c', "append after line 2";

    vim_append( "foo\nbar" );
    is join( '!', vim_lines() ) => '!a!b!foo!bar!z!c', "split on CRs";

};

__PACKAGE__->new->runtests;

1;
