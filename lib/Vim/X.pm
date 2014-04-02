package Vim::X;
# ABSTRACT: Candy for Perl programming in Vim

use strict;
use warnings;

use Sub::Attribute;
use parent 'Exporter';

our @EXPORT = qw/ 
    vim_func vim_prefix vim_msg vim_buffer vim_cursor vim_window
    vim_command
    vim_call
    vim_lines
    vim_append
    vim_range
    vim_line
vim_delete /;

use Vim::X::Window;
use Vim::X::Buffer;
use Vim::X::Line;

sub import {
    __PACKAGE__->export_to_level(1, @_);
    my $target_class = caller;


    eval <<"END";
    package $target_class;
    use Sub::Attribute;
    sub Vim :ATTR_SUB { goto &Vim::X::Vim; }
END

}

sub Vim :ATTR_SUB {
    my( $class, $sym_ref, $code_ref, $attr_name, $attr_data ) = @_;

    my $name = *{$sym_ref}{NAME};

    my $args = $attr_data eq 'args' ? '...' : undef;

    my $range = 'range' x ( $attr_data =~ /range/ );

    no strict 'refs';
    VIM::DoCommand(<<END);
function $name($args) $range
    perl ${class}::$name( split "\\n", scalar VIM::Eval('a:000'))
endfunction
END

    return;
}

unless ( $::curbuf ) {
    package VIM;
    no strict;
    sub AUTOLOAD {
        warn "calling $AUTOLOAD";
    }
}

=func vim_msg( @text )

Display the strings of I<@text> concatenated as a vim message.

    vim_msg "Hello from Perl";

=cut

sub vim_msg {
    VIM::Msg( join " ", @_ );
}

sub vim_prefix {
    my( $prefix ) = @_;

    $Vim::X::PREFIX = $prefix; 
}

=func vim_buffer( $i )

Returns the L<Vim::X::Buffer> object associated with the I<$i>th buffer. If
I<$i> is not given or set to '0', it returns the current buffer.

=cut

sub vim_buffer {
    my $buf = shift // $::curbuf->Number;

    return Vim::X::Buffer->new( $buf );
}

=func vim_lines( @indexes )

Returns the L<Vim::X::Line> objects for the lines in I<@indexes> of the
current buffer.

=cut

sub vim_lines {
    vim_buffer->lines(@_);
}

sub vim_line {
    vim_buffer->line(shift);
}

sub vim_append {
    vim_cursor()->append(@_);
}

sub vim_eval {
    return map { scalar VIM::Eval($_) } @_;
}

sub vim_range {
    my( $min, $max ) = map { vim_eval($_) } qw/ a:firstline a:lastline /;
    warn $min, " ", $max;

    if( @_ ) {
        vim_buffer->[1]->Delete( $min, $max );
        vim_buffer->line($min)->append(@_);
        return;
    }

    return vim_lines( $min..$max );
}

sub vim_func {
    my $name = shift;
    my $sub = pop;
    my %args = @_;

    if ( $Vim::X::PREFIX ) {
        $name = $Vim::X::PREFIX . $name;
    }

    my $args = $args{args} ? '...' : undef;

    my $range = 'range' x $args =~ /range/;

    no strict 'refs';
    *{"::$name"} = $sub;
    VIM::DoCommand(<<END);
function $name($args) $range
    perl ::$name( split "\\n", scalar VIM::Eval('a:000'))
endfunction
END
    

};

=func vim_command( @commands )

Run the given 'ex' commands.

    vim_command 'normal 10G', 'normal iHi there!';

=cut

sub vim_command {
    return map { VIM::DoCommand($_) } @_;
}

sub vim_call {
    my( $func, @args ) = @_;
    my $cmd = join ' ', 'call', $func . '(', map( { "'$_'" } @args ), ')';
    vim_command( $cmd );
}

=func vim_window( $i )

Returns the L<Vim::X::Window> associated with the I<$i>th window. If I<$i>
is not provided or is zero, returns the object for the current window.

=cut

sub vim_window {
    return Vim::X::Window->new(shift || $::curwin);
}

sub vim_cursor {
    my $w = vim_window();
    return $w->cursor;
}

sub vim_delete {
    vim_buffer->delete(@_);
}

1;

=synopsis

    package Vim::X::Plugin::MostUsedVariable;

    use strict;
    use warnings;

    use Vim::X;

    sub MostUsedVariable :Vim {
        my %var;

        for my $line ( vim_lines ) {
            $var{$1}++ while $line =~ /[$@%](\s+)/g;
        }

        my ( $most_used ) = reverse sort { $var{$a} <=> $var{$b} } keys %var;

        vim_msg "variable name $most_used used $var{$most_used} times";
    }

and then in your C<.vimrc>:

    perl push @INC, '/path/to/plugin/lib';
    perl use Vim::X::Plugin::MostUsedVariable;

    map <leader>m :call MostUsedVariable()

=description

I<Vim::X> provides two tools to make writing Perl functions for Vim a little
easier: it auto-exports functions tagged by the attribute C<:Vim> in
Vim-space, and it defines a slew of helper functions and objects that are a
little more I<Do What I Mean> than the I<VIM> API module that comes with Vim
itself.

Obviously, for this module to work, Vim has to be compiled with Perl interpreter
support.

=head1 SEE ALSO

The original blog entry: L<http://techblog.babyl.ca/entry/vim-x>
