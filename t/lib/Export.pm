package t::lib::Export;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/foo/;

sub foo { 1 }

1;

