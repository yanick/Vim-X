package Vim::X::Line;
# ABSTRACT: A line in a Vim buffer

use Moo;

use overload
    '""' => sub { $_[0]->content },
    '<<=' => sub { $_[0]->[0]->Set( $_[0]->[1], $_[1] ) },
    '0+' => sub { return $_[0]->number },
    '+' => sub { return $_[0]->number + $_[1] },
    '<=>' => sub { 
            return  $_[0]->number <=>  (ref $_[1] ? $_[1]->number : $_[1])
        },
    ;

has buffer => (
    is => 'ro',
    required => 1,
);

has 'index' => (
    is => 'ro',
    required => 1,
);

sub content { 
    my $self = shift; 
    $self->buffer->[1]->Get( $self->index ) 
} 

sub append {
    my( $self, @lines ) = @_;
    $self->buffer->append( $self->index, @lines );
}


sub clone {
    my $self = shift;
    return Vim::X::Line->new( @$self );
}

sub dec {
    my $self = shift;

    return if $self->[1] == 1;

    $self->[1] = $self->[1] -1;
    return $self;
}

sub inc {
    my $self = shift;

    return if $self->[1] == $self->buffer->size;

    ++$self->[1];
    return $self;
}

sub rewind {
    my( $self, $condition ) = @_;

    my $target = Vim::X::Line->new(@$self);
    while ( $target !~ $condition ) {
        $target->dec or return;
    }

    $self->[1] = $target->[1];
    return $self;
}

sub ff {
    my( $self, $condition ) = @_;

    my $target = Vim::X::Line->new(@$self);

    while ( $target !~ $condition ) {
        $target->inc or return;
    }

    $self->[1] = $target->[1];
    return $self;
}

sub map {
    my( $self, $code ) = @_;

    $_ = "$self";
    my @values = $code->();
    $self &= $values[0];
    
}

1;
