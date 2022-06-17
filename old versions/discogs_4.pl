
#!/perl
# use Discogs API to get additional data for sales list
# m.bole 11/2009
# $Id: discog~1.pl%v 1.1 2010/03/17 01:57:57 mark Exp mark $

use warnings;
use strict;

my (@releases, $rel_id, $line, $country, $released, @styles, @tracklist,
       @primary_images, @secondary_images, $image_uri, $href, $tracknum,
       $imagenum, $track_title);


if (! open(KOTB, $ARGV[0]) ) {
    die "Can't open $ARGV[0], $!\n";
}


use WWW::Discogs;
my $client = WWW::Discogs->new(apikey => '2f350a82a5');

#debug print join(",",ref $client, $client), "\n";


# read in the existing CSV list
my ($i) = 0;
while (<KOTB>) {
    next unless /^(\d+),/;
    next unless (++$i > 0);
    last if ($i > 5000);
    $rel_id = $1;
    chomp($line = $_);

    my $release = $client->release($rel_id);
    if (defined($release)) {
            $country = $release->country || "(no country)";
            $released = $release->released || "(no year)";
            @styles = $release->styles;
            @tracklist = $release->tracklist;
            @primary_images = $release->primary_images;
            @secondary_images = $release->secondary_images;
            print join(",", $line, $country, $released, '"'.$styles[0].'"',
                             defined($styles[1]) ? '"'.$styles[1].'"' : "" );

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
                next if ref($href->{'position'});    # an index track?
                ($track_title =  $href->{'title'}) =~ s/"/""/g;
                # separate tracks with <br> instead
                print $trackflag++ ? "<br>" : "", $track_title;
            }
            print  "\"\n";
    } else {
        print STDERR "$rel_id: NOT FOUND\n";
    }
}