#!/perl
# use Discogs API to get additional data for sales list
# m.bole 11/2009
# $Id: discog~1.pl%v 1.1 2010/03/17 01:57:57 mark Exp mark $

use warnings;
use strict;

# use NDBM_File;
use Getopt::Std;
use WWW::Discogs;


use vars qw($opt_h $opt_k $opt_s $opt_m);

my ( @releases, $rel_id, $line, $country, $released, @genres, @styles, %Styles, @tracklist,
       @primary_images, @secondary_images, $image_uri, $href, $tracknum,
       $imagenum, $track_title, $s1, $s2);

&Init;

&lookup_styles();

if (! open(KOTB, $ARGV[0]) ) {
    die "Can't open $ARGV[0], $!\n";
}

my $client = WWW::Discogs->new(apikey => $opt_k);

#debug print join(",",ref $client, $client), "\n";


# read in the existing CSV list
my ($i) = 0;
while (<KOTB>) { 
    next unless /^(\d+),/;
    next unless (++$i > 0);
    last if ($i > $opt_m);
    $rel_id = $1;
    chomp($line = $_);

    my $release = $client->release($rel_id);
    if (defined($release)) {

            $country = $release->country || "(no country)";
            $released = $release->released || "(no year)";

            # special handling for genre, style - can't get style to work
            # via API as of April 2010 - might be Discogs or WWW::Discogs bug
            @genres = $release->genres;
            if ( defined($Styles{$rel_id}) ) {
                @styles = @{$Styles{$rel_id}}
            } else {
                @styles = ();
            }
            # get first two of whatever is available, default to two empty strings
            ($s1, $s2, undef) = (@styles, @genres, '', ''); 

            @tracklist = $release->tracklist;
            @primary_images = $release->primary_images;
            @secondary_images = $release->secondary_images; 
            print join(",", 
                $line,
                $country,
                $released,
                '"'.$s1.'"',
                '"'.$s2.'"',
              );

            $image_uri = "";
            for $href (@primary_images) {
                $image_uri = ($href->{'uri150'} || $href->{'uri'});
            }
            if (! $image_uri) { # if primary didn't work, try secondary
                for $href (@secondary_images) {
                    $image_uri = ($href->{'uri150'} || $href->{'uri'});
                    last if $image_uri;
                }
            }
            print ",";
            if ($image_uri) {
                print $image_uri;
            } 
            print ',"';
            my ($trackflag) = 0;
            for $href (@tracklist) {
                next if ref($href->{'position'});	# an index track?
                ($track_title =  $href->{'title'}) =~ s/"/""/g;
                # separate tracks with <br> instead
                print $trackflag++ ? "<br>" : "", $track_title;
            }
            print  "\"\n";
    } else {
        print STDERR "$rel_id: NOT FOUND\n";
    }
}

sub lookup_styles {

    my ($rel, @stylist, $n);

    open(STYLES, $opt_s) or die "Can't open $opt_s, $!\n";

    print STDERR "Reading in styles list from flat file for each release...\n";

    while (<STYLES>) {
        
        ($rel, @stylist) = split(/~/);  # tilde is separator char from my Discogs extract
        pop @stylist;   # remove empty last element, including newline
        $Styles{$rel} = [ @stylist ];
        print STDERR "$n...\n" if (++$n % 100000 == 0);

    }
    print STDERR "Done reading in styles.\n\n";

}

sub Init {


    getopts('hk:s:m:');

    if (defined($opt_h)) {
        print <<"EndOfSyntax";
discogs_extract.pl - grab data via API, etc

  discogs_extract.pl [-h] [-k API_key] [-s file] release_list_file

   -h = help
   -k = API key
   -s = styles flat file
   -m = max number of rows to process from input file (for testing)
        default = 5,000

EndOfSyntax
        exit;
    }

    if (! $opt_m =~ /^\d+$/) {
        $opt_m = 5000;
    }
}
