package Vim::X;
BEGIN {
  $Vim::X::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Candy for Perl programming in Vim
$Vim::X::VERSION = '1.0.0';
use strict;
use warnings;

use Sub::Attribute;
use Path::Tiny;

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
}


sub source_function_dir {
    my $dir = shift;

    my @files = ( <$dir/*.pl>, <$dir/*.pvim> );

    for my $f ( @files ) {
        my $name = _func_name($f);
        vim_command( "source $f" ) if $f =~ /\.pvim$/;
        vim_command( 
            "au FuncUndefined $name perl Vim::X::load_function_file('$f')" 
        );
    }
}

sub _func_name {
    my $name = shift;
    $name =~ s#^.*/##;
    $name =~ s#\.p(?:l|vim)$##;
    return $name;
}


sub load_function_file {
    my $file = shift;

    my $name = _func_name($file);

    eval "{ package Vim::X::Function::$name;\n" 
       . "no warnings;\n"
       . Path::Tiny::path($file)->slurp
       . "\n}"
       ;

    vim_msg( "ERROR: $@" ) if $@;

    return '';

}

unless ( $main::curbuf ) {
    package 
        VIM;
    no strict;
    sub AUTOLOAD {
        # warn "calling $AUTOLOAD";
    }
}


sub vim_msg {
    VIM::Msg( join " ", @_ );
}

sub vim_prefix {
    my( $prefix ) = @_;

    $Vim::X::PREFIX = $prefix; 
}


sub vim_buffer {
    my $buf = shift // $::curbuf->Number;

    return Vim::X::Buffer->new( index => $buf, _buffer => $::curbuf );
}


sub vim_lines {
    vim_buffer->lines(@_);
}


sub vim_line {
    @_ ? vim_buffer->line(shift) : vim_cursor();
}


sub vim_append {
    vim_cursor()->append(@_);
}


sub vim_eval {
    return map { scalar VIM::Eval($_) } @_;
}


sub vim_range {
    my @range = map { 0 + $_ } @_ == 2 ? @_
                             : @_ == 1 ? ( @_ ) x 2
                             : map { vim_eval($_) } qw/ a:firstline a:lastline /;

    return vim_buffer->range( @range );
}


sub vim_command {
    return map { VIM::DoCommand($_) } @_;
}


sub vim_call {
    my( $func, @args ) = @_;
    my $cmd = join ' ', 'call', $func . '(', map( { "'$_'" } @args ), ')';
    vim_command( $cmd );
}


sub vim_window {
    return Vim::X::Window->new( _window => shift || $::curwin);
}


sub vim_cursor {
    my $w = vim_window();
    return $w->cursor;
}


sub vim_delete {
    vim_buffer->delete(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Vim::X - Candy for Perl programming in Vim

=head1 VERSION

version 1.0.0

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

=head3 Loading libraries

If your collection of functions is growing, 
C<load_function_dir()> can help with their management. See that function below
for more details.

=head1 FUNCTIONS

=head2 load_function_dir( $library_dir)

Looks into the given I<$library_dir> and imports the functions in all
files with the extension C<.pl> (non-recursively).
Each file must have the name of its main
function to be imported to Vim-space.

To have good start-up time and to avoid loading all dependencies for
all functions, the different files aren't sourced at start-up, but are
rather using the C<autocmd> function of Vim to trigger the loading
of those files only if used.

E.g.,

    # in ~/.vim/vimx/perlweekly/PWGetInfo.pl
    use Vim::X;

    use LWP::UserAgent;
    use Web::Query;
    use Escape::Houdini;

    sub PWGetInfo :Vim() {
        ...;
    }

    # in .vimrc
    perl use Vim::X;

    autocmd BufNewFile,BufRead **/perlweekly/src/*.mkd 
                \ perl Vim::X::load_function_dir('~/.vim/vimx/perlweekly')
    autocmd BufNewFile,BufRead **/perlweekly/src/*.mkd 
                \ map <leader>pw :call PWGetInfo()<CR>

=head2 source_function_dir( $library_dir )

Like C<load_function_dir>, but if it finds files with the exension C<.pvim>, 
it'll also source them as C<vimL> files at
load-time, allowing to define both the Perl bindings and the vim macros in the
same file. Note that, magically, the Perl code will still only be compiled if the function
is invoked.

For that special type of magic to happen, the C<.pvim> files must follow a certain pattern to
be able to live their double-life as Perl scripts and vim file:

    ""; <<'finish';

    " your vim code goes here

    finish

    # the Perl code goes here

When sourced as a vim script, the first line is considered a comment and
ignored, and the rest is read until it hits C<finish>, which cause Vim to 
stop reading the file. When read as a Perl file, the first line contains a
heredoc that makes all the Vim code into an unused string, so basically ignore
it in a fancy way.

For example, the snippet for C<load_function_dir> could be rewritten as such:

    # in ~/.vim/vimx/perlweekly/PWGetInfo.pvim
    ""; <<'finish';

        map <leader>pw :call PWGetInfo()<CR>

    finish

    use Vim::X;

    use LWP::UserAgent;
    use Web::Query;
    use Escape::Houdini;

    sub PWGetInfo :Vim() {
        ...;
    }

    # in .vimrc
    perl use Vim::X;

    autocmd BufNewFile,BufRead **/perlweekly/src/*.mkd 
                \ perl Vim::X::source_function_dir('~/.vim/vimx/perlweekly')

=head2 load_function_file( $file_path )

Loads the code within I<$file_path> under the namespace
I<Vim::X::Function::$name>, where name is the basename of the I<$file_path>,
minus the C<.pl>/C<.pvim> extension. Not that useful by itself, but used by 
C<load_function_dir>.

=head2 vim_msg( @text )

Display the strings of I<@text> concatenated as a vim message.

    vim_msg "Hello from Perl";

=head2 vim_buffer( $i )

Returns the L<Vim::X::Buffer> object associated with the I<$i>th buffer. If
I<$i> is not given or set to '0', it returns the current buffer.

=head2 vim_lines( @indexes )

Returns the L<Vim::X::Line> objects for the lines in I<@indexes> of the
current buffer. If no index is given, returns all the lines of the buffer.

=head2 vim_line($index) 

Returns the L<Vim::X::Line> object for line I<$index> of the current buffer.
If I<$index> is not given, returns the line at the cursor.

=head2 vim_append(@lines) 

Appends the given lines after the line under the cursor.

If carriage returns are present in the lines, they will be split in
consequence.

=head2 vim_eval(@expressions)

Evals the given C<@expressions> and returns their results.

=head2 vim_range($from, $to)

=head2 vim_range($line)

=head2 vim_range()

Returns a L<Vim::X::Range> object for the given lines, or single line,
in the current buffer. The lines can be passed as indexes, or L<Vim::X::Line>
objects.

If no line whatsoever is passed, the range will be the one on 
which the command has been called (i.e.: C<:afirstline> and C<a:lastline>).

=head2 vim_command( @commands )

Run the given 'ex' commands and return their results.

    vim_command 'normal 10G', 'normal iHi there!';

=head2 vim_call( $function, @args )

Calls the vim-space function I<$function> with the 
provided arguments.

    vim_call( 'SetVersion', '1.23' )

    # equivalent of doing 
    #    :call SetVersion( '1.23' )
    # in vim

=head2 vim_window( $i )

Returns the L<Vim::X::Window> associated with the I<$i>th window. If I<$i>
is not provided or is zero, returns the object for the current window.

=head2 vim_cursor

Returns the L<Vim::X::Line> associated with the position of the cursor
in the current window.

=head2 vim_delete( @lines ) 

Deletes the given lines from the current buffer.

=head1 SEE ALSO

The original blog entry: L<http://techblog.babyl.ca/entry/vim-x>

=head3 CONTRIBUTORS

Hernan Lopes

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
