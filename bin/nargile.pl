#!/usr/bin/perl

use strict;
use warnings;
use Fcntl;
use AnyDBM_File;
use WWW::Mechanize;
use CPAN::DistnameInfo;
use Getopt::Long qw(GetOptions);
use File::Spec;
use Pod::Usage qw(pod2usage);
use File::Basename qw(dirname);

use CPAN::Nargile;


my %opt;
GetOptions(\%opt, "cpan=s", "perl=s", "help", "version", "count=i", "ask") or pod2usage(2);
#$opt{cpan}   ||= "http://www.cpan.org";
$opt{perl}   ||= $^X;

if ($opt{version}) {
	print "Nargile v$CPAN::Nargile::VERSION\n";
	exit;
}
pod2usage(2) if $opt{help} or not $opt{cpan};

my $bin = dirname($opt{perl});
my $cpansmoke = File::Spec->catfile($bin, "cpansmoke");


my $mech = WWW::Mechanize->new();
$mech->get("$opt{cpan}/modules/01modules.mtime.html");
die "Could not fetch list of latest modules" if not $mech->success();

foreach my $link ($mech->links) {
	last if defined $opt{count} and $opt{count} <=0;
	next if $link->url =~ /html$/;
	next if $link->url !~ /tar.gz$/;
	my $pathname = $link->url;
	my $d = CPAN::DistnameInfo->new($pathname);

	if (not_yet_smoked($d->distvname)) {
		$opt{count}-- if defined $opt{count};
		print "Next distribution: ", $d->distvname, "\n";
		if ($opt{ask}) {
			my $resp = "";
			do {
				print "Test/Skip/Quit: [T] ";
				chomp($resp = <STDIN>);
			} while ($resp !~ /^[TSQ]?$/i);
			exit if $resp =~ /[qQ]/;
			next if $resp =~ /[sS]/;
		}
		system "$opt{perl} $cpansmoke -aipsu " . $d->distvname;
		#print "$opt{perl} $cpansmoke -aipsu " . $d->distvname;
	}
}


## Add to DBM database $dist if not exist and return 1, else return 0;
sub not_yet_smoked {
    my ($dist) = @_;

    my $sdbm = "$ENV{HOME}/.nargile.dbm";

    my $rv = 0;
    my %myreports;

    # Initialize DBM hash with report send by user
    tie (%myreports, 'AnyDBM_File', $sdbm, O_RDWR|O_CREAT, 0640)
        or die "Can't open %1: %2", $sdbm, $!;

    unless ($myreports{$dist}) {
        $myreports{$dist} = localtime;
        $rv = 1;
    }
    untie %myreports;

    return $rv;
}


=head1 NAME

nargile - CPAN smoking that makes you dizzy


=head1 SYNOPSIS

 nargile [options]

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

=head1 DESCRIPTION

 Enable the user on any platform (will someone test this on other platforms as well, please)
 to run smoke tests of CPAN modules.

 The original recommended CPAN smoking is done based on e-mails sent to the 
 CPAN Testsers mailing list. This has the drawback that it requres some way to 
 parse the incoming mails on the same box where I want to run the smoker.
 
 Nargile downloads the list of the latest modules from CPAN and works on that list so
 you don't need to read mail any more.

 It also ensures that only modules that already reached CPAN will be tested.

=head1 FILES

 The scipt maintains a file called $ENV{HOME}/.nargile.dbm where it lists the
 distributes which were already tried.

=head1 BUGS

 Sometimes I get the following error message:
 
 Can't call method "module" on an undefined value at /home/gabor/perl/585/lib/site_perl/5.8.5/CPANPLUS/Internals/Install.pm line 220.

 When user selects Skiping a module or Quiting (in case of --ask) the name of the module is already
 addedd to the "smoked" list and it won't be smoked again in the next run.



=head1 TODO

 Fix the bugs.

 Enable the user to give a list of modules (using regexes) to be smoked or a list of 
 modules (using regexes) to exclude from smoking.

 Enable the user to decide per module if s/he wants to smoke it or not.

 Interactive mode asking the user for every module what to do before and maybe even after running it.
 Test/Skip/Quit/Exclude ?

 Reduce prerequisites of this module ?

 Enable user initiate smoking a specific distribution by giving its name.
 

=head1 SEE ALSO

 L<CPANPLUS::TesterGuide>
 L<cpansmoke>
 L<http://search.cpan.org/dist/CPANPLUS>

 L<CPAN::Mini>

=head1 AUTHOR

 Gabor Szabo <gabor@pti.co.il>
 Copyright 2004, Gabor Szabo
 The code is released under the same terms as Perl itself.

 L<http://www.szabgab.com/>


=cut

