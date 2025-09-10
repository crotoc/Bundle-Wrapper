use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Bundle::Wrapper',
    license             => 'artistic_2',
    dist_author         => q{Rui Chen <crotoc@gmail.com>},
    dist_version_from   => 'lib/Bundle/Wrapper.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
	'Data::Dumper' => '0',
            'File::Path' => '0',
            'IPC::Cmd' => '0',
            'IPC::Run' => '0',
	    'MCE::Map' => '0',
	    'String::Random' => '0'
	    
    },
    add_to_cleanup     => [ 'Bundle-Wrapper-*' ],
);

$builder->create_build_script();
