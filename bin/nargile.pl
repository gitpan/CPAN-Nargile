#!/usr/bin/perl -w
use strict;
use Pod::Usage qw(pod2usage);
use Getopt::Long qw(GetOptions);
use CPAN::Nargile;


my %opt;
GetOptions(\%opt, "cpan=s", "perl=s", "help", "version", "count=i", "ask") or pod2usage(2);
$opt{perl}   ||= $^X;

if ($opt{version}) {
	print "Nargile v$CPAN::Nargile::VERSION\n";
	exit;
}
pod2usage(2) if $opt{help} or not $opt{cpan};

CPAN::Nargile->smoke(%opt);

=head1 SYNOPSIS

 nargile.pl [options]

 Options
   --cpan URL       - where is the nearest CPAN mirror or minicpan ?             (required)
   --perl PATH      - what is the path to the perl you are using for testing ?
                      by default we use the same perl that was used to execute
					  this script but you might want to test another one without
					  the installation of Nargile.
   --version
   --help
   --count NUM      - the number of modules to be processed this time 
                      (defaults to all 150 in the recentness list)
   --ask            - turn the script interactive, ask the user for every module to
                      Test/Skip/Don't do/Quit
					  Skip     - will skip the testing for this run but might attempt for the next run if
					             module is still in latests list
					  Don't do - will skip this distribution/version pair for good


  See also perldoc CPAN::Nargile

=cut


