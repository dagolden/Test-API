package t::lib::ExportComplex;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw/foo bar/;

sub foo { 1 }

sub bar { 2 }

1;

