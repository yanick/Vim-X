use Path::Tiny;

my $iter = path( 't/vim' )->iterator({ recurse => 1 });

while( my $file = $iter->() ) {
    next unless $file =~ /\.t$/;

    run_test( $file );
}

sub run_test {
    exec 'vim', qw/ -V -u NONE -i NONE -N -e -s /,
        '-c' => 'perl push @INC, "lib"', 
        '-c' => 'perl push @INC, "t/lib"', 
        '-c', "perl do '$_[0]' or die \$@",
        '-c', "qall!";
}


