package ResolveConflictTest;

use Vim::X;
use Vim::X::Plugin::ResolveConflict;

use Test::Class::Moose;

sub test_setup {
    vim_command( 'new', 'read conflict.txt' );
}

sub test_teardown {
    vim_command( 'close!' );
}

sub here_mine :Tests {
    vim_command( 'normal 3G' );
    vim_call( 'ResolveConflict', 'here' );

    is join( '', vim_lines(1..3) ) => 'abc', "here, mine";
    is vim_buffer->size => 3, "only 3 lines left";
};

sub here_theirs :Tests { 
    vim_command( 'normal 6G' );
    vim_call( 'ResolveConflict', 'here' );

    is join( '', vim_lines(1..3) ) => 'def';
    is vim_buffer->size => 3, "only 3 lines left";
};

sub mine :Tests {
    vim_call( 'ResolveConflict', 'mine' );

    is join( '', vim_lines(1..3) ) => 'abc';
    is vim_buffer->size => 3, "only 3 lines left";
};

sub theirs :Tests {
    vim_call( 'ResolveConflict', 'theirs' );

    is join( '', vim_lines(1..3) ) => 'def';
    is vim_buffer->size => 3, "only 3 lines left";
};

sub both :Tests {
    vim_call( 'ResolveConflict', 'both' );

    is join( '', vim_lines(1..6) ) => 'abcdef';
    is vim_buffer->size => 6, "only 6 lines left";
};

__PACKAGE__->new->runtests;


# $ vim -u NONE -i NONE -N -e -s -S vim.test < /dev/null

__END__
describe 'basic'

    perl push @INC, './lib'
    perl use Vim::YANICK

    before
        new
        read conflict.txt
    end

    after
        close!
    end


    it 'here mine'
        normal 3G
        call ResolveConflict('here')

        Expect getline(1) == "a"
        Expect getline(2) == "b"
        Expect getline(3) == "c"
    end

    it 'here theirs'
        normal 6G
        call ResolveConflict('here')

        Expect getline(1) == "d"
        Expect getline(2) == "e"
        Expect getline(3) == "f"
    end

    it 'mine'
        normal 6G
        call ResolveConflict('mine')

        Expect getline(1) == "a"
        Expect getline(2) == "b"
        Expect getline(3) == "c"
    end

    it 'theirs'
        normal 6G
        call ResolveConflict('theirs')

        Expect getline(1) == "d"
        Expect getline(2) == "e"
        Expect getline(3) == "f"
    end

    it 'both'
        normal 6G
        call ResolveConflict('both')

        Expect getline(1) == "a"
        Expect getline(2) == "b"
        Expect getline(3) == "c"
        Expect getline(4) == "d"
        Expect getline(5) == "e"
        Expect getline(6) == "f"
    end

end
