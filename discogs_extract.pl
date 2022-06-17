#!/perl
# use Discogs API to get additional data for sales list
# m.bole 11/2009
# $Id: discogs_extract.pl 1.4 2012/03/25 21:58:21 mark Exp mark $

use warnings;
use strict;

# use NDBM_File;
use Getopt::Std;
use WWW::Discogs;


use vars qw($opt_h $opt_m);

my ( @releases, $rel_id, $line, $country, $released, @genres, @styles, %Styles, @tracklist,
       @primary_images, @secondary_images, $image_uri, $href, $tracknum, @identifiers, $barcode,
       $imagenum, $track_title, $s1, $s2);

&Init;

if (! open(INPUT_FILE, $ARGV[0]) ) {
    die "Can't open $ARGV[0], $!\n";
}

if (! open(OUTPUT_FILE, ">discogs_extract.csv") ) {
    die "Can't open discogs_extract.csv, $!\n";
}

select OUTPUT_FILE;

my $client = WWW::Discogs->new;

#debug print join(",",ref $client, $client), "\n";


# read in the existing CSV list
my ($i) = 0;
while (<INPUT_FILE>) { 
    next unless /^(\d+),/;
    next unless (++$i > 0);
    last if ($i > $opt_m);
    $rel_id = $1;
    chomp($line = $_);

    my $release = $client->release(id => $rel_id);
    if (defined($release)) {

            $country = $release->country || "(no country)";
            $released = $release->released || "(no year)";

            @genres = $release->genres;
            @styles = $release->styles;

            # get first two of whatever is available, default to two empty strings
            ($s1, $s2, undef) = (@styles, @genres, '', ''); 

            @tracklist = $release->tracklist;
      #      @identifiers = $release->identifiers;
            @primary_images = $release->images(type => 'primary');
            @secondary_images = $release->images(type => 'secondary'); 

            $barcode = '(no barcode)';
            for $href (@identifiers) {
                if ($href->{'type'} eq 'Barcode') {
                    $barcode = $href->{'value'};
                    last;
                }
            }

            print join(",", 
                $line,
                '"'.$barcode.'_"',
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


sub Init {


    getopts('hm:');

    if (defined($opt_h)) {
        print <<"EndOfSyntax";
discogs_extract.pl - grab data via API, etc

  discogs_extract.pl [-h] [-m] release_list_file

   -h = help

   -m = max number of rows to process from input file (for testing)
        default = 50,000

EndOfSyntax
        exit;
    }

    if (! $opt_m =~ /^\d+$/) {
        $opt_m = 50000;
    }

}
