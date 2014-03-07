use 5.006;
use strict;
use warnings;

package Test::API;
# ABSTRACT: Test a list of subroutines provided by a module
# VERSION

use Symbol ();

use superclass 'Test::Builder::Module' => 0.86;
our @EXPORT = qw/public_ok import_ok/;

#--------------------------------------------------------------------------#

sub import_ok ($;@) { ## no critic
    my $package = shift;
    my %spec    = @_;
    for my $key (qw/export export_ok/) {
        $spec{$key} ||= [];
        $spec{$key} = [ $spec{$key} ] unless ref $spec{$key} eq 'ARRAY';
    }
    my $tb = _builder();
    my @errors;
    my %flagged;

    my $label = "importing from $package";

    return 0 unless _check_loaded( $package, $label );

    # test export
    {
        my $test_pkg = *{ Symbol::gensym() }{NAME};
        eval "package $test_pkg; use $package;"; ## no critic
        my ( $ok, $missing, $extra ) = _public_ok( $test_pkg, @{ $spec{export} } );
        if ( !$ok ) {
            push @errors, "not exported: @$missing" if @$missing;
            @flagged{@$missing} = (1) x @$missing if @$missing;
            push @errors, "unexpectedly exported: @$extra" if @$extra;
            @flagged{@$extra} = (1) x @$extra if @$extra;
        }
    }

    # test export_ok
    my @exportable;
    for my $fcn ( _public_fcns($package) ) {
        next if $flagged{$fcn}; # already complaining about this so skip
        next if grep { $fcn eq $_ } @{ $spec{export} }; # exported by default
        my $pkg_name = *{ Symbol::gensym() }{NAME};
        eval "package $pkg_name; use $package '$fcn';"; ## no critic
        my ( $ok, $missing, $extra ) = _public_ok( $pkg_name, $fcn );
        if ($ok) {
            push @exportable, $fcn;
        }
    }
    my ( $missing, $extra ) = _difference( $spec{export_ok}, \@exportable, );
    push @errors, "not optionally exportable: @$missing" if @$missing;
    push @errors, "extra optionally exportable: @$extra" if @$extra;

    # notify of results
    $tb->ok( !@errors, "importing from $package" );
    $tb->diag($_) for @errors;
    return !@errors;
}

#--------------------------------------------------------------------------#

sub public_ok ($;@) { ## no critic
    my ( $package, @expected ) = @_;
    my $tb    = _builder();
    my $label = "public API for $package";

    return 0 unless _check_loaded( $package, $label );

    my ( $ok, $missing, $extra ) = _public_ok( $package, @expected );
    $tb->ok( $ok, $label );
    if ( !$ok ) {
        $tb->diag("missing: @$missing") if @$missing;
        $tb->diag("extra: @$extra")     if @$extra;
    }
    return $ok;
}

#--------------------------------------------------------------------------#

sub _builder {
    return __PACKAGE__->builder;
}

#--------------------------------------------------------------------------#

sub _check_loaded {
    my ( $package, $label ) = @_;
    ( my $path = $package ) =~ s{::}{/}g;
    $path .= ".pm";
    if ( $INC{$path} ) {
        return 1;
    }
    else {
        my $tb = _builder();
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $tb->ok( 0, $label );
        $tb->diag("Module '$package' not loaded");
        return;
    }
}

#--------------------------------------------------------------------------#

sub _difference {
    my ( $array1, $array2 ) = @_;
    my ( %only1, %only2 );
    @only1{@$array1} = (1) x @$array1;
    delete @only1{@$array2};
    @only2{@$array2} = (1) x @$array2;
    delete @only2{@$array1};
    return ( [ sort keys %only1 ], [ sort keys %only2 ] );
}

#--------------------------------------------------------------------------#

sub _public_fcns {
    my ($package) = @_;
    no strict qw(refs);
    return grep { substr( $_, 0, 1 ) ne '_' }
      map { ( my $f = $_ ) =~ s/^\*$package\:://; $f }
      grep { defined(*$_{CODE}) }
      values(%{"$package\::"});
}

#--------------------------------------------------------------------------#

sub _public_ok ($;@) { ## no critic
    my ( $package, @expected ) = @_;
    my @fcns = _public_fcns($package);
    my ( $missing, $extra ) = _difference( \@expected, \@fcns );
    return ( !@$missing && !@$extra, $missing, $extra );
}

1;

__END__

=head1 SYNOPSIS

    use Test::More tests => 3;
    use Test::API;

    require_ok( 'My::Package' );
    
    public_ok ( 'My::Package', @names );
    
    import_ok ( 'My::Package',
        export    => [ 'foo', 'bar' ],
        export_ok => [ 'baz', 'bam' ], 
    );

=head1 DESCRIPTION

This simple test module checks the subroutines provided by a module.  This is
useful for confirming a planned API in testing and ensuring that other
functions aren't unintentionally included via import.

=head1 USAGE

Note: Subroutines in a package starting with an underscore are ignored.
Therefore, do not include them in any list of expected subroutines.

=head2 public_ok

  public_ok( $package, @names );

This function checks that all of the C<@names> provided are available within the
C<$package> namespace and that *only* these subroutines are available.  This
means that subroutines imported from other modules will cause this test to fail
unless they are explicitly included in C<@names>.

=head2 import_ok

  import_ok ( $package, %spec );
  
This function checks that C<$package> correctly exports an expected list of
subroutines and *only* these subroutines.  The C<%spec> generally follows 
the style used by [Exporter], but in lower case:  

  %spec = (
    export    => [ 'foo', 'bar' ],  # exported automatically
    export_ok => [ 'baz', 'bam' ],  # optional exports
  );

For C<export_ok>, the test will check for public functions not listed in
C<export> or C<export_ok> that can be imported and will fail if any are found.

=head1 SEE ALSO

=for :list
* L<Test::ClassAPI> -- more geared towards class trees with inheritance

=cut

