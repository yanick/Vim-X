BEGIN {
    return if $::curbuf;

    exec 'vim', qw/ -V -u NONE -i NONE -N -e -s /,
        '-c' => 'perl unshift @INC, "lib"', 
        '-c' => 'perl unshift @INC, "t/lib"', 
        '-c', "perl do '$0'",
        '-c', "qall!";

    exit;
}

package My::Loader;
use base qw( Test::Class::Moose::Load );

sub is_test_class {
    my ( $class, $file, $dir ) = @_;

      # return unless it's a .pm (the default)
      return unless $class->SUPER::is_test_class( $file, $dir );

      return $file !~ /VimTest/;
}

package Foo;

$DB::single = 1;
My::Loader->import( 't/lib' );
#VimTest->runtests;

__END__

use Test::More;

plan skip_all => 'soon';

use Path::Tiny;

my $iter = path( 't/lib/TestsFor' )->iterator({ recurse => 1 });

while( my $file = $iter->() ) {
    next unless $file =~ /\.pm$/ and 0;

    run_test( $file );
}

sub run_test {
    system 'vim', qw/ -V -u NONE -i NONE -N -e -s /,
        '-c' => 'perl push @INC, "lib"', 
#        '-c' => 'perl push @INC, "t/lib"', 
        '-c', "perl do '$0' or die \$@",
        '-c', "qall!";
}


