# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use lib 'inc';
eval "require Pod::WikiDoc";
my $class = $@ ? "Module::Build" : "Module::Build::WikiDoc";
eval "require $class";
my $build = $class->new( 
    module_name => 'Test::API',
    dist_author => 'David Golden <dagolden@cpan.org>',
    license => 'apache',
    create_readme => 1,
    create_makefile_pl  => 'traditional',
    requires => {
        'perl' => '5.006',
        'base' => 0,
        'Devel::Symdump' => 2.08,
        'Test::Builder::Module' => 0.86, 
    },
    build_requires => {
        'Carp' => 0,
        'Test::Builder::Tester' => 1.18, # 1.02 in perl 5.008008; 1.18 is new
    },
    meta_add            => { 
        no_index => { 
            directory => [ qw/ examples inc t xt /],
        },
        resources => {
          repository => "http://github.com/dagolden/Test-API/", 
          bugtracker => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-API",
        },
    },
);
$build->create_build_script;

