# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

package Test::API;
use strict;
use warnings;
use Devel::Symdump ();
use Symbol ();

our $VERSION = '0.002';
$VERSION = eval $VERSION; ## no critic

use base 'Test::Builder::Module';
our @EXPORT = qw/public_ok import_ok/;

#--------------------------------------------------------------------------#

sub import_ok ($;@) {
  my $package = shift;
  my %spec = @_;
  for my $key ( qw/export export_ok/ ) {
    $spec{$key} ||= [];
    $spec{$key} = [ $spec{$key} ] unless ref $spec{$key} eq 'ARRAY';
  }
  my $tb = _builder();
  my @errors;
  my %flagged;

  my $label = "importing from $package";

  return 0 unless _check_loaded($package, $label);

  # test export
  {
    my $test_pkg = *{Symbol::gensym()}{NAME};
    eval "package $test_pkg; use $package;"; ## no critic
    my ($ok, $missing, $extra ) = _public_ok( $test_pkg, @{$spec{export}} );
    if ( !$ok ) {
      push @errors, "not exported: @$missing" if @$missing;
      @flagged{ @$missing } = (1) x @$missing if @$missing;
      push @errors, "unexpectedly exported: @$extra" if @$extra;
      @flagged{ @$extra } = (1) x @$extra if @$extra;
    }
  }

  # test export_ok
  my @exportable;
  for my $fcn ( _public_fcns( $package ) ) {
    next if $flagged{$fcn}; # already complaining about this so skip
    next if grep { $fcn eq $_ } @{$spec{export}}; # exported by default
    my $pkg_name = *{Symbol::gensym()}{NAME};
    eval "package $pkg_name; use $package '$fcn';"; ## no critic
    my ($ok, $missing, $extra ) = _public_ok( $pkg_name, $fcn );
    if ( $ok ) {
      push @exportable, $fcn;
    }
  }
  my ($missing, $extra) = _difference( 
    $spec{export_ok}, \@exportable,
  );
  push @errors, "not optionally exportable: @$missing" if @$missing;
  push @errors, "extra optionally exportable: @$extra" if @$extra;

  # notify of results
  $tb->ok(! @errors, "importing from $package");
  $tb->diag( $_ ) for @errors;
  return ! @errors;
}

#--------------------------------------------------------------------------# 

sub public_ok ($;@) { ## no critic
  my ($package, @expected) = @_;
  my $tb = _builder();
  my $label = "public API for $package";

  return 0 unless _check_loaded($package, $label);

  my ($ok, $missing, $extra) = _public_ok( $package, @expected );
  $tb->ok($ok, $label );
  if ( !$ok ) {
    $tb->diag( "missing: @$missing" ) if @$missing;
    $tb->diag( "extra: @$extra" ) if @$extra;
  }
  return $ok;
}

#--------------------------------------------------------------------------#

sub _builder {
  return __PACKAGE__->builder;
}

#--------------------------------------------------------------------------#

sub _check_loaded {
  my ($package, $label) = @_;
  (my $path = $package) =~ s{::}{/}g;
  $path .= ".pm";
  if ( $INC{$path} ) {
    return 1
  }
  else {
    my $tb = _builder();
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $tb->ok( 0, $label );
    $tb->diag( "Module '$package' not loaded" );
    return;
  }
}

#--------------------------------------------------------------------------#

sub _difference {
  my ($array1, $array2) = @_;
  my (%only1, %only2);
  @only1{ @$array1 } = (1) x @$array1;
  delete @only1{ @$array2 };
  @only2{ @$array2 } = (1) x @$array2;
  delete @only2{ @$array1 };
  return ([sort keys %only1], [sort keys %only2]);
}


#--------------------------------------------------------------------------#

sub _public_fcns {
  my ($package) = @_;
  my $symbols = Devel::Symdump->new( $package );
  return  grep  { substr($_,0,1) ne '_' } 
          map   { (my $f = $_) =~ s/^$package\:://; $f } 
          $symbols->functions;
}

#--------------------------------------------------------------------------#

sub _public_ok ($;@) { ## no critic
  my ($package, @expected) = @_;
  my @fcns = _public_fcns($package);
  my ($missing, $extra) = _difference( \@expected, \@fcns );
  return ( !@$missing && !@$extra, $missing, $extra );
}

1;

__END__

=begin wikidoc

= NAME

Test::API - Test a list of subroutines provided by a module

= VERSION

This documentation describes version %%VERSION%%.

= SYNOPSIS

    use Test::More tests => 2;
    use Test::API;

    require_ok( 'My::Package' );
    
    public_ok ( 'My::Package', @names );
    
    import_ok ( 'My::Package',
        export    => [ 'foo', 'bar' ],
        export_ok => [ 'baz', 'bam' ], 
    );

= DESCRIPTION

This simple test module checks the subroutines provided by a module.  This is
useful for confirming a planned API in testing and ensuring that other
functions aren't unintentionally included via import.

= USAGE

Note: Subroutines in a package starting with an underscore are ignored.
Therefore, do not include them in any list of expected subroutines.

== public_ok

  public_ok( $package, @names );

This function checks that all of the {@names} provided are available within the
{$package} namespace and that *only* these subroutines are available.  This
means that subroutines imported from other modules will cause this test to fail
unless they are explicitly included in {@names}.

== import_ok

  import_ok ( $package, %spec );
  
This function checks that {$package} correctly exports an expected list of
subroutines and *only* these subroutines.  The {%spec} generally follows 
the style used by [Exporter], bun in lower case:  

  %spec = (
    export    => [ 'foo', 'bar' ],  # exported automatically
    export_ok => [ 'baz', 'bam' ],  # optional exports
  );

For {export_ok}, the test will check for public functions not listed in
{export} or {export_ok} that can be imported and will fail if any are found.

= BUGS

Please report any bugs or feature requests using the CPAN Request Tracker  
web interface at [http://rt.cpan.org/Dist/Display.html?Queue=Test-API]

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

= SEE ALSO

* [Test::ClassAPI] -- more geared towards class trees with inheritance

= AUTHOR

David A. Golden (DAGOLDEN)

= COPYRIGHT AND LICENSE

Copyright (c) 2009 by David A. Golden. All rights reserved.

Licensed under Apache License, Version 2.0 (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a 
copy of the License from http://www.apache.org/licenses/LICENSE-2.0

Files produced as output though the use of this software, shall not be
considered Derivative Works, but shall be considered the original work of the
Licensor.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=end wikidoc

=cut

