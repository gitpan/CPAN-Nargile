package CPAN::Nargile;
use strict;

use Fcntl;
use AnyDBM_File;
use WWW::Mechanize;
use CPAN::DistnameInfo;
use File::Spec;
use File::Basename qw(dirname);

our $VERSION = "0.03";

sub smoke {
	my ($class, %opt) = @_;

	my $cpansmoke = File::Spec->catfile(dirname($opt{perl}), "cpansmoke");

	my $mech = WWW::Mechanize->new();
	my $latest = "$opt{cpan}/modules/01modules.mtime.html";
	$mech->get($latest);
	die "Could not fetch list of latest modules: $latest\n" if not $mech->success();

	foreach my $link ($mech->links) {
		last if defined $opt{count} and $opt{count} <=0;
		next if $link->url =~ /html$/;
		next if $link->url !~ /tar.gz$/;
		my $pathname = $link->url;
		my $d = CPAN::DistnameInfo->new($pathname);

		if (not_yet_smoked($d->distvname)) {
			$opt{count}-- if defined $opt{count};
			print "\n-----------------------------------------\n";
			print "Next distribution: ", $d->distvname, "\n";
			if ($opt{ask}) {
				my $resp = "";
				do {
					print "Test/Skip/Don't do/Quit: [T] ";
					chomp($resp = <STDIN>);
				} while ($resp !~ /^[TSQD]?$/i);
				exit if $resp =~ /[qQ]/;
				next if $resp =~ /[sS]/;
				if ($resp =~ /[dD]/) {
					mark_as_smoked($d->distvname);
					next;
				};
			}
			system "$opt{perl} $cpansmoke -aisu " . $d->distvname;
			mark_as_smoked($d->distvname);
		}
	}
}


## Add to DBM database $dist if not exist and return 1, else return 0;
sub mark_as_smoked {
    my ($dist) = @_;
	return smoke_manager($dist, scalar localtime);
}

sub not_yet_smoked {
    my ($dist) = @_;
	return smoke_manager($dist);
}


sub smoke_manager {
    my ($dist, $value) = @_;
	
    my $sdbm = "$ENV{HOME}/.nargile.dbm";

    my $rv = 0;
    my %myreports;

    # Initialize DBM hash with report send by user
    tie (%myreports, 'AnyDBM_File', $sdbm, O_RDWR|O_CREAT, 0640)
        or die "Can't open %1: %2", $sdbm, $!;

    unless ($myreports{$dist}) {
        $myreports{$dist} = $value if $value;
        $rv = 1;
    }
    untie %myreports;

    return $rv;
}



1;


=head1 NAME

CPAN::Nargile - Front-end for cpansmoke 

=head1 SYNOPSIS

 nargile.pl --cpan http://www.cpan.org --ask

 or if you want to run it on another perl installation:
 
 nargile.pl --cpan http://www.cpan.org --perl /home/gabor/perl/585/bin/perl -ask

 See also nargile.pl --help

=head1 DESCRIPTION

 Enable the user on any platform (will someone test this on other platforms as well, please)
 to run smoke tests of CPAN modules.

 The original recommended CPAN smoking is done based on e-mails sent to the 
 CPAN Testsers mailing list. This has the drawback that it requres some way to 
 parse the incoming mails on the same box where I want to run the smoker.
 
 Nargile downloads the list of the latest modules from CPAN and works on that list so
 you don't need to read mail any more.

 It also ensures that only modules that already reached CPAN will be tested.

=head2 Frequency

 By default CPANPLUS is being configured to reload its index ever 86400 seconds,
 that is 24 hours. If you would like to run nargile more often with fresh data
 from CPAN you'll have to configure the C<update> value of CPANPLUS to a lower number.


=head1 FILES

 The scipt maintains a file called $ENV{HOME}/.nargile.dbm where it lists the
 distributes which were already tried.

=head1 BUGS

 This is an experimental version that works on my computer...


 Sometimes I get the following error message:
 
 Can't call method "module" on an undefined value at /home/gabor/perl/585/lib/site_perl/5.8.5/CPANPLUS/Internals/Install.pm line 220.

 It seems that cpansmoke when it notices that I have already sent a report about a distribution
 (in a previous life) it won't even install it. This might be a problem but it might be that it
 happens only as I have installed some modules in a previous attemt to test the Nargile script.


 This might be a bug in CPANPLUS 0.049 -  should upgrade it before complaining:
 In the recent uploads list there was 
 TMTM      Text-Decorator-1.5.tar.gz 

 but when I ran cpansmok Text-Decorator-1.5
 it tiread to fetch  /S/SI/SIMON/Text-Decorator-1.5.tar.gz
 It seem the module just changed owners as SIMON has the earlier versions of this module.


=head1 TODO

 Fix the bugs.

 Enable the user to give a list of modules (using regexes) to be smoked or a list of 
 modules (using regexes) to exclude from smoking.

 Enable the user to decide per module if s/he wants to smoke it or not.

 Interactive mode asking the user for every module what to do before and maybe even after running it.
 Test/Skip/Quit/Exclude ?

 Reduce prerequisites of this module ?

 Enable user initiate smoking a specific distribution by giving its name.

 Automatically skip Bundles ?
 
 With the current way of testing all the files in the latest 150 it migth happen that
 the user uploaded 2 or more versions in the past few days and we might test an already
 outdated version (in addition to the new one). Worse than that it can easily happen
 especially if using CPAN::Mini that we don't have one of the versions. I should find out
 first what is really the latest version of a dist on the CPAN mirror I am using.

 Somehow catch the output of each cpansmoke run (using script on unix ?) for later reference.


=head1 Changes

=head2 v0.03

 code moved mostly from script to module

 fix bug
   When user selects Skiping a module or Quiting (in case of --ask) the name of the module is already
   addedd to the "smoked" list and it won't be smoked again in the next run.
 split the Don't do and the Skip modes

 cpanplus option -p removed to install prerequisites too


=head1 SEE ALSO

 L<CPANPLUS::TesterGuide>
 L<cpansmoke>
 L<http://search.cpan.org/dist/CPANPLUS>

 L<CPAN::Mini>

=head1 Spelling

 Maybe it was better if I spelled it as Nargila ?

=head1 AUTHOR

 Gabor Szabo <gabor@pti.co.il>
 Copyright 2004, Gabor Szabo
 The code is released under the same terms as Perl itself.

 L<http://www.szabgab.com/>

=cut

