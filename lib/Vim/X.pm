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
    no warnings 'uninitialized';

    my( $class, $sym_ref, undef, undef, $attr_data ) = @_;

    my $name = *{$sym_ref}{NAME};

    my $args = $attr_data =~ 'args' ? '...' : undef;

    my $range = 'range' x ( $attr_data =~ /range/ );

    no strict 'refs';
    VIM::DoCommand(<<END);
function $name($args) $range
    perl ${class}::$name( split "\\n", scalar VIM::Eval('a:000'))
endfunction
END

    return;
}

sub load_function_dir {
    my $dir = shift;

    my @files = <$dir/*.pl>; 

    for my $f ( @files ) {
        my $name = _func_name($f);
        vim_command( 
            "au FuncUndefined $name perl Vim::X::load_function_file('$f')" 
        );
    }

END

}

sub _func_name {
    my $name = shift;
    $name =~ s#^.*/##;
    $name =~ s#\.pl$##;
    return $name;
}

sub load_function_file {
    my $file = shift;

    my $name = _func_name($file);

    eval <<"END";
    package $name;

    do '$file';
END

}

unless ( $main::curbuf ) {
    package 
        VIM;
    no strict;
    sub AUTOLOAD {
        # warn "calling $AUTOLOAD";
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

    return Vim::X::Buffer->new( index => $buf, _buffer => $::curbuf );
}

=func vim_lines( @indexes )

Returns the L<Vim::X::Line> objects for the lines in I<@indexes> of the
current buffer. If no index is given, returns all the lines of the buffer.

=cut

sub vim_lines {
    vim_buffer->lines(@_);
}

=func vim_line($index) 

Returns the L<Vim::X::Line> object for line I<$index> of the current buffer.
If I<$index> is not given, returns the line at the cursor.

=cut

sub vim_line {
    @_ ? vim_buffer->line(shift) : vim_cursor();
}

=func vim_append(@lines) 

Appends the given lines after the line under the cursor.

If carriage returns are present in the lines, they will be split in
consequence.

=cut

sub vim_append {
    vim_cursor()->append(@_);
}

=func vim_eval(@expressions)

Evals the given C<@expressions> and returns their results.

=cut

sub vim_eval {
    return map { scalar VIM::Eval($_) } @_;
}

=func vim_range()

Returns the range of line (if any) on which the command has been called.

=cut

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

=func vim_command( @commands )

Run the given 'ex' commands and return their results.

    vim_command 'normal 10G', 'normal iHi there!';

=cut

sub vim_command {
    return map { VIM::DoCommand($_) } @_;
}

=func vim_call( $function, @args )

Calls the vim-space function I<$function> with the 
provided arguments.

    vim_call( 'SetVersion', '1.23' )

    # equivalent of doing 
    #    :call SetVersion( '1.23' )
    # in vim

=cut

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
    return Vim::X::Window->new( _window => shift || $::curwin);
}

=func vim_cursor

Returns the L<Vim::X::Line> associated with the position of the cursor
in the current window.

=cut

sub vim_cursor {
    my $w = vim_window();
    return $w->cursor;
}

=func vim_delete( @lines ) 

Deletes the given lines from the current buffer.

=cut

sub vim_delete {
    vim_buffer->delete(@_);
}

1;

=head1 SYNOPSIS

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

=head1 DESCRIPTION

I<Vim::X> provides two tools to make writing Perl functions for Vim a little
easier: it auto-exports functions tagged by the attribute C<:Vim> in
Vim-space, and it defines a slew of helper functions and objects that are a
little more I<Do What I Mean> than the I<VIM> API module that comes with Vim
itself.

Obviously, for this module to work, Vim has to be compiled with Perl interpreter
support.

=head2 Import Perl function in Vim-space

Function labeled with the C<:Vim> attribute are automatically exported to Vim.

The C<:Vim> attribute accepts two optional parameters: C<args> and C<range>. 

=head3 :Vim(args)

If C<args> is present, the function will be exported expecting arguments, that
will be passed to the function via the usual C<@_> way.

    sub Howdie :Vim(args) {
        vim_msg( "Hi there, ", $_[0] );
    }

    # and then in vim:
    call Howdie("buddy")

=head3 :Vim(range)

If C<range> is present, the function will be called only once when invoked
over a range, instead than once per line (which is the default behavior).


    sub ReverseLines :Vim(range) {
        my @lines = reverse map { "$_" } vim_range();
        for my $line ( vim_range ) {
            $line <<= pop @lines;
        }
    }

    # and then in vim:
    :5,15 call ReverseLines()

=head1 SEE ALSO

The original blog entry: L<http://techblog.babyl.ca/entry/vim-x>
