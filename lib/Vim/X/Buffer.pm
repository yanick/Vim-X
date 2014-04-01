package Vim::X::Buffer;

sub new {
    my( $class, $buf ) = @_;
    my $self = ref $buf ? [ -1, $buf ] : [ $buf, (undef,VIM::Buffers())[$buf] ];
    return bless $self, $class;
}

sub append {
    my( $self, $index, @lines ) = @_;
    $self->[1]->Append( $index, map { split "\n" } @lines );
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

    return map { Vim::X::Line->new( buffer => $self, index => $_ ) } @lines;
}

sub size {
    my $self = shift;
    $self->[1]->Count;
}

1;


