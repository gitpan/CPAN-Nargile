use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'CPAN::Nargile',
	license             => 'perl',
	dist_author         => 'Gabor Szabo <gabor@pti.co.il>',
	dist_abstract       => 'Script for smoking CPAN',
	create_makefile_pl  => 'traditional',
	create_readme       => 1,
	script_files        => ['bin/nargile.pl'],
	requires            => {
		'Test::More'                => '0.47',
		'WWW::Mechanize'            => '0',
		'CPAN::DistnameInfo'        => '0',
		'CPANPLUS'                  => '0.049',   
		# actually we require CPANPLUS in the target perl installation and not the one we are
		# installing this module to, but there is no way to express this and besides in most of
		# the cases there will be only one perl installation
	},
);

$builder->create_build_script();
