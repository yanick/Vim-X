package MyVim;

use Data::Printer;
use Sub::Attribute;

sub Vim :ATTR_SUB {
    my($class, $sym_ref, $code_ref, $attr_name, $attr_data) = @_;

    p @_;
    print *{$sym_ref}{NAME};

    return;
}

sub all_caps :Vim {
    VIM::Msg( "coucou" );
    for ( 1..$::curbuf->Count ) {
        $::curbuf->Set( $_, uc $::curbuf->Get($_) );
    }
}

0 and VIM::DoCommand(<<'END');
function MyVim_all_caps()
    perl MyVim::all_caps()
endfunction
END


1;
