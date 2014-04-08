BEGIN {
    return if $::curbuf;

    eval <<'END' unless `vim --version` =~ /\+perl/;
    use Test::More;
    plan skip_all => "vim not found, or not compiled with perl support";
    exit;
END

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

My::Loader->import( 't/lib' );
