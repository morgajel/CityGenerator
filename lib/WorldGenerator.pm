#!/usr/bin/perl -wT
###############################################################################

package WorldGenerator;

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK $VERSION $XS_VERSION $TESTING_PERL_ONLY);
use base qw(Exporter);
@EXPORT_OK = qw( create_world generate_name);
#FIXME TODO I don't need to reassign back to world when passing in a reference
# i.e. I can simplify $world=generate_foo($world); as generate_foo($world);
###############################################################################

=head1 NAME

    WorldGenerator - used to generate Worlds

=head1 SYNOPSIS

    use WorldGenerator;
    my $world=WorldGenerator::create_world();

=cut

###############################################################################

use Carp;
use CGI;
use ContinentGenerator;
use Data::Dumper;
use Exporter;
use GenericGenerator qw(set_seed rand_from_array roll_from_array d parse_object seed);
use List::Util 'shuffle', 'min', 'max';
use POSIX;
use version;
use XML::Simple;

my $xml = XML::Simple->new();

###############################################################################

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Data files

The following datafiles are used by WorldGenerator.pm:

=over

=item F<xml/data.xml>

=item F<xml/worldnames.xml>

=back

=head1 INTERFACE


=cut

###############################################################################
my $world_data          = $xml->XMLin( "xml/worlddata.xml",      ForceContent => 1, ForceArray => ['option','reason'] );
my $worldnames_data     = $xml->XMLin( "xml/worldnames.xml",     ForceContent => 1, ForceArray => [] );
my $starnames_data      = $xml->XMLin( "xml/starnames.xml",      ForceContent => 1, ForceArray => [] );
my $moonnames_data      = $xml->XMLin( "xml/moonnames.xml",      ForceContent => 1, ForceArray => [] );

###############################################################################

=head2 Core Methods

The following methods are used to create the core of the world structure.


=head3 create_world()

This method is used to create a simple world with nothing more than:

=over

=item * a seed

=item * a name

=back

=cut

###############################################################################
sub create_world {
    my ($params) = @_;
    my $world = {};

    if ( ref $params eq 'HASH' ) {
        foreach my $key ( sort keys %$params ) {
            $world->{$key} = $params->{$key};
        }
    }

    if ( !defined $world->{'seed'} ) {
        $world->{'seed'} = set_seed();
    }

    $world=generate_world_name($world);
    $world=generate_starsystem($world);
    $world=generate_moons($world);
    $world=generate_atmosphere($world);
    return $world;
} ## end sub create_world


###############################################################################

=head3 generate_world_name()

    generate a name for the world.

=cut

###############################################################################
sub generate_world_name {
    my ($world) = @_;
    set_seed($world->{'seed'});
    my $nameobj= parse_object( $worldnames_data );
    $world->{'name'}=$nameobj->{'content'}   if (!defined $world->{'name'} );
   return $world; 
}


###############################################################################

=head3 generate_starsystem()

    generate a starsystem for the world.

=cut

###############################################################################
sub generate_starsystem {
    my ($world) = @_;
    set_seed($world->{'seed'});

    $world->{'starsystem_roll'}= d(100) if (!defined $world->{'starsystem_roll'});
    
    my $starsystem=roll_from_array($world->{'starsystem_roll'},  $world_data->{'stars'}->{'option'});
    $world->{'starsystem_count'}=$starsystem->{'count'};
    $world->{'starsystem_name'}=$starsystem->{'content'};
    $world->{'star'}= [] if (!defined $world->{'star'});
    for (my $starid=0 ; $starid < $world->{'starsystem_count'} ; $starid++ ){
        generate_star($world,$starid);
    }

    return $world; 
}
###############################################################################

=head3 generate_moons()

    generate a moons for the world.

=cut

###############################################################################
sub generate_moons {
    my ($world) = @_;
    set_seed($world->{'seed'});

    $world->{'moons_roll'}= d(100) if (!defined $world->{'moons_roll'});
    
    my $moons=roll_from_array($world->{'moons_roll'},  $world_data->{'moons'}->{'option'});
    $world->{'moons_count'}=$moons->{'count'};
    $world->{'moons_name'}=$moons->{'content'};

    $world->{'moon'}= [] if (!defined $world->{'moon'});
    for (my $moonid=0 ; $moonid < $world->{'moons_count'} ; $moonid++ ){
        generate_moon($world,$moonid);
    }

    return $world; 
}




###############################################################################

=head3 generate_star()

    generate a name for a star.

=cut

###############################################################################
sub generate_star {
    my ($world,$id) = @_;

    $id=0 if (!defined $id);
    set_seed($world->{'seed'}+$id);
    my $nameobj= parse_object( $starnames_data );
    $world->{'star'}[$id]->{'name'} = $nameobj->{'content'}   if (!defined $world->{'star'}[$id]->{'name'} );

    $world->{'star'}[$id]->{'color_roll'} = d(100)  if (!defined $world->{'star'}[$id]->{'color_roll'} );
    $world->{'star'}[$id]->{'color'}= roll_from_array( $world->{'star'}[$id]->{'color_roll'}, $world_data->{'starcolor'}->{'option'})->{'content'} if (!defined $world->{'star'}[$id]->{'color'});

    $world->{'star'}[$id]->{'size_roll'} = d(100)  if (!defined $world->{'star'}[$id]->{'size_roll'} );
    $world->{'star'}[$id]->{'size'}= roll_from_array( $world->{'star'}[$id]->{'size_roll'}, $world_data->{'size'}->{'option'})->{'content'} if (!defined $world->{'star'}[$id]->{'size'});

   return $world; 
}


###############################################################################

=head3 generate_moon()

    generate a name for a moon.

=cut

###############################################################################
sub generate_moon {
    my ($world,$id) = @_;

    $id=0 if (!defined $id);
    set_seed($world->{'seed'}+$id);
    my $nameobj= parse_object( $moonnames_data );
    $world->{'moon'}[$id]->{'name'} = $nameobj->{'content'}   if (!defined $world->{'moon'}[$id]->{'name'} );

    $world->{'moon'}[$id]->{'color_roll'} = d(100)  if (!defined $world->{'moon'}[$id]->{'color_roll'} );
    $world->{'moon'}[$id]->{'color'}= roll_from_array( $world->{'moon'}[$id]->{'color_roll'}, $world_data->{'mooncolor'}->{'option'})->{'content'} if (!defined $world->{'moon'}[$id]->{'color'});

    $world->{'moon'}[$id]->{'size_roll'} = d(100)  if (!defined $world->{'moon'}[$id]->{'size_roll'} );
    $world->{'moon'}[$id]->{'size'}= roll_from_array( $world->{'moon'}[$id]->{'size_roll'}, $world_data->{'size'}->{'option'})->{'content'} if (!defined $world->{'moon'}[$id]->{'size'});

   return $world; 
}


###############################################################################

=head3 generate_atmosphere()

    generate anatmosphere.

=cut

###############################################################################
sub generate_atmosphere {
    my ($world) = @_;

    set_seed($world->{'seed'});

    $world->{'atmosphere'}->{'color_roll'} = d(100)  if (!defined $world->{'atmosphere'}->{'color_roll'} );
    my $atmosphere=roll_from_array( $world->{'atmosphere'}->{'color_roll'}, $world_data->{'atmosphere'}->{'option'});

    $world->{'atmosphere'}->{'color'}= $atmosphere->{'color'}         if (!defined $world->{'atmosphere'}->{'color'});

    $world->{'atmosphere'}->{'reason_roll'} = d(100)  if (!defined $world->{'atmosphere'}->{'reason_roll'} );

    if (  $world->{'atmosphere'}->{'reason_roll'} <  $world_data->{'atmosphere'}->{'reason_chance'} ){
        $world->{'atmosphere'}->{'reason'}= roll_from_array( $world->{'atmosphere'}->{'reason_roll'}, $atmosphere->{'reason'})->{'content'} if (!defined $world->{'atmosphere'}->{'reason'});
    }

   return $world; 
}

1;

__END__


=head1 AUTHOR

Jesse Morgan (morgajel)  C<< <morgajel@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Jesse Morgan (morgajel) C<< <morgajel@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
