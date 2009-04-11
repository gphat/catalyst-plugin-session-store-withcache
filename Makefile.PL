use inc::Module::Install;

name     'Catalyst-Plugin-Session-Store-Cache';
all_from 'lib/Catalyst/Plugin/Session/Store/Cache.pm';
author   'Cory G Watson <gphat@cpan.org>';

build_requires 'Test::More';

requires 'CHI' => '0.102';
requires 'Catalyst::Plugin::Session';
requires 'MRO::Compat';

WriteAll;

