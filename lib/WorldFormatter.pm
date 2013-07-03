
#!/usr/bin/perl -wT
###############################################################################

package WorldFormatter;

###############################################################################

=head1 NAME

    WorldFormatter - used to format the summary.

=head1 DESCRIPTION

 This take a world, strips the important info, and generates a Sumamry.

=cut

###############################################################################

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK $VERSION $XS_VERSION $TESTING_PERL_ONLY);
require Exporter;

@ISA       = qw(Exporter);
@EXPORT_OK = qw( printSummary);

use CGI;
use Data::Dumper;
use Lingua::Conjunction;
use Lingua::EN::Inflect qw(A);
use Lingua::EN::Numbers qw(num2en);
use List::Util 'shuffle', 'min', 'max';
use POSIX;

###############################################################################

=head2 printSummary()

printSummary strips out important info from a World object and returns formatted text.

=cut

###############################################################################
sub printSummary {
    my ($world) = @_;
    my $content="";
    $content.="$world->{'name'} is a $world->{'size'}, $world->{'basetemp'} planet orbiting a $world->{'starsystem_name'}. ";
    $content.="$world->{'name'} has a $world->{'moons_name'}, a $world->{'air'} $world->{'atmosphere'}->{'color'} atmosphere and fresh water is $world->{'freshwater_description'}. ";
    $content.="The surface of the planet is $world->{'surfacewater_percent'}% covered by water. ";
    return $content;
}


###############################################################################

=head2 printSkySummary()

printSkySummary strips out important info from a World object and returns formatted text.

=cut

###############################################################################
sub printSkySummary {
    my ($world) = @_;
    my $content="";
    my $stars=conjunction(@{ $world->{'star_description'}} );
    my $moons=printMoonList($world);
    my $celestials=printCelestialList($world);
    my $atmosphere=printAtmosphere($world);
    $content.= "$world->{'name'} orbits ". A($world->{'starsystem_name'}). ": $stars. ";
    $content.= "$world->{'name'} also has $moons. ";
    $content.= "In the night sky, you see $celestials. ";
    $content.= "During the day, the sky is $atmosphere.";


    return $content;
}

sub printAtmosphere {
    my ($world) = @_;
    my $content=$world->{'atmosphere'}->{'color'};
    if (defined $world->{'atmosphere'}->{'reason'}){
        $content.=", which is partially due to ".$world->{'atmosphere'}->{'reason'};
    }

    return $content;
}


sub printMoonList {
    my ($world) = @_;
    my $content="";
    if ($world->{'moons_count'} == 0 ){
        $content.=$world->{'moons_name'};
    }else{
        $content.=A($world->{'moons_name'}).": ".conjunction(@{ $world->{'moon_description'}} );
    }
#print Dumper $world;

    return $content;
}


sub printCelestialList {
    my ($world) = @_;
    my $content="";
    if ($world->{'celestial_count'} == 0 ){
        $content.=$world->{'celestial_name'};
    } else {
        $content.=$world->{'celestial_name'}.": ".conjunction(@{ $world->{'celestial_description'}} );
    }

    return $content;
}




1;