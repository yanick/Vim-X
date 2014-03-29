package Vim::X;

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
vim_delete /;


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

=end

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

=end

sub vim_buffer {
    my $buf = shift // $::curbuf->Number;

    return Vim::X::Buffer->new( $buf );
}

=func vim_lines( @indexes )

Returns the L<Vim::X::Line> objects for the lines in I<@indexes> of the
current buffer.

=end

sub vim_lines {
    vim_buffer->lines(@_);
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

=end

sub vim_command {
    return map { VIM::DoCommand($_) } @_;
}

sub vim_call {
    my( $func, @args ) = @_;
    my $cmd = join ' ', 'call', $func . '(', map( { "'$_'" } @args ), ')';
    vim_command( $cmd );
}

sub vim_window {
    return Vim::X::Window->new($::curwin);
}

sub vim_cursor {
    my $w = vim_window();
    return $w->cursor;
}

sub vim_delete {
    vim_buffer->delete(@_);
}

package Vim::X::Window;

sub new {
    my( $class, $win ) = @_;
    my $self = [ $win ];
    return bless $self, $class;
}

sub buffer {
    my $self = shift;
    return Vim::X::Buffer->new( $self->[0]->Buffer );
}

sub cursor {
    my $win = shift;
    return wantarray ? $win->[0]->Cursor 
        : Vim::X::Line->new( $win->buffer, ($win->[0]->Cursor)[0] );
}

package Vim::X::Buffer;

sub new {
    my( $class, $buf ) = @_;
    my $self = ref $buf ? [ -1, $buf ] : [ $buf, (undef,VIM::Buffers())[$buf] ];
    return bless $self, $class;
}

sub delete {
    my ( $self, @lines ) = @_;
    my %seen;
    @lines = sort { $a <=> $b } grep { !$seen{$_}++ } map { 0+$_ } @lines;

    for my $r ( reverse @lines ) {
        $self->[1]->Delete( $r );
    }
}

sub line {
    my ( $self, $nbr ) = @_;

    return Vim::X::Line->new( $self, $nbr );
}

sub lines {
    my $self = shift;
    my @lines = @_;
    unless(@lines) {
        @lines = 1..$self->size;
    }

    return map { Vim::X::Line->new( $self, $_ ) } @lines;
}

sub size {
    my $self = shift;
    $self->[1]->Count;
}

1;
